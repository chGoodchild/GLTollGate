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
    if (!(pctx && EVP_PKEY_keygen_init(pctx))) {
        fprintf(stderr, "Failed to initialize key generation context.\n");
        return 1;
    }

    pkey = EVP_PKEY_new();
    if (!EVP_PKEY_generate(pctx, &pkey)) {
        fprintf(stderr, "Failed to generate key.\n");
        EVP_PKEY_CTX_free(pctx);
        return 1;
    }

    // Memory streams for public and private keys
    unsigned char *pubkey = NULL, *privkey = NULL;
    size_t pubkey_len = 0, privkey_len = 0;
    FILE *pub_fp = open_memstream((char **)&pubkey, &pubkey_len);
    FILE *priv_fp = open_memstream((char **)&privkey, &privkey_len);

    PEM_write_PUBKEY(pub_fp, pkey);
    PEM_write_PrivateKey(priv_fp, pkey, NULL, NULL, 0, NULL, NULL);
    fclose(pub_fp);
    fclose(priv_fp);

    // Generate BIP-39 Mnemonic
    unsigned char entropy[32];
    char *mnemonic = NULL;
    if (RAND_bytes(entropy, sizeof(entropy)) != 1) {
        fprintf(stderr, "Failed to generate secure random bytes.\n");
        goto end;
    }
    
    if (bip39_mnemonic_from_bytes(NULL, entropy, sizeof(entropy), &mnemonic) != WALLY_OK) {
        fprintf(stderr, "Failed to generate mnemonic.\n");
        goto end;
    }

    // Output in JSON format
    output_json((const char*)pubkey, (const char*)privkey, mnemonic);

end:
    free(pubkey);
    free(privkey);
    if (mnemonic) wally_free_string(mnemonic);
    if (pkey) EVP_PKEY_free(pkey);
    if (pctx) EVP_PKEY_CTX_free(pctx);

    wally_cleanup(0);  // Cleanup libwally resources
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

