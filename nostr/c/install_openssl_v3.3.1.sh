#!/bin/bash

# Define the OpenSSL version
OPENSSL_VERSION="openssl-3.3.1"

# Define directories
DOWNLOAD_DIR="$HOME"
INSTALLATION_DIR="/usr/local/ssl"

# Define file paths
OPENSSL_TAR="$DOWNLOAD_DIR/$OPENSSL_VERSION.tar.gz"
OPENSSL_SHA="$DOWNLOAD_DIR/$OPENSSL_VERSION.tar.gz.sha256"

# Download OpenSSL tarball and checksum file if they don't exist or if checksum doesn't match
if [ ! -f "$OPENSSL_TAR" ] || ! echo "$(cat $OPENSSL_SHA)  $OPENSSL_TAR" | sha256sum -c --status; then
    echo "Downloading OpenSSL $OPENSSL_VERSION..."
    wget -O "$OPENSSL_TAR" "https://github.com/openssl/openssl/releases/download/$OPENSSL_VERSION/$OPENSSL_VERSION.tar.gz"
    wget -O "$OPENSSL_SHA" "https://github.com/openssl/openssl/releases/download/$OPENSSL_VERSION/$OPENSSL_VERSION.tar.gz.sha256"

    # Verify the checksum
    echo "Verifying the checksum..."
    if ! echo "$(cat $OPENSSL_SHA)  $OPENSSL_TAR" | sha256sum -c --status; then
        echo "Checksum verification failed."
        exit 1
    fi
else
    echo "OpenSSL $OPENSSL_VERSION already downloaded and verified."
fi


# Remove existing OpenSSL installation
echo "Removing existing OpenSSL installation..."
sudo apt remove openssl libssl-dev -y

# Unpack the tarball
echo "Unpacking OpenSSL..."
tar -xzvf $OPENSSL_VERSION.tar.gz
cd $OPENSSL_VERSION

# Configure, compile and install OpenSSL
echo "Configuring, compiling, and installing OpenSSL..."
./config --prefix=$INSTALLATION_DIR --openssldir=$INSTALLATION_DIR shared zlib
make
sudo make install

# Update the dynamic linker run-time bindings
sudo ldconfig

# Update the PATH to include the new OpenSSL binary location
echo "export PATH=$INSTALLATION_DIR/bin:\$PATH" >> $HOME/.bashrc
source $HOME/.bashrc

# Verify installation
echo "OpenSSL version installed:"
openssl version

echo "OpenSSL $OPENSSL_VERSION installation completed."

