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


# Acknowledgements

Special thanks to the nym who came up with this idea, to npub1elta7cneng3w8p9y4dw633qzdjr4kyvaparuyuttyrx6e8xp7xnq32cume for helping me and everyone who controls npub1u3w2g4s9gpefczy3gf8tah4ghum5tav56hcn62jpft6jw76ax3fqj9wxcv for encouraging me to work on the right things.

