#!/bin/bash

# Check if Npub argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <npub>"
  exit 1
fi

# Save the Npub argument
NPUB=$1

# Function to check if an npm package is installed
is_package_installed() {
  local package=$1
  npm list "$package" > /dev/null 2>&1
}

# Check and install necessary npm packages
if ! is_package_installed bip39; then
  echo "Installing necessary npm packages..."
  npm install bip39
fi

# Create the Node.js script to convert Npub to a BIP39 mnemonic
cat << 'EOF' > npub_to_mnemonic.js
const bip39 = require('bip39');

// Get the Npub (public key) from command line arguments
const npub = process.argv[2];

// Remove the 'npub' prefix if present
const npubClean = npub.startsWith('npub') ? npub.slice(4) : npub;

// Convert the Npub hex string to a Buffer
const npubBuffer = Buffer.from(npubClean, 'hex');

// Ensure the buffer is 32 bytes long by padding if necessary
let entropyBuffer = npubBuffer;
if (entropyBuffer.length < 32) {
  const padding = Buffer.alloc(32 - entropyBuffer.length, 0);
  entropyBuffer = Buffer.concat([entropyBuffer, padding]);
} else if (entropyBuffer.length > 32) {
  entropyBuffer = entropyBuffer.slice(0, 32);
}

// Convert the entropy buffer to hex format
const entropyHex = entropyBuffer.toString('hex');

// Convert the entropy (hex string) to a mnemonic
const mnemonic = bip39.entropyToMnemonic(entropyHex);

console.log("Your BIP39 mnemonic is:", mnemonic);
EOF

# Run the Node.js script
node npub_to_mnemonic.js "$NPUB"

# Clean up
rm npub_to_mnemonic.js

