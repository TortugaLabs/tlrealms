#!/bin/sh

gen_known_hosts() {
  [ $# -eq 0 ] && set - /etc/ssh/ssh_known_hosts
  find "$TLR_DATA/hosts.d" -maxdepth 1 -mindepth 1 -name '*.pub' -type f -print |(
    while read host
    do
      sed -e "s/^/$(basename "$host" .pub) /" "$host"
    done
  ) > "$1"

}
