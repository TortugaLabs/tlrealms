#!/bin/sh
require api-serial.sh

hosts_namechk() {
  #~ local in="$(echo "$1" | cut -d'.' -f1 | cut -d'-' -f1 | tr A-Z a-z)"
  local in="$(echo "$1" | cut -d'.' -f1 | tr A-Z a-z)"
  local out="$(echo "$in" | tr -dc a-z0-9-)"
  echo "$out"
  [ "$out" = "$in" ] && return 0
  return 1
}

hosts_exists() {
  local n="$1"
  [ -f "$TLR_DATA/hosts.d/$n.pub" ] && return 0
  return 1
}
hosts_add() {
  local n="$1"
  tee "$TLR_DATA/hosts.d/$n.pub"
  serial_update
}

hosts_rm() {
  local n
  for n in "$@"
  do
    rm -f \
	"$TLR_DATA/hosts.d/$n.pub" \
	"$TLR_DATA/hosts.d/$n.cfg"
  done
  serial_update
}

hosts_list() {
  find "$TLR_DATA/hosts.d" -maxdepth 1 -mindepth 1 -name '*.pub' -type f \
    | while read x
      do
	basename "$x" .pub
      done
}

gen_known_hosts() {
  [ $# -eq 0 ] && set - /etc/ssh/ssh_known_hosts
  find "$TLR_DATA/hosts.d" -maxdepth 1 -mindepth 1 -name '*.pub' -type f -print |(
    while read host
    do
      sed -e "s/^/$(basename "$host" .pub) /" "$host"
    done
  ) > "$1"

}
