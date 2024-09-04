#!/bin/sh

# Function to check if a package is installed
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

# Function to install packages if needed
install_packages_if_needed() {
    for package_name in "$@"; do
        if ! is_package_installed "$package_name"; then
            echo "Installing $package_name..."
            opkg install "$package_name"
        fi
    done
}

# Install dependencies (if not already included in the custom image)
echo "Checking and installing dependencies if needed..."
install_packages_if_needed coreutils-base64 unzip

# Configure nodogsplash service
echo "Configuring nodogsplash service..."
if ! service nodogsplash status >/dev/null 2>&1; then
    echo "Starting nodogsplash service..."
    service nodogsplash start
else
    echo "Nodogsplash service is already running."
fi

# Generate nostr keys
echo "Generating nostr keys..."
chmod +x /nostr/shell/install/install_keygen.sh /nostr/shell/install_keygen.sh
/nostr/shell/install/./install_keygen.sh
/nostr/shell/./generate_keys.sh

# Setup cron job for time checking and disconnection
CRON_JOB="* * * * * /etc/init.d/check_time_and_disconnect start"
SCRIPT_PATH="/www/cgi-bin/check_time_and_disconnect.sh"
LINK_NAME="/etc/init.d/check_time_and_disconnect"

# Ensure the script is linked and executable
if [ ! -L $LINK_NAME ]; then
    ln -s $SCRIPT_PATH $LINK_NAME
    chmod +x $SCRIPT_PATH
    echo "Link created for $SCRIPT_PATH"
fi

# Enable the script to run on startup
$LINK_NAME enable > /dev/null 2>&1
echo "Script enabled to run on startup."

# Add cron job if not already present
if ! crontab -l | grep -Fq "$CRON_JOB"; then
    (crontab -l; echo "$CRON_JOB") | crontab -
    /etc/init.d/cron restart
    echo "Cron job added and cron restarted."
else
    echo "Cron job already exists. No changes made."
fi

# Apply firewall rules
echo "Applying firewall rules..."
/etc/./firewall.nodogsplash

echo "Setup completed."
