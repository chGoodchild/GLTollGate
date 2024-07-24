# Dependencies

```
opkg update
opkg install coreutils-base64
opkg install libpthread
opkg install libmicrohttpd
opkg install jq
opkg install nlbwmon
```

# Setup

```
scp nodogsplash_5.0.0-1_mips_24kc.ipk root@192.168.8.1:/tmp/

opkg remove nodogsplash
opkg install nodogsplash_5.0.0-1_mips_24kc.ipk
service nodogsplash start
service nodogsplash status
logread | grep nodogsplash
```

# Debugging

```
ndsctl json
ndsctl deauth 28:d2:44:64:f1:f7
service nodogsplash restart
/www/cgi-bin/./check_and_disconnect.sh
cat /var/log/nodogsplash_data_usage.json
cat /var/log/nodogsplash_data_purchases.json
```

# wrtbwmon

```
wrtbwmon setup /tmp/usage.db
wrtbwmon update /tmp/usage.db
cat /tmp/usage.db
ndsctl json
iperf3 -c $IPERF_SERVER -n $NUM_BYTES
wrtbwmon update /tmp/usage.db
cat /tmp/usage.db
ndsctl json
```

