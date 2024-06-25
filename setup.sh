#!/bin/bash

# Define the router's IP address and password
ROUTER_IP="192.168.8.1"
ROUTER_USER="root"
ROUTER_PASSWORD="1"  # replace with your actual password

# Marker directory
MARKER_DIR="/tmp/markers"

# Ensure marker directory exists
sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "mkdir -p $MARKER_DIR"

# Step 1: Copy the nodogsplash package and install it
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/nodogsplash_installed ]"; then
    sshpass -p "$ROUTER_PASSWORD" scp nodogsplash_5.0.0-1_mips_24kc.ipk $ROUTER_USER@$ROUTER_IP:/tmp/
    
    sshpass -p "$ROUTER_PASSWORD" ssh -tt $ROUTER_USER@$ROUTER_IP <<'ENDSSH'
opkg remove nodogsplash
opkg install /tmp/nodogsplash_5.0.0-1_mips_24kc.ipk
service nodogsplash start
service nodogsplash status
logread | grep nodogsplash
touch /tmp/markers/nodogsplash_installed
ENDSSH
fi

# Step 4: Copy CGI scripts and make them executable
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/cgi_scripts_copied ]"; then
    sshpass -p "$ROUTER_PASSWORD" scp -r www/cgi-bin/*.sh $ROUTER_USER@$ROUTER_IP:/www/cgi-bin/.
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "chmod +x /www/cgi-bin/*.sh"
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "touch $MARKER_DIR/cgi_scripts_copied"
fi

# Step 2: Install additional packages
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/additional_packages_installed ]"; then
    sshpass -p "$ROUTER_PASSWORD" ssh -tt $ROUTER_USER@$ROUTER_IP <<'ENDSSH'
opkg update
opkg install coreutils-base64
opkg install libpthread
opkg install libmicrohttpd
opkg install jq
opkg install iptables-legacy
touch /tmp/markers/additional_packages_installed
ENDSSH
fi

# opkg install curl
# opkg install libmbedtls14 libmbedx509-1 libmbedcrypto7
# curl -o /opt/wrtbwmon https://raw.githubusercontent.com/brvphoenix/wrtbwmon/master/wrtbwmon
# chmod +x /opt/wrtbwmon

# Step 3: Copy nodogsplash config
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/nodogsplash_config_copied ]"; then
    sshpass -p "$ROUTER_PASSWORD" scp -r etc/config/nodogsplash $ROUTER_USER@$ROUTER_IP:/etc/config/.
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "touch $MARKER_DIR/nodogsplash_config_copied"
fi

# Step 5: Copy nodogsplash directory
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/nodogsplash_dir_copied ]"; then
    sshpass -p "$ROUTER_PASSWORD" scp -r etc/nodogsplash/ $ROUTER_USER@$ROUTER_IP:/etc/.
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "touch $MARKER_DIR/nodogsplash_dir_copied"
fi

