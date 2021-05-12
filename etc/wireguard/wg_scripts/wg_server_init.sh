#!/bin/sh
# Initial server config
# Usage
# wg_server_init <wgconf> <server_ip>
# Note: Address is ignored by the wg tool, only useful with
# wg-quick.

wgconf="$1"
server_ip="$2"

if [ -z "$wgconf" -o -z "$server_ip" ] ; then
	echo "Usage wg_server_init <wgconf>"
	exit 1
fi

PRIVKEY=$(wg genkey)

umask 007

cat > $wgconf <<SERVERCF
[Interface]
Address = $server_ip/32
ListenPort = 51820
PrivateKey = $PRIVKEY
SERVERCF
