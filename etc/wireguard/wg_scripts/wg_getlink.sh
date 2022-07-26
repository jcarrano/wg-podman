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

SERVERPORT="$(sed -n 's/[[:space:]]*ListenPort[[:space:]]*=[[:space:]]*\(.\+\)/\1/p' "$wgconf")"

#from https://stackoverflow.com/a/10660730
u() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER)
}

if [ -n "$clientname" ] ; then
    QUERY_CN="&cn=$(u ${clientname})"
else
    QUERY_CN=""
fi

QUERY="sa=$(u ${SERVERFQDN})&sp=${SERVERPORT}&sk=$(u ${SERVERPUB})&ca=${CLIENTADDR}&aa=${ALLOWEDSUBNET}&ap=${ALLOWEDPREFIX}${QUERY_CN}"

echo -n https://gateway.pinata.cloud/ipfs/QmdU8zZ1HPrS7JZQ5AqCbGnCE2zLqtiGLpxPYL99XTipZk?
echo "$QUERY"
