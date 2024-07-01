#!/bin/sh

# Function to check if an npm package is installed
is_package_installed() {
  local package=$1
  npm list "$package" > /dev/null 2>&1
}

# List of required packages
required_packages="bip39 bip32 bitcoinjs-lib ecpair tiny-secp256k1 bech32 bech32-buffer @scure/base"

# Check and install necessary npm packages
for package in $required_packages; do
  if ! is_package_installed "$package"; then
    echo "Installing necessary npm packages..."
    npm install $required_packages
    break
  fi
done

# Run the Node.js script
node generate_keys.js

