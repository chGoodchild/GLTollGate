#!/bin/bash

# Define the router's IP address and password
ROUTER_IP="192.168.8.1"
ROUTER_USER="root"
ROUTER_PASSWORD="1"  # replace with your actual password

# Marker directory
MARKER_DIR="/tmp/markers"

# Ensure marker directory exists
sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "mkdir -p $MARKER_DIR"

# Step 0: Prepare cgi-scripts because nodogsplash depends on them
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/cgi_scripts_copied ]"; then
    sshpass -p "$ROUTER_PASSWORD" scp -r www/cgi-bin/*.sh $ROUTER_USER@$ROUTER_IP:/www/cgi-bin/.
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "chmod +x /www/cgi-bin/*.sh"
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "touch $MARKER_DIR/cgi_scripts_copied"
fi

# Step 1: Install nodogsplash package
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/nodogsplash_installed ]"; then
    sshpass -p "$ROUTER_PASSWORD" scp nodogsplash_5.0.0-1_mips_24kc.ipk $ROUTER_USER@$ROUTER_IP:/tmp/
    sshpass -p "$ROUTER_PASSWORD" scp wrtbwmon_0.36_all.ipk $ROUTER_USER@$ROUTER_IP:/tmp/
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP << 'ENDSSH'
opkg remove nodogsplash
opkg install /tmp/nodogsplash_5.0.0-1_mips_24kc.ipk
service nodogsplash start
service nodogsplash status
logread | grep nodogsplash
touch /tmp/markers/nodogsplash_installed
ENDSSH
fi

# Step 2: Install additional packages including iptables-legacy and wrtbwmon
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/additional_packages_installed ]"; then
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP << 'ENDSSH'
opkg update
opkg install coreutils-base64
opkg install libpthread
opkg install libmicrohttpd
opkg install jq
opkg install iptables-legacy
ln -sf /usr/sbin/iptables-legacy /usr/sbin/iptables
ln -sf /usr/sbin/ip6tables-legacy /usr/sbin/ip6tables
ln -sf /usr/sbin/arptables-legacy /usr/sbin/arptables
ln -sf /usr/sbin/ebtables-legacy /usr/sbin/ebtables
opkg install /tmp/wrtbwmon_0.36_all.ipk
touch /tmp/markers/additional_packages_installed
ENDSSH
fi

# Step 3: Copy nodogsplash config
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/nodogsplash_config_copied ]"; then
    sshpass -p "$ROUTER_PASSWORD" scp -r etc/config/nodogsplash $ROUTER_USER@$ROUTER_IP:/etc/config/.
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "touch $MARKER_DIR/nodogsplash_config_copied"
fi

# Step 5: Copy nodogsplash directory
if ! sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "[ -f $MARKER_DIR/nodogsplash_dir_copied ]"; then
    sshpass -p "$ROUTER_PASSWORD" scp -r etc/nodogsplash/ $ROUTER_USER@$ROUTER_IP:/etc/.
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "touch $MARKER_DIR/nodogsplash_dir_copied"
    sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP "service nodogsplash restart"
fi

# Step 6: Setup and update wrtbwmon database
sshpass -p "$ROUTER_PASSWORD" ssh $ROUTER_USER@$ROUTER_IP << 'ENDSSH'
wrtbwmon setup /tmp/usage.db
wrtbwmon update /tmp/usage.db
ENDSSH

echo "Setup completed."

