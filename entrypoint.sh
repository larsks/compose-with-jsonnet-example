#!/bin/sh

set -ex

: "${KEEPALIVED_STATE:=BACKUP}"

mkdir -p /etc/keepalived
sed 's/@STATE@/'"$KEEPALIVED_STATE"'/g' </config/keepalived.conf >/etc/keepalived/keepalived.conf

exec "$@"
