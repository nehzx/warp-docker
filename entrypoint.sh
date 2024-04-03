#!/bin/bash

# exit when any command fails
set -e

# create a tun device
if [ ! -c /dev/net/tun ]; then
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

# start dbus
mkdir -p /run/dbus
if [ -f /run/dbus/pid ]; then
  rm /run/dbus/pid
fi
dbus-daemon --config-file=/usr/share/dbus-1/system.conf

# start the daemon
warp-svc &

# sleep to wait for the daemon to start, default 2 seconds
sleep "$WARP_SLEEP"

# if /var/lib/cloudflare-warp/reg.json not exists, register the warp client
if [ ! -f /var/lib/cloudflare-warp/reg.json ]; then
    warp-cli register && echo "Warp client registered!"
    # if a license key is provided, register the license
    if [ -n "$WARP_LICENSE_KEY" ]; then
        echo "License key found, registering license..."
        warp-cli set-license "$WARP_LICENSE_KEY" && echo "Warp license registered!"
    fi
    # connect to the warp server
    warp-cli connect
else
    echo "Warp client already registered, skip registration"
fi

# start the proxy
gost $GOST_ARGS
