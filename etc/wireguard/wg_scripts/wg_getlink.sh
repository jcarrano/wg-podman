#!/bin/sh
# Generate a link for the Online Client Config Generator
# Usage
# wg_getlink <wgconf> [<client_name>]
# This works with configurations created by wg_server_init.
# Todo: deduplicate code wrt newuser

wgconf="$1"
clientname="$2"

if [ ! -f "$wgconf" ] ; then
	echo "wg_getlink <wgconf> [<client_name>]"
    exit 1
fi

set -e

. $(dirname $0)/newuser_parameters

#from https://stackoverflow.com/a/10660730
u() {
  local string="${1}"
  local strlen=${#string}
  local pos

  for pos in $(seq 0 $(($strlen-1))) ; do
     local c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) printf '%c' "${c}" ;;
        * )               printf '%%%02x' "'$c"
     esac
  done
}

if [ -n "$clientname" ] ; then
    QUERY_CN="&cn=$(u ${clientname})"
else
    QUERY_CN=""
fi

if [ -n "$ADMIN_EMAIL" ] ; then
    QUERY_AE="&ae=$(u ${ADMIN_EMAIL})"
else
    QUERY_AE=""
fi

QUERY="sa=$(u ${SERVERFQDN})&sp=${SERVERPORT}&sk=$(u ${SERVERPUB})&ca=${CLIENTADDR}&aa=${ALLOWEDSUBNET}&ap=${ALLOWEDPREFIX}${QUERY_CN}${QUERY_AE}"

echo -n 'https://gateway.pinata.cloud/ipfs/QmdGs4rfkTS3D4614sjUysx9XxJkp57v5sm59w259eX7ov?'
echo "$QUERY"

echo -n 'https://ipfs.io/ipfs/QmdGs4rfkTS3D4614sjUysx9XxJkp57v5sm59w259eX7ov?'
echo "$QUERY"

echo -n 'https://jcarrano.github.io/wg-keygen-notrust/?'
echo "$QUERY"
