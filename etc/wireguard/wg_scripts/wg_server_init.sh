#!/bin/sh
# Initial server config
# Usage
# wg_server_init <wgconf> <server_ip> <server_fqdn>

set -e

wgconf="$1"
server_ip="$2"
server_fqdn="$3"

note() {
	echo "The 'Address' entry in the resulting file is commented out," >&2
	echo "because 'wg' cannot use it. If you use wg-quick, uncomment." >&2
}

if [ -z "$wgconf" -o -z "$server_ip" -o -z "$server_fqdn" ] ; then
	echo "Usage wg_server_init <wgconf> <server_ip> <server_fqdn>"
	note
	exit 1
fi

PRIVKEY=$(wg genkey)

umask 007

cat > $wgconf <<SERVERCF
[Interface]
#fqdn = $server_fqdn
#Address = $server_ip/32
ListenPort = 51820
PrivateKey = $PRIVKEY
SERVERCF
