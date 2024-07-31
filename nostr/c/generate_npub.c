#include <wally_core.h>
#include <wally_bip39.h>
#include <wally_address.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/err.h>
#include <stdio.h>
#include <stdlib.h>


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

    int len;
    unsigned char *der = NULL;
    if (is_public) {
        len = i2d_PUBKEY(pkey, &der);
    } else {
        len = i2d_PrivateKey(pkey, &der);
    }
    EVP_PKEY_free(pkey);

    if (len < 0 || !der) {
        fprintf(stderr, "Error converting key to DER format\n");
        return NULL;
    }

    char *hex = to_hex(der, len);
    OPENSSL_free(der);  // Properly free the DER-encoded key data
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

