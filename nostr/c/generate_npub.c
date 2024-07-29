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

unsigned char* convert_der_to_bech32(const unsigned char* der, size_t der_len, char** bech32_address) {
    EVP_PKEY* pkey = NULL;
    const unsigned char* p = der;
    if (d2i_PublicKey(EVP_PKEY_EC, &pkey, &p, der_len) == NULL) {
        fprintf(stderr, "Failed to decode public key from DER.\n");
        return NULL;
    }

    // Use OSSL_ENCODER to handle key conversion
    OSSL_ENCODER_CTX* ctx = OSSL_ENCODER_CTX_new_for_pkey(pkey, OSSL_KEYMGMT_SELECT_PUBLIC_KEY, "TEXT", "legacy", NULL);
    if (ctx == NULL) {
        fprintf(stderr, "Encoder context creation failed.\n");
        EVP_PKEY_free(pkey);
        return NULL;
    }

    BIO* bio = BIO_new(BIO_s_mem());
    if (bio == NULL) {
        fprintf(stderr, "Failed to create BIO.\n");
        OSSL_ENCODER_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return NULL;
    }

    if (OSSL_ENCODER_to_bio(ctx, bio) <= 0) {
        fprintf(stderr, "Failed to encode public key.\n");
        BIO_free(bio);
        OSSL_ENCODER_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return NULL;
    }

    BUF_MEM* bptr = NULL;
    BIO_get_mem_ptr(bio, &bptr);
    char* raw_pubkey = malloc(bptr->length);
    memcpy(raw_pubkey, bptr->data, bptr->length);

    // Assume wally_address function is available to convert raw pubkey to Bech32
    if (wally_addr_segwit_from_bytes((unsigned char*)raw_pubkey, bptr->length, "bc", 0, bech32_address) != WALLY_OK) {
        fprintf(stderr, "Failed to convert public key to Bech32 address.\n");
        free(raw_pubkey);
        BIO_free(bio);
        OSSL_ENCODER_CTX_free(ctx);
        EVP_PKEY_free(pkey);
        return NULL;
    }

    free(raw_pubkey);
    BIO_free(bio);
    OSSL_ENCODER_CTX_free(ctx);
    EVP_PKEY_free(pkey);

    return 0; // Successfully converted
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

    size_t len_pub, len_priv; // Variables to hold the lengths of the keys
    unsigned char *der_pubkey = get_raw_key("public_key.pem", 0, &len_pub);
    unsigned char *der_privkey = get_raw_key("private_key.pem", 1, &len_priv);

    char* bech32_address = NULL;

    if (der_pubkey && convert_der_to_bech32(der_pubkey, len_pub, &bech32_address) == 0) {
        printf("Bech32 Address: %s\n", bech32_address);
        free(bech32_address);
    } else {
        fprintf(stderr, "Failed to convert DER to Bech32.\n");
    }

    free(der_pubkey);
    free(der_privkey);
    EVP_cleanup();
    return 0;

    EVP_cleanup();
    return 0;
}
