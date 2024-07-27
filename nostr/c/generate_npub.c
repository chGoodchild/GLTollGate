#include <wally_core.h>
#include <wally_bip39.h>
#include <wally_address.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void output_json(const char* npub, const char* nsec, const char* mnemonic);

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

    unsigned char *pubkey = NULL, *privkey = NULL;
    size_t pubkey_len = 0, privkey_len = 0;
    FILE *pub_fp = open_memstream((char **)&pubkey, &pubkey_len);
    FILE *priv_fp = open_memstream((char **)&privkey, &privkey_len);

    if (pub_fp == NULL || priv_fp == NULL) {
        fprintf(stderr, "Failed to create memory streams.\n");
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

    output_json((const char*)pubkey, (const char*)privkey, mnemonic);

cleanup:
    free(pubkey);
    free(privkey);
    if (mnemonic) wally_free_string(mnemonic);
    if (pkey) EVP_PKEY_free(pkey);
    if (pctx) EVP_PKEY_CTX_free(pctx);

    wally_cleanup(0);
    return 0;
}

int main() {
    // Initialize OpenSSL algorithms
    OpenSSL_add_all_algorithms();

    // Generate the keypair
    return generate_ecdsa_keypair();
}

void output_json(const char* npub, const char* nsec, const char* mnemonic) {
    printf("{\n");
    printf("  \"npub\": \"%s\",\n", npub);
    printf("  \"nsec\": \"%s\",\n", nsec);
    printf("  \"bip39_nsec\": \"%s\"\n", mnemonic);
    printf("}\n");
}

