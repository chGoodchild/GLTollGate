#!/bin/sh

# Define Git tag for downloading specific versions
GIT_TAG="0.0.2"

# Ensure the download directory exists
mkdir -p /tmp/download
cd /tmp/download

# Function to check file presence and validate checksum, then download if necessary
check_and_download() {
    local url=$1
    local destination=$2
    local expected_checksum=$3

    # Check if the file exists
    if [ -f "$destination" ]; then
        echo "File $destination exists. Checking checksum..."
        # Calculate the checksum
        local actual_checksum=$(sha256sum "$destination" | awk '{print $1}')

        # Compare checksums
        if [ "$actual_checksum" = "$expected_checksum" ]; then
            echo "Checksum for $destination is correct."
            return 0
        else
            echo "Checksum mismatch for $destination. Expected $expected_checksum, got $actual_checksum."
            echo "Redownloading file..."
        fi
    else
        echo "File $destination does not exist. Downloading..."
    fi

    # Download the file
    curl -L -o "$destination" "$url"
    if [ $? -eq 0 ]; then
        echo "Downloaded file to $destination successfully."
    else
        echo "Failed to download file from $url"
        return 1
    fi
}

echo "Downloading required files..."
check_and_download "https://github.com/chGoodchild/GLTollGate/archive/refs/tags/v$GIT_TAG.zip" "/tmp/download/GLTollGate.zip" "a42191ec74e4bbcba6cd6e49d3f472176781d31606c4adea1fe46b77f5ce879a"
check_and_download "https://github.com/chGoodchild/GLTollGate/releases/download/v$GIT_TAG/nodogsplash_5.0.0-1_mips_24kc.ipk" "/tmp/download/nodogsplash_5.0.0-1_mips_24kc.ipk" "76834cbd51cb1b989f6a7b33b21fa610d9b5fd310d918aa8bea3a5b2a9358b5a"

# Unpack the zip file
echo "Unpacking GLTollGate.zip..."
unzip -o GLTollGate.zip

# Move to the unpacked directory (adjust the directory name if needed)
cd GLTollGate-$GIT_TAG

is_package_installed() {
    local package_name="$1"
    if opkg list-installed | grep -q "^$package_name "; then
        echo "$package_name is already installed."
        return 0
    else
        echo "$package_name is not installed."
        return 1
    fi

}

install_packages_if_needed() {
    local package_name
    local update_needed=0
    local update_performed=0

    # First check which packages need to be installed
    for package_name in "$@"; do
        if ! is_package_installed "$package_name"; then
            update_needed=1
            break
        fi
    done

    # If any package needs installation, update the package list first
    if [ "$update_needed" -eq 1 ]; then
        echo "Updating package list..."
        opkg update
        update_performed=1
    fi

    # Now install the packages that are not installed
    for package_name in "$@"; do
        if ! is_package_installed "$package_name"; then
            echo "Installing $package_name..."
            opkg install "$package_name"
            if [ $? -eq 0 ]; then
                echo "$package_name installed successfully."
            else
                echo "Failed to install $package_name."
            fi
        fi
    done

    # If no packages needed installation and thus no update was performed
    if [ "$update_performed" -eq 0 ] && [ "$update_needed" -eq 0 ]; then
        echo "All packages are already installed. No update needed."
    fi
}


# Install dependencies
echo "Installing dependencies..."
install_packages_if_needed jq curl coreutils-base64

# Check if nodogsplash service is running
nodogsplash_status=$(service nodogsplash status 2>&1)

# Check for the presence of a known string that indicates the service is not found or inactive
if echo "$nodogsplash_status" | grep -q "not found"; then
    echo "Service 'nodogsplash' not installed or not running. Installing and starting the service..."
    # Attempt to remove any existing installation first (if any)
    opkg remove nodogsplash
    # Install the package
    opkg install /tmp/download/nodogsplash_5.0.0-1_mips_24kc.ipk

    cp /tmp/download/GLTollGate-$GIT_TAG/www/cgi-bin/*.sh /www/cgi-bin/.
    cp -r /tmp/download/GLTollGate-$GIT_TAG/etc/nodogsplash/htdocs/* /etc/nodogsplash/htdocs/.
    # cp -r /tmp/download/GLTollGate-$GIT_TAG/nostr/ /nostr/
    cp -r /tmp/download/GLTollGate-$GIT_TAG/etc/config/* /etc/config/
    cp /tmp/download/GLTollGate-$GIT_TAG/etc/config/nodogsplash /etc/config/nodogsplash
    cp /tmp/download/GLTollGate-$GIT_TAG/etc/firewall.nodogsplash /etc/firewall.nodogsplash
    chmod +x /etc/firewall.nodogsplash
    /etc/./firewall.nodogsplash
    
    # Attempt to start the service
    if service nodogsplash start; then
        echo "Service 'nodogsplash' started successfully."
        # Optionally, you can check the status again to confirm it's running
        service nodogsplash status
    else
        echo "Failed to start service 'nodogsplash'."
        return 1  # Return with error
    fi
else
    echo "Service 'nodogsplash' is running."
fi

# Define the command to add to crontab
CRON_JOB="* * * * * /etc/init.d/check_time_and_disconnect start"

# Path to your script
SCRIPT_PATH="/www/cgi-bin/check_time_and_disconnect.sh"
LINK_NAME="/etc/init.d/check_time_and_disconnect"

# Ensure the script is linked and executable
if [ ! -L $LINK_NAME ]; then
    ln -s $SCRIPT_PATH $LINK_NAME
    chmod +x $SCRIPT_PATH
    cp /tmp/download/GLTollGate-$GIT_TAG/etc/rc.local /etc/rc.local
    echo "Link created for $SCRIPT_PATH"
fi

# Enable the script to run on startup
$LINK_NAME enable
echo "Script enabled to run on startup."

# Check if the cron job is already in the crontab
if ! crontab -l | grep -Fq "$CRON_JOB"; then
    # Add the cron job if it does not exist
    (crontab -l; echo "$CRON_JOB") | crontab -
    # Restart the cron service
    /etc/init.d/cron restart
    echo "Cron job added and cron restarted."
else
    echo "Cron job already exists. No changes made."
fi

# Log any output related to nodogsplash from the system logs
logread | grep nodogsplash

echo "Setup completed."

