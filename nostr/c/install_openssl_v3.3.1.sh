#!/bin/bash

# Define the OpenSSL version
OPENSSL_VERSION="openssl-3.3.1"

# Define directories
DOWNLOAD_DIR="$HOME"
INSTALLATION_DIR="/usr/local/ssl"
LIB_DIR="$INSTALLATION_DIR/lib64"  # Define the library directory

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
sudo apt autoremove openssl libssl-dev -y

# Check if the tarball exists before unpacking
if [ -f "$OPENSSL_TAR" ]; then
    echo "Unpacking OpenSSL..."
    tar -xzvf $OPENSSL_TAR
    if [ $? -ne 0 ]; then
        echo "Failed to unpack OpenSSL. Exiting."
        exit 1
    fi
else
    echo "OpenSSL tarball does not exist. Exiting."
    exit 1
fi

# Change into the directory
cd $OPENSSL_VERSION || exit

# Configure, compile and install OpenSSL
echo "Configuring, compiling, and installing OpenSSL..."
./config --prefix=$INSTALLATION_DIR --openssldir=$INSTALLATION_DIR shared zlib
if [ $? -ne 0 ]; then
    echo "Configuration failed. Exiting."
    exit 1
fi

make
if [ $? -ne 0 ]; then
    echo "Make failed. Exiting."
    exit 1
fi

# Verify current OpenSSL version
CURRENT_VERSION=$(openssl version 2> /dev/null | grep "$OPENSSL_VERSION" || true)
if [ -z "$CURRENT_VERSION" ]; then
    echo "Installing OpenSSL $OPENSSL_VERSION..."
    # Installation commands here...
    sudo make install
    if [ $? -ne 0 ]; then
        echo "Make install failed. Exiting."
        exit 1
    fi
    # Verify installation after install
    echo "Verifying OpenSSL installation..."
    openssl version
else
    echo "OpenSSL $OPENSSL_VERSION is already installed."
fi

# Check and add the new library path to the ld.so configuration
CONF_FILE="/etc/ld.so.conf.d/openssl-3.3.1.conf"
if [ ! -f "$CONF_FILE" ] || ! grep -q "$LIB_DIR" "$CONF_FILE"; then
    echo "Adding OpenSSL library path to the linker configuration..."
    echo "$LIB_DIR" | sudo tee "$CONF_FILE"
    # Update the dynamic linker cache
    echo "Updating the dynamic linker cache..."
    sudo ldconfig
else
    echo "Linker configuration already set."
fi

# Update the PATH to include the new OpenSSL binary location
if ! grep -q "$INSTALLATION_DIR/bin" "$HOME/.bashrc"; then
    echo "Updating PATH in .bashrc..."
    echo "export PATH=$INSTALLATION_DIR/bin:\$PATH" >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
else
    echo "PATH already updated in .bashrc."
fi

# Verify installation
echo "OpenSSL version installed:"
openssl version

# Update the symbolic link to point to the new OpenSSL binary
echo "Updating symbolic link for OpenSSL..."
sudo ln -sf /usr/local/ssl/bin/openssl /usr/bin/openssl
if [ $? -eq 0 ]; then
    echo "Symbolic link updated successfully."
else
    echo "Failed to update symbolic link. Please check permissions and file paths."
    exit 1
fi

# Verify installation
echo "Verifying OpenSSL version installed:"
openssl version
if [[ $(openssl version) =~ "$OPENSSL_VERSION" ]]; then
    echo "OpenSSL $OPENSSL_VERSION installation completed and verified."
else
    echo "Error: OpenSSL version does not match $OPENSSL_VERSION."
    exit 1
fi

echo "OpenSSL $OPENSSL_VERSION installation completed."

