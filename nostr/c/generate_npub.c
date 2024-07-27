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

int main() {
    OpenSSL_add_all_algorithms();
    if (generate_and_save_keys() != 0) {
        fprintf(stderr, "Key generation and saving failed.\n");
        return 1;
    }

    if (read_pubkey_and_convert_to_bech32("public_key.pem", "output.json") != 0) {
        fprintf(stderr, "Failed to process public key.\n");
        return 1;
    }

    EVP_cleanup();
    return 0;
}

