#!/bin/sh
[ -z "${TLR_BASE:-}" ] && export TLR_BASE=$(cd $(dirname "$0")/..;pwd)
. $TLR_BASE/crt.sh
include -1 api-hosts

# Create a new host
force=false ; enroll=false
while [ $# -gt 0 ]
do
  case "$1" in
  --clobber|--force)
    force=true
    ;;
  --no-clobber|--no-force)
    force=false
    ;;
  --enroll)
    enroll=true
    ;;
  --enroll)
    enroll=false
    ;;
  *)
    break
    ;;
  esac
  shift
done
[ $# -eq 1 ] && quit 10 "Usage: $0 [--force] {new-host}"

new_host="$1" ; shift
if hosts_exists "$new_host" ; then
  if $force ; then
    hosts_del "$new_host"
  else
    quit 68 "$new_host: host already exists"
  fi
fi

ROOT='${ROOT:-}'

$enroll && cat <<-_PROLOGUE_
	mkdir -p $ROOT/etc/ssh
	tar -C $ROOT/etc/ssh -zxvf - <<-_EOF_
	_PROLOGUE_
hosts_new "$new_host" "$output" | base64
$enroll && cat <<-_EPILOGUE_

	_EOF_
	_EPILOGUE_

