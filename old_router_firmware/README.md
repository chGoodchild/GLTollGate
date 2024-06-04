# GL-AR300M Captive Portal with Custom Redirect

This project sets up a captive portal on a GL-AR300M router using the built-in OpenWrt firmware and redirects users to a custom webpage hosted on the router.

## Features
- Captive portal to authenticate users
- Custom redirect to a local webpage hosted on the router


Custom splashscreen:
https://nodogsplash.readthedocs.io/en/docs/customize.html

https://docs.gl-inet.com/router/en/3/tutorials/captive_portal/#2-change-the-default-page


### Editing SSH Config File

1. **Open or create the SSH configuration file in your home directory**:
    ```sh
    nano ~/.ssh/config
    ```

2. **Add the following lines to specify the use of `ssh-rsa` for your router**:
    ```sh
    Host 192.168.8.1
        HostkeyAlgorithms +ssh-rsa
        PubkeyAcceptedAlgorithms +ssh-rsa
    ```

3. **Save and close the file**.


# opkg install uhttpd
opkg install lighttpd lighttpd-mod-cgi