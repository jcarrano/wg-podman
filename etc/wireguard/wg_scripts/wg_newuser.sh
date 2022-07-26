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

SERVERFQDN="$(sed -nE 's|^#?fqdn[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$|\1|p' "$wgconf" | head -n 1)"

if [ -z "$SERVERFQDN" ] ; then
	echo "Cannot parse server's FQDN base from config file"
	exit 2
fi

ADDRPREFIX="$(sed -nE 's|^#?Address[[:space:]]*=[[:space:]]*([0-9.]+).[0-9]+/[0-9]+$|\1|p' "$wgconf" | head -n 1)"

if [ -z "$ADDRPREFIX" ] ; then
	echo "Cannot parse address base from config file"
	exit 2
fi

EXISTING_PEERS=$(grep -F '[Peer]' $wgconf | wc -l)
PEERBASE=10
PEERN=$(($EXISTING_PEERS + $PEERBASE))

PRIVKEY=$(wg genkey)
PUBKEY=$(wg pubkey <<PK
$PRIVKEY
PK
)

SERVERPRIV="$(sed -n 's/[[:space:]]*PrivateKey[[:space:]]*=[[:space:]]*\(.\+\)/\1/p' "$wgconf")"
SERVERPUB=$(wg pubkey <<PK
$SERVERPRIV
PK
)

SERVERPORT="$(sed -n 's/[[:space:]]*ListenPort[[:space:]]*=[[:space:]]*\(.\+\)/\1/p' "$wgconf")"

PSKEY=$(wg genpsk)

CLIENTADDR=$ADDRPREFIX.$PEERN

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
AllowedIPs = $ADDRPREFIX.0/24

# Send periodic keepalives to ensure connection stays up behind NAT.
PersistentKeepalive = 25
CLIENTCONF
