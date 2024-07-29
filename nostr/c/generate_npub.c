#include <wally_core.h>
#include <wally_bip39.h>
#include <wally_address.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/pem.h>
#include <openssl/ec.h> // Necessary for EC functions
#include <openssl/obj_mac.h> // For NID_secp256k1
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/bn.h>
#include <stdbool.h>
#include <openssl/encoder.h>
#include <openssl/err.h>  // For ERR_print_errors_fp


void output_json(const char* filename, const char* address) {
    FILE *fp = fopen(filename, "w");
    if (fp) {
        fprintf(fp, "{\"Bech32\": \"%s\"}\n", address);
        fclose(fp);
    } else {
        fprintf(stderr, "Failed to write to JSON file.\n");
    }
}

int generate_and_save_keys() {
    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX *pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_EC, NULL);
    if (!pctx || EVP_PKEY_keygen_init(pctx) != 1 || EVP_PKEY_CTX_set_ec_paramgen_curve_nid(pctx, NID_secp256k1) != 1) {
        fprintf(stderr, "Failed to initialize EC key generation.\n");
        if (pctx) EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    if (EVP_PKEY_keygen(pctx, &pkey) != 1) {
        fprintf(stderr, "Failed to generate EC key.\n");
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    FILE *fp_pub = fopen("public_key.pem", "w");
    FILE *fp_priv = fopen("private_key.pem", "w");

    if (!fp_pub || !fp_priv || !PEM_write_PUBKEY(fp_pub, pkey) || !PEM_write_PrivateKey(fp_priv, pkey, NULL, NULL, 0, NULL, NULL)) {
        fprintf(stderr, "Failed to write keys to PEM files.\n");
        if (fp_pub) fclose(fp_pub);
        if (fp_priv) fclose(fp_priv);
        EVP_PKEY_free(pkey);
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    fclose(fp_pub);
    fclose(fp_priv);
    EVP_PKEY_free(pkey);
    EVP_PKEY_CTX_free(pctx);
    return 0;
}

int read_pubkey_and_convert_to_bech32(const char *pubkey_filename, const char *json_filename) {
    FILE *fp = fopen(pubkey_filename, "r");
    if (!fp) {
        fprintf(stderr, "Failed to open public key PEM file.\n");
        return 1;
    }

    EVP_PKEY *pkey = PEM_read_PUBKEY(fp, NULL, NULL, NULL);
    fclose(fp);

    if (!pkey) {
        fprintf(stderr, "Failed to read public key from PEM file.\n");
        return 1;
    }

    unsigned char *pubkey_raw;
    size_t pubkey_raw_len;
    EVP_PKEY_get_raw_public_key(pkey, NULL, &pubkey_raw_len);
    pubkey_raw = malloc(pubkey_raw_len);
    if (!EVP_PKEY_get_raw_public_key(pkey, pubkey_raw, &pubkey_raw_len)) {
        fprintf(stderr, "Failed to extract raw public key.\n");
        free(pubkey_raw);
        EVP_PKEY_free(pkey);
        return 1;
    }

    char *address = NULL;
    if (wally_addr_segwit_from_bytes(pubkey_raw, pubkey_raw_len, "bc", 0, &address) != WALLY_OK) {
        fprintf(stderr, "Failed to convert public key to Bech32 address.\n");
        free(pubkey_raw);
        EVP_PKEY_free(pkey);
        return 1;
    }

    output_json(json_filename, address);

    free(address);
    free(pubkey_raw);
    EVP_PKEY_free(pkey);
    return 0;
}


// Function to extract raw public key data
unsigned char* get_raw_public_key(EVP_PKEY *pkey, size_t *out_len) {
    unsigned char *buf = NULL;
    OSSL_ENCODER_CTX *ctx = OSSL_ENCODER_CTX_new_for_pkey(pkey, OSSL_KEYMGMT_SELECT_PUBLIC_KEY, "DER", NULL, NULL);
    if (!ctx) {
        fprintf(stderr, "Failed to create encoder context for public key.\n");
        ERR_print_errors_fp(stderr);
        return NULL;
    }

    if (!OSSL_ENCODER_to_data(ctx, &buf, out_len)) {
        fprintf(stderr, "Failed to encode public key.\n");
        ERR_print_errors_fp(stderr);
        OSSL_ENCODER_CTX_free(ctx);
        return NULL;
    }

    OSSL_ENCODER_CTX_free(ctx);
    return buf;
}

// Function to print raw private key data
unsigned char* get_raw_private_key(EVP_PKEY *pkey, size_t *out_len) {
    unsigned char *buf = NULL;
    OSSL_ENCODER_CTX *ctx = OSSL_ENCODER_CTX_new_for_pkey(pkey, OSSL_KEYMGMT_SELECT_PRIVATE_KEY, "DER", NULL, NULL);
    if (!ctx) {
        fprintf(stderr, "Failed to create encoder context for private key.\n");
        ERR_print_errors_fp(stderr);
        return NULL;
    }

    if (!OSSL_ENCODER_to_data(ctx, &buf, out_len)) {
        fprintf(stderr, "Failed to encode private key.\n");
        ERR_print_errors_fp(stderr);
        OSSL_ENCODER_CTX_free(ctx);
        return NULL;
    }

    OSSL_ENCODER_CTX_free(ctx);
    return buf;
}


// Modified function to handle both public and private keys
unsigned char* get_raw_key(const char *key_filename, int is_private, size_t *out_len) {
    FILE *fp = fopen(key_filename, "r");
    if (!fp) {
        fprintf(stderr, "Failed to open key PEM file.\n");
        return NULL;
    }

    EVP_PKEY *pkey = NULL;
    if (is_private) {
        pkey = PEM_read_PrivateKey(fp, NULL, NULL, NULL);
    } else {
        pkey = PEM_read_PUBKEY(fp, NULL, NULL, NULL);
    }
    fclose(fp);

    if (!pkey) {
        fprintf(stderr, "Failed to read key from PEM file.\n");
        return NULL;
    }

    unsigned char *raw_key = is_private ? get_raw_private_key(pkey, out_len) : get_raw_public_key(pkey, out_len);
    EVP_PKEY_free(pkey);
    return raw_key;
}

int main() {
    OpenSSL_add_all_algorithms();
    if (generate_and_save_keys() != 0) {
        fprintf(stderr, "Key generation and saving failed.\n");
        return 1;
    }


    size_t len_pub, len_priv; // Declare these variables to hold the lengths of the keys
    unsigned char *raw_pubkey = get_raw_key("public_key.pem", 0, &len_pub);
    unsigned char *raw_privkey = get_raw_key("private_key.pem", 1, &len_priv);


    if (raw_pubkey) {
        printf("Public Key: ");
        for (size_t i = 0; i < len_pub; i++) {
            printf("%02x", raw_pubkey[i]);
        }
        printf("\n");
        free(raw_pubkey); // Free the allocated buffer
    }

    if (raw_privkey) {
        printf("Private Key: ");
        for (size_t i = 0; i < len_priv; i++) {
            printf("%02x", raw_privkey[i]);
        }
        printf("\n");
        free(raw_privkey); // Free the allocated buffer
    }

    /**
    if (read_pubkey_and_convert_to_bech32("public_key.pem", "output.json") != 0) {
        fprintf(stderr, "Failed to process public key.\n");
        return 1;
    }
    **/

    EVP_cleanup();
    return 0;
}

