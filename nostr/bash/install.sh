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

