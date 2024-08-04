#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/ec.h>

// Dummy function assuming 'wally_addr_segwit_from_bytes' is defined elsewhere
int wally_addr_segwit_from_bytes(const unsigned char *pub_key, size_t pub_key_len, const char *hrp, int version, char **output) {
    *output = malloc(50); // Just a dummy allocation for testing
    sprintf(*output, "bc1qx2gw3t4t5qpszj602ed2s8u9m79l09x6qqpqrz");
    return 0; // Simulating success
}

void free_wally_string(char *str) {
    free(str);
}

int convert_der_to_bech32(const unsigned char* der, size_t der_len, char** bech32_address) {
    EVP_PKEY* pkey = NULL;
    const unsigned char* p = der;

    printf("Attempting to decode DER data of length: %zu\n", der_len);
    for (size_t i = 0; i < der_len; i++) {
        printf("%02X ", der[i]);
    }
    printf("\n");

    pkey = EVP_PKEY_new();
    if (!pkey) {
        fprintf(stderr, "Failed to allocate EVP_PKEY.\n");
        return 1;
    }

    if (d2i_PublicKey(EVP_PKEY_EC, &pkey, &p, der_len) == NULL) {
        ERR_print_errors_fp(stderr);
        fprintf(stderr, "Failed to decode public key from DER.\n");
        EVP_PKEY_free(pkey);
        return 1;
    }

    int result = wally_addr_segwit_from_bytes(der, der_len, "bc", 0, bech32_address);
    if (result != 0) {
        fprintf(stderr, "Failed to convert public key to Bech32 address.\n");
        EVP_PKEY_free(pkey);
        return 1;
    }

    EVP_PKEY_free(pkey);
    return 0;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <hex_der>\n", argv[0]);
        return 1;
    }

    // Convert hex to binary
    size_t der_len = strlen(argv[1]) / 2;
    unsigned char* der = malloc(der_len);
    if (!der) {
        fprintf(stderr, "Memory allocation failed.\n");
        return 1;
    }

    for (size_t i = 0; i < der_len; i++) {
        sscanf(&argv[1][i * 2], "%2hhx", &der[i]);
    }

    char* bech32_address = NULL;
    if (convert_der_to_bech32(der, der_len, &bech32_address) == 0) {
        printf("Generated Bech32 address: %s\n", bech32_address);
        free_wally_string(bech32_address);
    } else {
        fprintf(stderr, "Conversion failed.\n");
    }

    free(der);
    return 0;
}
