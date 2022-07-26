#!/bin/sh
# Add client to a wireguard conf
# Usage
# wg_newuser <wgconf> <client_conf>

wgconf="$1"
client_conf="$2"

if [ ! -f "$wgconf" -o -z "$client_conf" ] ; then
	echo "Usage wg_newuser <wgconf> <client_conf>"
	echo "Give a meaningful name to client_conf because it is used to"
	echo "label the peer entry on the server config."
	exit 1
fi

set -e

. $(dirname $0)/newuser_parameters

PRIVKEY=$(wg genkey)
PUBKEY=$(wg pubkey <<PK
$PRIVKEY
PK
)

PSKEY=$(wg genpsk)

umask 007

cat >> $wgconf <<PEERSECTION

[Peer]
# $(basename $client_conf)
PublicKey = $PUBKEY
PresharedKey = $PSKEY
AllowedIPs = $CLIENTADDR/32
PEERSECTION

cat > $client_conf <<CLIENTCONF
[Interface]
PrivateKey = $PRIVKEY
Address = $CLIENTADDR/32

[Peer]
Endpoint = $SERVERFQDN:$SERVERPORT
PublicKey = $SERVERPUB
PresharedKey = $PSKEY
AllowedIPs = $ALLOWEDSUBNET/$ALLOWEDPREFIX

# Send periodic keepalives to ensure connection stays up behind NAT.
PersistentKeepalive = 25
CLIENTCONF
