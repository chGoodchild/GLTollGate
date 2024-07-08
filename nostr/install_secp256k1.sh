#!/bin/bash

# Update package list and install required dependencies
sudo apt-get update
sudo apt-get install -y autoconf automake libtool git

# Clone the secp256k1 repository into /tmp
cd /tmp
git clone https://github.com/bitcoin-core/secp256k1.git
cd secp256k1

# Run the autogen script
./autogen.sh

# Configure the build with Schnorr signatures and ECDH enabled
./configure --enable-module-schnorrsig --enable-module-ecdh

# Build the library
make

# Optionally run the test suite
make check

# Optionally install the library
sudo make install

echo "secp256k1 library has been built and installed."
