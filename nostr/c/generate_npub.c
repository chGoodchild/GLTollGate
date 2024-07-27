// #include "~/libbtc/src/trezor-crypto/bip39.h"
#include "/home/pachai/libbtc/src/trezor-crypto/bip39.h"
// #include <wally_core.h>  // Adjust include based on actual Bech32 library used
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void generate_ecdsa_keypair() {
    // Initialize libraries (if needed)
    btc_init();  // Initializes libbtc, needed for BIP-39

    EVP_PKEY *pkey = NULL;
    EVP_PKEY_CTX *pctx = EVP_PKEY_CTX_new_id(EVP_PKEY_EC, NULL);
    unsigned char *pubkey = NULL, *privkey = NULL;
    char *mnemonic = NULL;
    char *bech32_pub = NULL, *bech32_priv = NULL;
    size_t pubkey_len = 0, privkey_len = 0;
    FILE *pub_fp = open_memstream((char **)&pubkey, &pubkey_len);
    FILE *priv_fp = open_memstream((char **)&privkey, &privkey_len);

    PEM_write_PUBKEY(pub_fp, pkey);
    PEM_write_PrivateKey(priv_fp, pkey, NULL, NULL, 0, NULL, NULL);
    fclose(pub_fp);
    fclose(priv_fp);

    // Convert to Bech32
    // Note: You will need to write or use a function that converts public and private key bytes to Bech32.
    bech32_pub = convert_to_bech32(pubkey, pubkey_len);
    bech32_priv = convert_to_bech32(privkey, privkey_len);

    // Generate BIP-39 Mnemonic
    unsigned char entropy[32];
    if (RAND_bytes(entropy, sizeof(entropy)) != 1) {
        fprintf(stderr, "Failed to generate secure random bytes.\n");
        goto end;
    }
    mnemonic = mnemonic_from_data(entropy, sizeof(entropy));

    // Output in JSON format
    output_json(bech32_pub, bech32_priv, mnemonic);

end:
    free(pubkey);
    free(privkey);
    free(mnemonic);
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

char* entropy_to_mnemonic(unsigned char *entropy, size_t size) {
    // Implement or call your mnemonic generation library here
    return strdup("example-mnemonic-phrase");
}

void output_json(const char* npub, const char* nsec, const char* mnemonic) {
    printf("{\n");
    printf("  \"npub\": \"%s\",\n", npub);
    printf("  \"nsec\": \"%s\",\n", nsec);
    printf("  \"bip39_nsec\": \"%s\"\n", mnemonic);
    printf("}\n");
}

