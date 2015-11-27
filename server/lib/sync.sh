#!/bin/sh
#
# Sync data transport
#
sync_send() {
  [ -z "$1" ] && fatal "No dbdir specified"
  [ ! -d "$1" ] && fatal "dbdir($1) not found"

  (
    cd "$1"
    find * | grep -v '~$' | while read L
    do
      echo "$L"
      ls -l "$L"
      sed 's/^/:/' "$L"
      echo "EOF"
    done
  )
}

sync_recv() {
  [ -z "$1" ] && fatal "No dbdir specified"
  [ ! -d "$1" ] && fatal "dbdir($1) not found"

  local mod=1 size= fname=

  while read size fname
  do
   fname=$(echo "$fname" | tr -d /)
   [ -z "$size" -o -z "$fname" ] && break
   if [ ! -f "$1/$fname" ] ; then
      echo "$fname: does not exist" 1>&2
      fname=/dev/null
    else
      fname="$1/$fname"
      mod=0
    fi
    dd of="$fname" bs=1  count="$size"
  done

  return $mod
}
