#include <wally_core.h>
#include <wally_bip39.h>
#include <wally_address.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/ec.h>
#include <openssl/obj_mac.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void output_json(const char* npub, const char* nsec, const char* mnemonic);

int generate_ecdsa_keypair() {
    wally_init(0);

    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX *pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_EC, NULL);
    if (!pctx) {
        fprintf(stderr, "Failed to create EVP_PKEY_CTX.\n");
        return 1;
    }

    if (EVP_PKEY_keygen_init(pctx) != 1 || EVP_PKEY_CTX_set_ec_paramgen_curve_nid(pctx, NID_secp256k1) != 1) {
        fprintf(stderr, "Failed to initialize EC key generation.\n");
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    if (EVP_PKEY_keygen(pctx, &pkey) != 1) {
        fprintf(stderr, "Failed to generate EC key.\n");
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    // Use the EVP_PKEY directly to extract the public key bytes
    size_t pubkey_len = 0;
    EVP_PKEY_get_raw_public_key(pkey, NULL, &pubkey_len); // Get length first
    unsigned char *pubkey = malloc(pubkey_len);
    if (!EVP_PKEY_get_raw_public_key(pkey, pubkey, &pubkey_len)) {
        fprintf(stderr, "Failed to get raw public key.\n");
        free(pubkey);
        EVP_PKEY_free(pkey);
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    char *address = NULL;
    if (wally_addr_segwit_from_bytes(pubkey, pubkey_len, "bc", 0, &address) != WALLY_OK) {
        fprintf(stderr, "Failed to convert public key to Bech32 address.\n");
        free(pubkey);
        EVP_PKEY_free(pkey);
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    unsigned char entropy[32];
    char *mnemonic = NULL;
    if (RAND_bytes(entropy, sizeof(entropy)) != 1 || bip39_mnemonic_from_bytes(NULL, entropy, sizeof(entropy), &mnemonic) != WALLY_OK) {
        fprintf(stderr, "Failed to generate mnemonic.\n");
        if (mnemonic) wally_free_string(mnemonic);
        free(pubkey);
        EVP_PKEY_free(pkey);
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    output_json(address, "Private key not exposed", mnemonic);

    free(address);
    wally_free_string(mnemonic);
    free(pubkey);
    EVP_PKEY_free(pkey);
    EVP_PKEY_CTX_free(pctx);
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

