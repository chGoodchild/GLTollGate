#include <wally_core.h>
#include <wally_bip39.h>
#include <wally_address.h>
#include <openssl/evp.h>
#include <openssl/ec.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/bio.h>
#include <openssl/err.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "bech32.h"

void output_json(const char* npub, const char* nsec, const char* mnemonic);

char *encode_bech32(unsigned char *data, size_t data_len) {
    char *encoded;
    bech32_encode(&encoded, "bc", data, data_len);
    return encoded;
}

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

    // Extract the raw private key in DER format
    BIO *priv_bio = BIO_new(BIO_s_mem());
    PEM_write_bio_PrivateKey(priv_bio, pkey, NULL, NULL, 0, NULL, NULL);
    size_t privkey_len = BIO_pending(priv_bio);
    unsigned char *privkey = malloc(privkey_len);  // Allocate memory for private key
    BIO_read(priv_bio, privkey, privkey_len);
    BIO_free(priv_bio);

    // Extract the raw public key in DER format
    BIO *pub_bio = BIO_new(BIO_s_mem());
    PEM_write_bio_PUBKEY(pub_bio, pkey);
    size_t pubkey_len = BIO_pending(pub_bio);
    unsigned char *pubkey = malloc(pubkey_len);  // Allocate memory for public key
    BIO_read(pub_bio, pubkey, pubkey_len);
    BIO_free(pub_bio);

    // Convert both keys to Bech32
    char *npub = encode_bech32(pubkey, pubkey_len);
    char *nsec = encode_bech32(privkey, privkey_len);

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

    output_json(npub, nsec, mnemonic);

cleanup:
    free(npub);
    free(nsec);
    free(pubkey);
    free(privkey);
    if (mnemonic) wally_free_string(mnemonic);
    if (pkey) EVP_PKEY_free(pkey);
    if (pctx) EVP_PKEY_CTX_free(pctx);

    wally_cleanup(0);
    return 0;
}

int main() {
    OpenSSL_add_all_algorithms();
    int result = generate_ecdsa_keypair();
    EVP_cleanup();
    return result;
}

void output_json(const char* npub, const char* nsec, const char* mnemonic) {
    printf("{\n");
    printf("  \"npub\": \"%s\",\n", npub);
    printf("  \"nsec\": \"%s\",\n", nsec);
    printf("  \"bip39_nsec\": \"%s\"\n", mnemonic);
    printf("}\n");
}

