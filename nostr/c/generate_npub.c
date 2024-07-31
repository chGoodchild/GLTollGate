#include <stdio.h>   // For FILE, fopen, fprintf, fclose, etc.
#include <stdlib.h>  // For malloc and free
#include <string.h>  // If you need memory functions like memset etc.
#include <stddef.h>  // For NULL

#include <openssl/evp.h>        // For EVP_PKEY, EVP_PKEY_CTX, etc.
#include <openssl/pem.h>        // For PEM_read_PUBKEY, PEM_read_PrivateKey
#include <openssl/rand.h>       // For RAND_bytes
#include <openssl/bn.h>         // For BIGNUM functions
#include <openssl/err.h>        // For error handling
#include <openssl/encoder.h>
#include <openssl/core_names.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>

#include <wally_core.h>         // For libwally functions
#include <wally_bip39.h>        // For mnemonic generation
#include <wally_address.h>      // Additional libwally functionality

// Function Declarations
void handle_errors();
void output_json(const char* npub_hex, const char* nsec_hex, const char* mnemonic);
char* to_hex(const unsigned char *data, int length);
char* convert_key_to_hex(const char* filename, int is_public);  // Function declaration


void handle_errors() {
    ERR_print_errors_fp(stderr);
    abort();
}

void output_json(const char* npub_hex, const char* nsec_hex, const char* mnemonic) {
    printf("{\n");
    printf("  \"npub_hex\": \"%s\",\n", npub_hex);
    printf("  \"nsec_hex\": \"%s\",\n", nsec_hex);
    printf("  \"bip39_nsec\": \"%s\"\n", mnemonic);
    printf("}\n");
}

char* to_hex(const unsigned char *data, int length) {
    char* hex_string = malloc(length * 2 + 1);
    if (!hex_string) return NULL;
    for (int i = 0; i < length; ++i) {
        sprintf(hex_string + (i * 2), "%02x", data[i]);
    }
    hex_string[length * 2] = '\0';
    return hex_string;
}

char* convert_ec_public_key_to_hex(EVP_PKEY *pkey) {
    OSSL_ENCODER_CTX *ctx = NULL; // No need to pre-declare as NULL here when using new_for_pkey directly
    BIO *bio = BIO_new(BIO_s_mem());
    if (!bio) {
        fprintf(stderr, "Failed to create BIO for public key.\n");
        return NULL;
    }

    // Initialize the encoder context correctly
    if (!(ctx = OSSL_ENCODER_CTX_new_for_pkey(pkey, OSSL_KEYMGMT_SELECT_PUBLIC_KEY, "HEX", "SubjectPublicKeyInfo", NULL))) {
        fprintf(stderr, "Failed to create encoder context.\n");
        BIO_free_all(bio);
        return NULL;
    }

    // Encode the public key to the BIO
    if (!OSSL_ENCODER_to_bio(ctx, bio)) {
        fprintf(stderr, "Failed to encode public key.\n");
        OSSL_ENCODER_CTX_free(ctx);
        BIO_free_all(bio);
        return NULL;
    }

    // Extract the data from BIO
    BUF_MEM *bptr = NULL;
    BIO_get_mem_ptr(bio, &bptr);
    char *hex = malloc(bptr->length + 1);
    if (hex) {
        memcpy(hex, bptr->data, bptr->length);
        hex[bptr->length] = '\0'; // Null-terminate the string
    }

    // Clean up
    OSSL_ENCODER_CTX_free(ctx);
    BIO_free_all(bio);
    return hex;
}

char* convert_key_to_hex(const char* filename, int is_public) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        fprintf(stderr, "Unable to open file %s\n", filename);
        return NULL;
    }

    EVP_PKEY *pkey = NULL;
    if (is_public) {
        pkey = PEM_read_PUBKEY(file, NULL, NULL, NULL);
    } else {
        pkey = PEM_read_PrivateKey(file, NULL, NULL, NULL);
    }
    fclose(file);

    if (!pkey) {
        fprintf(stderr, "Failed to load key from %s\n", filename);
        return NULL;
    }

    char *hex;
    if (is_public) {
        hex = convert_ec_public_key_to_hex(pkey);
    } else {
        // Existing code for private key
    }

    EVP_PKEY_free(pkey);
    return hex;
}




int generate_ecdsa_keypair() {
    if (wally_init(0) != WALLY_OK) {  // Ensure WALLY_OK is defined in wally_core.h
        fprintf(stderr, "Failed to initialize libwally.\n");
        return 1;
    }

    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX *pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_EC, NULL);
    if (!pctx) handle_errors();

    if (EVP_PKEY_keygen_init(pctx) != 1) handle_errors();
    if (EVP_PKEY_CTX_set_ec_paramgen_curve_nid(pctx, NID_secp256k1) != 1) handle_errors();
    if (EVP_PKEY_keygen(pctx, &pkey) != 1) handle_errors();

    FILE *pub_fp = fopen("public_key.pem", "w");
    FILE *priv_fp = fopen("private_key.pem", "w");
    if (!pub_fp || !priv_fp || !PEM_write_PUBKEY(pub_fp, pkey) || !PEM_write_PrivateKey(priv_fp, pkey, NULL, NULL, 0, NULL, NULL)) {
        fprintf(stderr, "Failed to write keys to files.\n");
        if (pub_fp) fclose(pub_fp);
        if (priv_fp) fclose(priv_fp);
        EVP_PKEY_free(pkey);
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }
    fclose(pub_fp);
    fclose(priv_fp);

    char *pubkey_hex = convert_key_to_hex("public_key.pem", 1);
    char *privkey_hex = convert_key_to_hex("private_key.pem", 0);

    unsigned char entropy[32];
    char *mnemonic = NULL;
    if (RAND_bytes(entropy, sizeof(entropy)) != 1) {
        fprintf(stderr, "Failed to generate secure random bytes.\n");
        goto cleanup;
    }
    if (bip39_mnemonic_from_bytes(NULL, entropy, sizeof(entropy), &mnemonic) != WALLY_OK) {
        fprintf(stderr, "Failed to generate mnemonic.\n");
        goto cleanup;
    }
    output_json(pubkey_hex, privkey_hex, mnemonic);

cleanup:
    free(pubkey_hex);
    free(privkey_hex);
    if (mnemonic) wally_free_string(mnemonic);
    EVP_PKEY_free(pkey);
    EVP_PKEY_CTX_free(pctx);
    wally_cleanup(0);
    return 0;
}

int main() {
    OpenSSL_add_all_algorithms();
    ERR_load_crypto_strings();
    return generate_ecdsa_keypair();
}

