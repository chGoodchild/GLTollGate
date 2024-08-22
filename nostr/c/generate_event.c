#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <secp256k1.h>
#include <secp256k1_extrakeys.h>
#include <secp256k1_schnorrsig.h>

#include "nostri.h"

// Correct the function signature to match the declaration in nostri.h
/**
void print_hex(unsigned char *data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        printf("%02x", data[i]);
    }
    printf("\n");
}
**/

void secure_erase(unsigned char *buf, size_t len) {
    memset(buf, 0, len);
}

int fill_random(unsigned char *buf, size_t len) {
    FILE *fp = fopen("/dev/urandom", "rb");
    if (!fp) {
        return 0;
    }
    size_t read_len = fread(buf, 1, len, fp);
    fclose(fp);
    return read_len == len;
}

// Main function combining generate_dm and sign_event logic
int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s command [options]\n", argv[0]);
        return 1;
    }

    if (strcmp(argv[1], "generate_dm") == 0 && argc == 5) {
        // DM generation logic
        secp256k1_context* ctx = NULL;
        struct key sender_key;
        struct nostr_event event;
        char* json_output = NULL;

        init_secp_context(&ctx);

        if (!decode_key(ctx, argv[4], &sender_key)) {
            fprintf(stderr, "Key decoding failed\n");
            return 1;
        }

        struct args event_args = {
            .flags = HAS_KIND | HAS_ENCRYPT,
            .kind = 14,
            .content = argv[3],
            .encrypt_to = {0},
        };
        hex_decode(argv[2], strlen(argv[2]), event_args.encrypt_to, sizeof(event_args.encrypt_to));

        make_event_from_args(&event, &event_args);
        sign_event(ctx, &sender_key, &event);
        print_event(&event, &json_output);

        printf("%s\n", json_output);

        free(json_output);
        secp256k1_context_destroy(ctx);
        secure_erase(sender_key.secret, sizeof(sender_key.secret));
    } else if (strcmp(argv[1], "sign_event") == 0 && argc == 4) {
        // Event signing logic
        secp256k1_context* ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY);
        unsigned char msg_hash[32], seckey[32], signature[64], auxiliary_rand[32];

        // Parse inputs
        for (int i = 0; i < 32; i++) {
            sscanf(&argv[2][2 * i], "%2hhx", &msg_hash[i]);
            sscanf(&argv[3][2 * i], "%2hhx", &seckey[i]);
        }

        if (!secp256k1_context_randomize(ctx, msg_hash)) {
            fprintf(stderr, "Context randomization failed\n");
            secp256k1_context_destroy(ctx);
            return 1;
        }

        secp256k1_keypair keypair;
        if (!secp256k1_keypair_create(ctx, &keypair, seckey)) {
            fprintf(stderr, "Failed to create keypair\n");
            secp256k1_context_destroy(ctx);
            return 1;
        }

        if (!fill_random(auxiliary_rand, sizeof(auxiliary_rand))) {
            fprintf(stderr, "Failed to generate randomness\n");
            secp256k1_context_destroy(ctx);
            return 1;
        }

        if (!secp256k1_schnorrsig_sign32(ctx, signature, msg_hash, &keypair, auxiliary_rand)) {
            fprintf(stderr, "Failed to sign message\n");
            secp256k1_context_destroy(ctx);
            return 1;
        }

        print_hex(signature, sizeof(signature));
        secp256k1_context_destroy(ctx);
        secure_erase(seckey, sizeof(seckey));
    } else {
        fprintf(stderr, "Invalid command or incorrect number of arguments\n");
        return 1;
    }

    return 0;
}

