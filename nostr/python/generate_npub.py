import json, sys
from nostr.key import PrivateKey
from mnemonic import Mnemonic

__version__ = '0.0.1'


def generate_private_key():
    # Generate a new private key
    pk = PrivateKey()
    entropy = pk.raw_secret  # Get the raw entropy used to generate the private key
    return pk, entropy

def mnemonic_from_entropy(entropy):
    mnemo = Mnemonic("english")
    mnemonic_phrase = mnemo.to_mnemonic(entropy)
    return mnemonic_phrase

def entropy_from_mnemonic(mnemonic_phrase):
    mnemo = Mnemonic("english")
    entropy = mnemo.to_entropy(mnemonic_phrase)
    return entropy

def nsec_from_entropy(entropy):
    # Ensure the entropy is 32 bytes and a bytes object
    if isinstance(entropy, bytearray):
        entropy = bytes(entropy)
    if len(entropy) < 32:
        entropy = entropy.ljust(32, b'\x00')
    elif len(entropy) > 32:
        entropy = entropy[:32]

    pk = PrivateKey(entropy)
    return pk.bech32(), pk


def populate_json(pk, original_entropy):
    # Get the public key in bech32 format
    npub = pk.public_key.bech32()

    # Get the private key in bech32 format
    nsec = pk.bech32()

    # Generate mnemonic from original entropy
    mnemonic = mnemonic_from_entropy(original_entropy)

    # Verify that the mnemonic can be converted back to the same entropy
    derived_entropy = entropy_from_mnemonic(mnemonic)
    assert original_entropy == derived_entropy, "Entropy mismatch!"

    derrived_nsec = nsec_from_entropy(derived_entropy)[0]
    assert nsec == derrived_nsec, "nsec mismatch!"

    # Create the output dictionary
    if False:
        output = {
            "npub": npub,
            "nsec": nsec,
            "entropy": original_entropy.hex(),
            "bip39_nsec": mnemonic,
            "nsec_from_mnemonic": derrived_nsec
        }
    else:
        output = {
            "npub": npub,
            "nsec": nsec,
            "bip39_nsec": mnemonic,
        }
    return output
    
def generate_keypair_and_mnemonic():
    # Generate a new private key and entropy
    pk, original_entropy = generate_private_key()
    return populate_json(pk, original_entropy)


def get_keypair_from_nsec_hex(nsec_hex):
    # Convert the hexadecimal private key string to a bytes object
    entropy = bytes.fromhex(nsec_hex)

    # Generate the private key from the entropy
    pk = PrivateKey(entropy)

    # Populate and return the JSON output using the generated private key
    return populate_json(pk, entropy)


def get_keypair_from_mnemonic(mnemonic):
    # Assume input is a seed phrase (mnemonic)
    original_entropy = entropy_from_mnemonic(mnemonic)

    # Get the private key and public key
    pk = nsec_from_entropy(original_entropy)[1]
    return populate_json(pk, original_entropy)


if __name__ == "__main__":
    # Check if a mnemonic was provided as an argument
    if len(sys.argv) > 1:
        input_value = sys.argv[1]
        keypair_and_mnemonic = get_keypair_from_nsec_hex(input_value)
    else:
        keypair_and_mnemonic = generate_keypair_and_mnemonic()

    # Print the output as JSON
    print(json.dumps(keypair_and_mnemonic, indent=4))
