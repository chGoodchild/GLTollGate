#!/bin/sh

# Function to check if a package is installed
is_installed() {
    opkg list-installed | grep -q "^$1 "
}

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Please provide a package list as an argument."
    exit 1
fi

# Initialize variables for installed and not installed packages
INSTALLED=""
NOT_INSTALLED=""

# Check each package
for pkg in $1; do
    if is_installed "$pkg"; then
        INSTALLED="$INSTALLED $pkg"
    else
        NOT_INSTALLED="$NOT_INSTALLED $pkg"
    fi
done

# Print results
echo "Installed packages:"
echo "$INSTALLED" | tr ' ' '\n'
echo
echo "Not installed packages:"
echo "$NOT_INSTALLED" | tr ' ' '\n'
