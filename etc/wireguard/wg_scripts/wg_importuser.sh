#!/bin/sh
# Import a client fragment to a wireguard conf
# Usage
# wg_importuser <wgconf> <client_frag> [<client_name>]

wgconf="$1"
client_frag="$2"

if [ ! -f "$wgconf" -o -z "$client_frag" ] ; then
	echo "wg_importuser <wgconf> <client_frag> [<client_name>]"
	echo "The client fragment refers to a file with the following form:"
    cat <<EXAMPLE

[Peer]
# name-of-the-peer
PublicKey = .....
PresharedKey = .....
AllowedIPs = x.x.x.x/32

EXAMPLE
    echo "The peer name is optional and can be overriden in the command line"
	exit 1
fi

set -e
set -o pipefail

NAME_FROM_FILE=$(sed -nE 's/#[[:blank:]]*(.+)/\1/p' < "${client_frag}" | head -n 1 )
PEER_NAME=${3:-$NAME_FROM_FILE}
: ${PEER_NAME:?If the fragment has no peer name you must specify one}

extract_key () {
    F=$(sed -nE "s/^${1}[[:blank:]]*=[[:blank:]]*([A-Za-z0-9+/=]+)[[:blank:]]*$/${1} = \\1/p" < "${client_frag}" | head -n 1)
    : ${F:?Missing or badly formatted field $1}
    echo "$F"
}

extract_ip () {
    F=$(sed -nE "s|^AllowedIPs[[:blank:]]*=[[:blank:]]*([0-9.]+)/32[[:blank:]]*$|\\1|p" < "${client_frag}" | head -n 1)
    : ${F:?Ip address not found or not a /32 prefix}
    echo "AllowedIPs = ${F}/32"
}

# For safety reasons we must deconstruct and reconstruct the client fragment
REMADE_FRAG=$(echo; echo "[Peer]"; echo "# ${PEER_NAME}"; extract_key PublicKey; \
    extract_key PresharedKey; extract_ip)

echo "$REMADE_FRAG" >> "$wgconf"
