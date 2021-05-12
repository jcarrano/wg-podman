#!/bin/sh
# Add client to a wireguard conf
# Usage
# wg_newuser <wgconf> <client_conf>
# The prefix is hardcoded, sorry for that.

wgconf="$1"
client_conf="$2"

if [ ! -f "$wgconf" -o -z "$client_conf" ] ; then
	echo "Usage wg_newuser <wgconf> <client_conf>"
	exit 1
fi

set -e

SERVERFQDN=example.com
ADDRPREFIX="10.0.0"

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
