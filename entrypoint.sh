#!/bin/sh

set -ex

: "${KEEPALIVED_STATE:=BACKUP}"
: "${KEEPALIVED_INTERFACE:=eth0}"

mkdir -p /etc/keepalived
sed \
	-e 's/@STATE@/'"$KEEPALIVED_STATE"'/g' \
	-e 's/@VIP@/'"$KEEPALIVED_VIP"'/g' \
	-e 's/@INTERFACE@/'"$KEEPALIVED_INTERFACE"'/g' \
	</config/keepalived.conf >/etc/keepalived/keepalived.conf

exec "$@"
