#include <stdio.h>   // For printf
#include <stdlib.h>  // For malloc, free
#include <string.h>  // For memory functions like memset
// #include <wally_bip39.h> // For mnemonic generation from wally

// Include the necessary header for secp256k1 context and key generation
#include "../../../nostr_client_relay/src/nostril/nostri.h"

// Function Declarations
void output_json(const char* npub_hex, const char* nsec_hex);
char* to_hex(const unsigned char *data, int length);

void output_json(const char* npub_hex, const char* nsec_hex) {
    printf("{\n");
    printf("  \"npub_hex\": \"%s\",\n", npub_hex);
    printf("  \"nsec_hex\": \"%s\"\n", nsec_hex);
    printf("}\n");
}

char* to_hex(const unsigned char *data, int length) {
    char* hex_string = malloc(length * 2 + 1);
    if (!hex_string) return NULL;
    for (int i = 0; i < length; ++i) {
        sprintf(hex_string + (i * 2), "%02x", data[i]);
    }
    hex_string[length * 2] = '\0';
    return hex_string;
}

int generate_ecdsa_keypair() {
    secp256k1_context *ctx = NULL;
    if (!init_secp_context(&ctx)) {
        fprintf(stderr, "Failed to initialize secp256k1 context.\n");
        return 1;
    }

    struct key my_key;
    if (!generate_key(ctx, &my_key, NULL)) {
        fprintf(stderr, "Key generation failed.\n");
        secp256k1_context_destroy(ctx);
        return 1;
    }

    char *pubkey_hex = to_hex(my_key.pubkey, 32);
    char *privkey_hex = to_hex(my_key.secret, 32);

    output_json(pubkey_hex, privkey_hex);

    free(pubkey_hex);
    free(privkey_hex);
    secp256k1_context_destroy(ctx);
    return 0;
}

int main() {
    return generate_ecdsa_keypair();
}
