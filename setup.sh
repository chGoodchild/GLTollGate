#!/bin/bash

# Define the router's IP address and password
ROUTER_IP="192.168.8.1"
ROUTER_USER="root"
ROUTER_PASSWORD="1"  # replace with your actual password

sshpass -p "$ROUTER_PASSWORD" scp nodogsplash_5.0.0-1_mips_24kc.ipk $ROUTER_USER@$ROUTER_IP:/tmp/

sshpass -p "$ROUTER_PASSWORD" ssh -tt $ROUTER_USER@$ROUTER_IP << 'ENDSSH'
opkg remove nodogsplash
opkg install /tmp/nodogsplash_5.0.0-1_mips_24kc.ipk
service nodogsplash start
service nodogsplash status
logread | grep nodogsplash
opkg update
opkg install coreutils-base64
opkg install libpthread
opkg install libmicrohttpd
opkg install jq
opkg install nlbwmon
ENDSSH

# Copy the nodogsplash package to the router and install it
sshpass -p "$ROUTER_PASSWORD" scp -r etc/config/nodogsplash $ROUTER_USER@$ROUTER_IP:/etc/config/.
sshpass -p "$ROUTER_PASSWORD" scp -r www/cgi-bin/*.sh $ROUTER_USER@$ROUTER_IP:/www/cgi-bin/.
sshpass -p "$ROUTER_PASSWORD" scp -r etc/nodogsplash/ $ROUTER_USER@$ROUTER_IP:/etc/.

