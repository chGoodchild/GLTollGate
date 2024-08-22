#include "nostri.h"
#include <stdio.h>   // For fprintf, printf
#include <stdlib.h>  // For free
#include <string.h>  // For strlen

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <recipient_pubkey> <message> <private_key>\n", argv[0]);
        return 1;
    }

    secp256k1_context* ctx = NULL;
    struct key sender_key;
    struct nostr_event event;
    char* json_output = NULL;

    init_secp_context(&ctx);

    if (!decode_key(ctx, argv[3], &sender_key)) {
        fprintf(stderr, "Key decoding failed\n");
        return 1;
    }

    struct args event_args = {
        .flags = HAS_KIND | HAS_ENCRYPT,
        .kind = 14, // NIP-17 DM kind
        .content = argv[2],
        .encrypt_to = {0}, // Set this with recipient's pubkey
    };
    hex_decode(argv[1], strlen(argv[1]), event_args.encrypt_to, sizeof(event_args.encrypt_to));

    make_event_from_args(&event, &event_args);
    sign_event(ctx, &sender_key, &event);
    print_event(&event, &json_output);

    printf("%s\n", json_output);

    // Free resources
    free(json_output);
    secp256k1_context_destroy(ctx);
    secure_erase(sender_key.secret, sizeof(sender_key.secret));
    return 0;
}

