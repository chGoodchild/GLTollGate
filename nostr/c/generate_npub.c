#include <wally_core.h>
#include <wally_bip39.h>
#include <wally_address.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void output_json(const char* npub_hex, const char* nsec_hex, const char* mnemonic);

int generate_ecdsa_keypair() {
    wally_init(0);  // Initialize libwally

    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX *pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_EC, NULL);
    if (pctx == NULL) {
        fprintf(stderr, "Failed to create EVP_PKEY_CTX.\n");
        return 1;
    }

    if (EVP_PKEY_keygen_init(pctx) != 1) {
        fprintf(stderr, "Failed to initialize key generation context.\n");
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    if (EVP_PKEY_CTX_set_ec_paramgen_curve_nid(pctx, NID_secp256k1) != 1) {
        fprintf(stderr, "Failed to set EC curve.\n");
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    if (EVP_PKEY_keygen(pctx, &pkey) != 1) {
        fprintf(stderr, "Failed to generate EC key.\n");
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    FILE *pub_fp = fopen("public_key.pem", "w");
    FILE *priv_fp = fopen("private_key.pem", "w");

    if (pub_fp == NULL || priv_fp == NULL) {
        fprintf(stderr, "Failed to open file streams.\n");
        if (pub_fp) fclose(pub_fp);
        if (priv_fp) fclose(priv_fp);
        EVP_PKEY_free(pkey);
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    PEM_write_PUBKEY(pub_fp, pkey);
    PEM_write_PrivateKey(priv_fp, pkey, NULL, NULL, 0, NULL, NULL);
    fclose(pub_fp);
    fclose(priv_fp);

    // Assuming the functions to convert key data to hex are implemented (not shown here)
    char *pubkey_hex = "24b37f5ec0822b014c6ebb425641ac83529d47bce44d70272b3a95cf93f64cc1";  // Example hex
    char *privkey_hex = "c88eb4d229625c3969f4f9c5af9fa094a683588248cce5e3317b827439cb9c1a";  // Example hex

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
    if (mnemonic) wally_free_string(mnemonic);
    EVP_PKEY_free(pkey);
    EVP_PKEY_CTX_free(pctx);
    wally_cleanup(0);
    return 0;
}

int main() {
    OpenSSL_add_all_algorithms();
    return generate_ecdsa_keypair();
}

void output_json(const char* npub_hex, const char* nsec_hex, const char* mnemonic) {
    printf("{\n");
    printf("  \"npub_hex\": \"%s\",\n", npub_hex);
    printf("  \"nsec_hex\": \"%s\",\n", nsec_hex);
    printf("  \"bip39_nsec\": \"%s\"\n", mnemonic);
    printf("}\n");
}

