#!/bin/sh
[ -z "${TLR_BASE:-}" ] && export TLR_BASE=$(cd $(dirname "$0")/..;pwd)
. $TLR_BASE/crt.sh
echo PONG
exit 0
