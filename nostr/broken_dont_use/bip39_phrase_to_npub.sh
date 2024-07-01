#!/bin/bash

# Check if mnemonic argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <mnemonic>"
  exit 1
fi

# Save the mnemonic argument
MNEMONIC=$1

# Function to check if an npm package is installed
is_package_installed() {
  local package=$1
  npm list "$package" > /dev/null 2>&1
}

# Check and install necessary npm packages
if ! is_package_installed bip39 || ! is_package_installed ecpair || ! is_package_installed tiny-secp256k1; then
  echo "Installing necessary npm packages..."
  npm install bip39 ecpair tiny-secp256k1
fi

# Create the Node.js script to convert mnemonic to Npub
cat << 'EOF' > mnemonic_to_npub.js
const bip39 = require('bip39');

// Get the mnemonic from command line arguments
const mnemonic = process.argv[2];

// Convert the mnemonic to entropy (hex string)
const entropyHex = bip39.mnemonicToEntropy(mnemonic);

// Convert the entropy hex string to a Buffer
let entropyBuffer = Buffer.from(entropyHex, 'hex');

// Ensure the buffer is 32 bytes long by padding if necessary
if (entropyBuffer.length < 32) {
  const padding = Buffer.alloc(32 - entropyBuffer.length, 0);
  entropyBuffer = Buffer.concat([entropyBuffer, padding]);
} else if (entropyBuffer.length > 32) {
  entropyBuffer = entropyBuffer.slice(0, 32);
}

// Convert the buffer to hex and prepend the 'npub' prefix
const npub = entropyBuffer.toString('hex');

console.log("Your Npub (public key) is:", "npub" + npub);
EOF

# Run the Node.js script
node mnemonic_to_npub.js "$MNEMONIC"

# Clean up
rm mnemonic_to_npub.js

