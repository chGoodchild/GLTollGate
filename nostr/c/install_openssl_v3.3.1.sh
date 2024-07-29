#!/bin/bash

# Define the OpenSSL version
OPENSSL_VERSION="openssl-3.3.1"

# Define directories
DOWNLOAD_DIR="$HOME"
INSTALLATION_DIR="/usr/local/ssl"

# Download OpenSSL
echo "Downloading OpenSSL $OPENSSL_VERSION..."
cd $DOWNLOAD_DIR
# wget https://github.com/openssl/openssl/releases/download/$OPENSSL_VERSION/$OPENSSL_VERSION.tar.gz
# wget https://github.com/openssl/openssl/releases/download/$OPENSSL_VERSION/$OPENSSL_VERSION.tar.gz.sha256

# Prepare for checksum verification
echo "Preparing checksum..."
CHECKSUM=$(cat $OPENSSL_VERSION.tar.gz.sha256 | awk '{print $1}')  # Extract the checksum
echo "$CHECKSUM  $OPENSSL_VERSION.tar.gz" > checksum.sha256         # Create a new checksum file

# Verify the checksum
echo "Verifying the checksum..."
sha256sum -c checksum.sha256

if [ $? -eq 0 ]; then
    echo "Checksum verification successful."
else
    echo "Checksum verification failed."
    exit 1
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

