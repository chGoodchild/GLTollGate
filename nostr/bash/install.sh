#!/bin/bash

#!/bin/bash

# Define the URL for the websocat binary
WEBSOCAT_URL="https://github.com/vi/websocat/releases/download/v1.13.0/websocat.x86_64-unknown-linux-musl"
WEBSOCAT_BIN="websocat"
INSTALL_DIR="/usr/local/bin/"
EXPECTED_WEBSOCAT_VERSION="v1.13.0"

# Check if websocat is already installed and matches the expected version
if [ -x "$INSTALL_DIR$WEBSOCAT_BIN" ]; then
    INSTALLED_VERSION=$($INSTALL_DIR$WEBSOCAT_BIN --version 2>&1)
    if [[ "$INSTALLED_VERSION" == *"$EXPECTED_WEBSOCAT_VERSION"* ]]; then
        echo "Websocat $EXPECTED_WEBSOCAT_VERSION is already installed."
        exit 0
    fi
fi

echo "Installing Websocat $EXPECTED_WEBSOCAT_VERSION."

# Download the websocat binary
wget -q $WEBSOCAT_URL -O $WEBSOCAT_BIN

# Make it executable
chmod +x $WEBSOCAT_BIN

# Move it to the install directory
sudo mkdir -p $INSTALL_DIR
sudo mv $WEBSOCAT_BIN $INSTALL_DIR

echo "Websocat installed successfully."

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
