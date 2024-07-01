#!/bin/bash

# Check if Nsec argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <nsec>"
  exit 1
fi

# Save the Nsec argument
NSEC=$1

# Install necessary npm packages
npm install bip39

# Create the Node.js script to convert Nsec to mnemonic
cat << 'EOF' > key_to_mnemonic.js
const bip39 = require('bip39');

// Get the Nsec (private key) from command line arguments
const nsec = process.argv[2];

// Remove the 'nsec' prefix if present
const nsecClean = nsec.startsWith('nsec') ? nsec.slice(4) : nsec;

// Convert the Nsec hex string to a Buffer
const entropyBuffer = Buffer.from(nsecClean, 'hex');

// Convert the entropy buffer to entropy (hex string)
const entropyHex = entropyBuffer.toString('hex');

// Convert the entropy (hex string) to a mnemonic
const mnemonic = bip39.entropyToMnemonic(entropyHex);

console.log("Your BIP39 mnemonic is:", mnemonic);
EOF

# Run the Node.js script
node key_to_mnemonic.js "$NSEC"

# Clean up
rm key_to_mnemonic.js
