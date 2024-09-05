#!/bin/sh -e

##!/bin/sh -e
#set -x

# Define Git tag for downloading specific versions
GIT_TAG="0.0.6"

# Define checksums
GLTOLLGATE_ZIP_CHECKSUM="973373e6d3ccc9d2a6827a09907af5b26804be886a3802b1f4b5fedd14db3c20"

# Ensure the download directory exists
mkdir -p /tmp/download
cd /tmp/download

# Function to check checksum
check_checksum() {
    local file=$1
    local expected_checksum=$2
    echo "Checking checksum for $file..."
    local actual_checksum=$(sha256sum "$file" | awk '{print $1}')

    if [ "$actual_checksum" = "$expected_checksum" ]; then
        echo "Checksum for $file is correct."
        return 0
    else
        echo "Checksum mismatch for $file. Expected $expected_checksum, got $actual_checksum."
        return 1
    fi
}

# Function to download and verify a file
download_and_verify() {
    local url=$1
    local destination=$2
    local expected_checksum=$3

    echo "Attempting to download file from $url..."
    curl -L -o "$destination" "$url"
    if [ $? -eq 0 ]; then
        echo "Downloaded file to $destination successfully."
        # Re-check the checksum after download
        if check_checksum "$destination" "$expected_checksum"; then
            return 0
        else
            echo "Failed to verify checksum after download."
            exit 1  # Exit the entire script if checksum verification fails
        fi
    else
        echo "Failed to download file from $url"
        exit 1  # Exit the entire script if download fails
    fi
}

# Function to check file presence and validate checksum, then download if necessary
check_and_download() {
    local url=$1
    local destination=$2
    local expected_checksum=$3

    # Check if the file exists and validate the checksum
    if [ -f "$destination" ]; then
        if check_checksum "$destination" "$expected_checksum"; then
            return 0
        else
            echo "Redownloading file due to checksum mismatch..."
            download_and_verify "$url" "$destination" "$expected_checksum"
        fi
    else
        echo "File $destination does not exist. Downloading..."
        download_and_verify "$url" "$destination" "$expected_checksum"
    fi
}

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


echo "Downloading required files..."
if ! check_and_download "https://github.com/chGoodchild/GLTollGate/archive/refs/tags/v$GIT_TAG.zip" "/tmp/download/GLTollGate.zip" "$GLTOLLGATE_ZIP_CHECKSUM"; then
    echo "Error downloading or verifying GLTollGate.zip. Exiting..."
    exit 1
fi


echo "Downloading required files..."
check_and_download "https://github.com/chGoodchild/GLTollGate/archive/refs/tags/v$GIT_TAG.zip" "/tmp/download/GLTollGate.zip" "$GLTOLLGATE_ZIP_CHECKSUM"

# Install dependencies
echo "Installing dependencies..."
install_packages_if_needed coreutils-base64

# Unpack the zip file
echo "Unpacking GLTollGate.zip..."
unzip -o GLTollGate.zip

# Move to the unpacked directory (adjust the directory name if needed)
cd GLTollGate-$GIT_TAG


# Check if nodogsplash service is running
nodogsplash_status=$(service nodogsplash status 2>&1)

service nodogsplash stop

echo "Service 'nodogsplash' not installed or not running. Installing and starting the service..."
cp /tmp/download/GLTollGate-$GIT_TAG/www/cgi-bin/*.sh /www/cgi-bin/.
cp -r /tmp/download/GLTollGate-$GIT_TAG/etc/nodogsplash/htdocs/* /etc/nodogsplash/htdocs/.
cp -r /tmp/download/GLTollGate-$GIT_TAG/nostr/ /nostr/
# cp -r /tmp/download/GLTollGate-$GIT_TAG/etc/config/* /etc/config/
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
$LINK_NAME enable > /dev/null 2>&1
echo "Script enabled to run on startup, output suppressed."

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
