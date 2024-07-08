#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

#include <secp256k1.h>
#include <secp256k1_extrakeys.h>
#include <secp256k1_schnorrsig.h>

// Utility function to fill a buffer with random bytes
int fill_random(unsigned char *buf, size_t len) {
    FILE *fp = fopen("/dev/urandom", "rb");
    if (!fp) {
        return 0;
    }
    fread(buf, 1, len, fp);
    fclose(fp);
    return 1;
}

// Utility function to print a byte array as hex
void print_hex(const unsigned char *data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        printf("%02x", data[i]);
    }
    printf("\n");
}

// Utility function to securely erase a buffer
void secure_erase(unsigned char *buf, size_t len) {
    memset(buf, 0, len);
}

int main(void) {
    unsigned char msg[12] = "Hello World!";
    unsigned char msg_hash[32];
    unsigned char tag[17] = "my_fancy_protocol";
    unsigned char seckey[32];
    unsigned char randomize[32];
    unsigned char auxiliary_rand[32];
    unsigned char serialized_pubkey[32];
    unsigned char signature[64];
    int is_signature_valid, is_signature_valid2;
    int return_val;
    secp256k1_xonly_pubkey pubkey;
    secp256k1_keypair keypair;

    /* Before we can call actual API functions, we need to create a "context". */
    secp256k1_context* ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY);
    if (!fill_random(randomize, sizeof(randomize))) {
        printf("Failed to generate randomness\n");
        return 1;
    }

    /* Randomizing the context is recommended to protect against side-channel leakage */
    return_val = secp256k1_context_randomize(ctx, randomize);
    assert(return_val);

    /*** Key Generation ***/
    while (1) {
        if (!fill_random(seckey, sizeof(seckey))) {
            printf("Failed to generate randomness\n");
            return 1;
        }
        if (secp256k1_keypair_create(ctx, &keypair, seckey)) {
            break;
        }
    }

    /* Extract the X-only public key from the keypair */
    return_val = secp256k1_keypair_xonly_pub(ctx, &pubkey, NULL, &keypair);
    assert(return_val);

    /* Serialize the public key */
    return_val = secp256k1_xonly_pubkey_serialize(ctx, serialized_pubkey, &pubkey);
    assert(return_val);

    /*** Signing ***/
    /* Create a hash of the message using secp256k1_tagged_sha256 */
    return_val = secp256k1_tagged_sha256(ctx, msg_hash, tag, sizeof(tag), msg, sizeof(msg));
    assert(return_val);

    /* Generate 32 bytes of randomness for the signing function */
    if (!fill_random(auxiliary_rand, sizeof(auxiliary_rand))) {
        printf("Failed to generate randomness\n");
        return 1;
    }

    /* Generate a Schnorr signature */
    return_val = secp256k1_schnorrsig_sign32(ctx, signature, msg_hash, &keypair, auxiliary_rand);
    assert(return_val);

    /*** Verification ***/
    /* Deserialize the public key */
    if (!secp256k1_xonly_pubkey_parse(ctx, &pubkey, serialized_pubkey)) {
        printf("Failed parsing the public key\n");
        return 1;
    }

    /* Compute the tagged hash on the received messages */
    return_val = secp256k1_tagged_sha256(ctx, msg_hash, tag, sizeof(tag), msg, sizeof(msg));
    assert(return_val);

    /* Verify the signature */
    is_signature_valid = secp256k1_schnorrsig_verify(ctx, signature, msg_hash, 32, &pubkey);

    printf("Is the signature valid? %s\n", is_signature_valid ? "true" : "false");
    printf("Secret Key: ");
    print_hex(seckey, sizeof(seckey));
    printf("Public Key: ");
    print_hex(serialized_pubkey, sizeof(serialized_pubkey));
    printf("Signature: ");
    print_hex(signature, sizeof(signature));

    /* Clear everything from the context and free the memory */
    secp256k1_context_destroy(ctx);

    /* Verify the signature using the static context */
    is_signature_valid2 = secp256k1_schnorrsig_verify(secp256k1_context_static, signature, msg_hash, 32, &pubkey);
    assert(is_signature_valid2 == is_signature_valid);

    /* Securely erase the secret key */
    secure_erase(seckey, sizeof(seckey));
    return 0;
}

