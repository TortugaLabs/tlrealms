#!/bin/sh
[ -z "${TLR_BASE:-}" ] && export TLR_BASE=$(cd $(dirname "$0")/..;pwd)
. $TLR_BASE/crt.sh
include -1 api-sync

sync_rpc_check "$@" || quit 5 "Invalid rsync call"
sync_rpc_run
