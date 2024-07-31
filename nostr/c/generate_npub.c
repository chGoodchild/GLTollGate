#include <stdint.h>  // Include this line to define uint64_t and other standard integer types
#include "../../../nostr_client_relay/src/nostril/nostri.h"

#include <stdio.h>   // For FILE, fopen, fprintf, fclose, etc.
#include <stdlib.h>  // For malloc and free
#include <string.h>  // If you need memory functions like memset etc.
#include <stddef.h>  // For NULL

/**
#include <openssl/evp.h>        // For EVP_PKEY, EVP_PKEY_CTX, etc.
#include <openssl/pem.h>        // For PEM_read_PUBKEY, PEM_read_PrivateKey
#include <openssl/rand.h>       // For RAND_bytes
#include <openssl/bn.h>         // For BIGNUM functions
#include <openssl/err.h>        // For error handling
#include <openssl/encoder.h>
#include <openssl/core_names.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>
**/

// #include <wally_core.h>         // For libwally functions
#include <wally_bip39.h>        // For mnemonic generation
// #include <wally_address.h>      // Additional libwally functionality

// Function Declarations
//void handle_errors();
void output_json(const char* npub_hex, const char* nsec_hex);
char* to_hex(const unsigned char *data, int length);
char* convert_key_to_hex(const char* filename, int is_public);  // Function declaration


/**
void handle_errors() {
    ERR_print_errors_fp(stderr);
    abort();
}
**/

void output_json(const char* npub_hex, const char* nsec_hex) {
    printf("{\n");
    printf("  \"npub_hex\": \"%s\",\n", npub_hex);
    printf("  \"nsec_hex\": \"%s\",\n", nsec_hex);
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

/**
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

    EVP_PKEY *pkey = is_public ? PEM_read_PUBKEY(file, NULL, NULL, NULL) : PEM_read_PrivateKey(file, NULL, NULL, NULL);
    fclose(file);

    if (!pkey) {
        fprintf(stderr, "Failed to load key from %s\n", filename);
        return NULL;
    }

    unsigned char *der = NULL;
    int len = is_public ? i2d_PUBKEY(pkey, &der) : i2d_PrivateKey(pkey, &der);
    if (len < 0 || !der) {
        fprintf(stderr, "Failed to convert key to DER format\n");
        EVP_PKEY_free(pkey);
        return NULL;
    }

    char *hex = to_hex(der, len);
    OPENSSL_free(der);  // It's important to free the DER data
    EVP_PKEY_free(pkey);

    return hex;
}
**/


int generate_ecdsa_keypair() {
    secp256k1_context *ctx = NULL;
    if (!init_secp_context(&ctx)) {
        fprintf(stderr, "Failed to initialize secp256k1 context.\n");
        return 1;
    }

    struct key my_key;
    if (!generate_key(ctx, &my_key, NULL)) { // Assuming no mining difficulty needed
        fprintf(stderr, "Key generation failed.\n");
        secp256k1_context_destroy(ctx);
        return 1;
    }

    char *pubkey_hex = to_hex(my_key.pubkey, 32);
    char *privkey_hex = to_hex(my_key.secret, 32);

    /**
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
    **/
    output_json(pubkey_hex, privkey_hex);

    free(pubkey_hex);
    free(privkey_hex);
    // if (mnemonic) wally_free_string(mnemonic);
    secp256k1_context_destroy(ctx);
    return 0;
}


int main() {
    // OpenSSL_add_all_algorithms();
    // ERR_load_crypto_strings();
    return generate_ecdsa_keypair();
}

