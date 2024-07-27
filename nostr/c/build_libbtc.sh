#!/bin/bash

# Path to the update marker file
UPDATE_MARKER="/var/lib/apt/periodic/update-success-stamp"

# Check if the marker file exists and get today's date and the date of last update
if [ -f "$UPDATE_MARKER" ]; then
    LAST_UPDATE=$(date -r "$UPDATE_MARKER" +%Y%m%d)
    TODAY=$(date +%Y%m%d)

    # Compare the last update date to today's date
    if [ "$LAST_UPDATE" != "$TODAY" ]; then
        echo "Running 'sudo apt-get update' because it hasn't been run today..."
        sudo apt-get update
        sudo apt-get upgrade
    else
        echo "'sudo apt-get update' has already been run today."
    fi
else
    echo "Update marker file does not exist. Running 'sudo apt-get update'..."
    sudo apt-get update
    sudo apt-get upgrade
fi

sudo apt-get install -y libevent-dev

cd ~/
git clone https://github.com/libbtc/libbtc.git
cd libbtc
./autogen.sh
./configure
make
sudo make install

# Check for btc headers
if ! ls /usr/local/include/btc > /dev/null 2>&1; then
    echo "Error: BTC headers are missing."
    exit 1
fi

# Check for btc libraries
if ! ls /usr/local/lib/libbtc* > /dev/null 2>&1; then
    echo "Error: BTC libraries are missing."
    exit 1
fi

if ! grep -qxF "/usr/local/lib" /etc/ld.so.conf.d/local.conf; then
    echo "/usr/local/lib" | sudo tee -a /etc/ld.so.conf.d/local.conf
    sudo ldconfig
else
    echo "The path /usr/local/lib is already included."
fi

echo "libbtc headers and libraries are correctly installed."
