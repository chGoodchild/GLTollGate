#!/bin/bash

# Check if mnemonic argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <mnemonic>"
  exit 1
fi

# Save the mnemonic argument
MNEMONIC=$1

# Install necessary npm packages
npm install bip39 ecpair tiny-secp256k1

# Create the Node.js script to convert mnemonic to Nsec/Npub
cat << 'EOF' > mnemonic_to_key.js
const bip39 = require('bip39');
const { ECPairFactory } = require('ecpair');
const ecc = require('tiny-secp256k1');

// Use ECPairFactory to create an ECPair instance
const ECPair = ECPairFactory(ecc);

// Get the mnemonic from command line arguments
const mnemonic = process.argv[2];

// Convert the mnemonic to entropy (hex string)
const entropyHex = bip39.mnemonicToEntropy(mnemonic);

// Convert the entropy hex string to a Buffer
let entropyBuffer = Buffer.from(entropyHex, 'hex');

// Ensure the buffer is 32 bytes long by padding if necessary
if (entropyBuffer.length < 32) {
  const padding = Buffer.alloc(32 - entropyBuffer.length, 0);
  entropyBuffer = Buffer.concat([padding, entropyBuffer]);
}

// Convert the entropy buffer to hex format for Nsec
const nsec = entropyBuffer.toString('hex');

// Generate public key (Npub) from the private key (Nsec)
const keyPair = ECPair.fromPrivateKey(entropyBuffer);
const npub = keyPair.publicKey.toString('hex');

console.log("Your Nsec (private key) is:", "nsec" + nsec);
console.log("Your Npub (public key) is:", "npub" + npub);
EOF

# Run the Node.js script
node mnemonic_to_key.js "$MNEMONIC"

# Clean up
rm mnemonic_to_key.js

