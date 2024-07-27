#include "/home/pachai/libbtc/src/trezor-crypto/bip39.h"
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Declare these functions if their implementations are not included in the headers
void btc_init(void);
void btc_cleanup(void);
char* convert_to_bech32(const unsigned char* data, size_t len);
const char* mnemonic_from_data(const uint8_t* data, int len);
void output_json(const char* npub, const char* nsec, const char* mnemonic);

void generate_ecdsa_keypair() {
    // Initialize libraries (if needed)
    btc_init();  // Initializes libbtc, needed for BIP-39

    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX *pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_EC, NULL);
    if (!(pctx && EVP_PKEY_keygen_init(pctx))) {
        fprintf(stderr, "Failed to initialize key generation context.\n");
        return;
    }

    // Generate key
    pkey = EVP_PKEY_new();
    if (!EVP_PKEY_generate(pctx, &pkey)) {
        fprintf(stderr, "Failed to generate key.\n");
        EVP_PKEY_CTX_free(pctx);
        return;
    }

    unsigned char *pubkey = NULL, *privkey = NULL;
    size_t pubkey_len = 0, privkey_len = 0;
    FILE *pub_fp = open_memstream((char **)&pubkey, &pubkey_len);
    FILE *priv_fp = open_memstream((char **)&privkey, &privkey_len);

    PEM_write_PUBKEY(pub_fp, pkey);
    PEM_write_PrivateKey(priv_fp, pkey, NULL, NULL, 0, NULL, NULL);
    fclose(pub_fp);
    fclose(priv_fp);

    // Convert to Bech32
    char *bech32_pub = convert_to_bech32(pubkey, pubkey_len);
    char *bech32_priv = convert_to_bech32(privkey, privkey_len);

    // Generate BIP-39 Mnemonic
    unsigned char entropy[32];
    if (RAND_bytes(entropy, sizeof(entropy)) != 1) {
        fprintf(stderr, "Failed to generate secure random bytes.\n");
        goto end;
    }
    const char *mnemonic = mnemonic_from_data(entropy, sizeof(entropy));

    // Output in JSON format
    output_json(bech32_pub, bech32_priv, mnemonic);

end:
    free(pubkey);
    free(privkey);
    free(bech32_pub);
    free(bech32_priv);
    if (pkey) EVP_PKEY_free(pkey);
    if (pctx) EVP_PKEY_CTX_free(pctx);

    btc_cleanup();  // Cleanup libbtc resources
}

int main() {
    // Initialize OpenSSL algorithms
    OpenSSL_add_all_algorithms();

    // Generate the keypair
    generate_ecdsa_keypair();
    return 0;
}

void output_json(const char* npub, const char* nsec, const char* mnemonic) {
    printf("{\n");
    printf("  \"npub\": \"%s\",\n", npub);
    printf("  \"nsec\": \"%s\",\n", nsec);
    printf("  \"bip39_nsec\": \"%s\"\n", mnemonic);
    printf("}\n");
}

