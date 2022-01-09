#!/bin/sh
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#*#####################################################################
## Functions to manage hosts data
##
## Configurable variables
##
## - hosts_exts
## - hosts_key_types
## - hosts_db
## - TLR_DATA
## - TLR_LIB
## - DOMAIN
#*####################################################################
include -1 api-plist.sh
hosts_key_types="dsa ecdsa ed25519 rsa"
hosts_exts=".pub .cfg"
hosts_db="$TLR_DATA/hosts.d"

hosts_namechk() {
  ## Make sure valid host names
  ## # USAGE
  ##   hosts_namechk <name>
  ## # OPTIONS
  ## * name - name candidate to check
  ## # RETURNS
  ## 0 if name is valid, 1 if it is invalid
  ## # OUTPUT
  ## Outputs a sanitized version of the name
  #~ local in="$(echo "$1" | cut -d'.' -f1 | cut -d'-' -f1 | tr A-Z a-z)"
  local in="$(echo "$1" | cut -d'.' -f1 | tr A-Z a-z)"
  local out="$(echo "$in" | tr -dc a-z0-9-)"
  echo "$out"
  [ "$out" = "$in" ] && return 0
  return 1
}

hosts_exists() {
  ## checks if a host exists
  ## # USAGE
  ##   hosts_exists <hostname>
  ## # OPTIONS
  ## * hostname - host to verify
  ## # DESC
  ## Tests if host exists
  ## # RETURNS
  ## 0 if found, 1 if not found
  plst_exists "$1" "$hosts_db" $hosts_exts
  return $?
}

hosts_list() {
  ## list registered hosts
  ## # USAGE
  ##   hosts_list
  plst_list "$hosts_db" $hosts_exts
  return 0
}


hosts_del() {
  ## Deletes hosts
  ## # USAGE
  ##   hosts_del <name>
  ## # OPTIONS
  ## * name - host name to delete (can be specified multiple times)
  ##
  local n g
  for n in "$@"
  do
    plst_del "$n" "$hosts_db" $hosts_exts
  done
  return 0
}

hosts_plst() {
  ## Manipulate plst values
  ## # USAGE
  ##   hosts_plst [plist] [-v] <id> [<key> [val|'' [key val]]]
  ## # OPTIONS
  ## * plist - to use, one of $hosts_exts
  ## * -v - return key names on lookups
  ## * id - user to lookup or modify
  ## * key - key to lookup or modify
  ## * val - value to write, if '', the key is removed
  ## # DESC
  ## If a single key is specified it is returned.
  ##
  ## To modify values, specify one or more key value pairs
  local optv='' ext="$1" ; shift
  while [ $# -gt 0 ]
  do
    case "$1" in
      -v) optv="$1" ;;
      *) break
    esac
    shift
  done
  [ $# -eq 0 ] && return 1

  local h="$1" ; shift
  if ! hosts_exists "$h" ; then
    echo "$h: does not exist" 1>&2
    return 1
  fi

  if [ $# -lt 2 ] ; then
    # read
    plst_get $optv "$h" "$hosts_db" "$ext" "$@"
    return $?
  fi
  # write
  plst_set "$h" "$hosts_db" "$ext" "$@"
}

hosts_cfg() {
  ## set/get cfg values
  ## # USAGE
  ##   hosts_cfg [-v] <id> [<key> [val|'' [key val]]]
  ## # OPTIONS
  ## * -v - return key names on lookups
  ## * id - user to lookup or modify
  ## * key - key to lookup or modify
  ## * val - value to write, if '', the key is removed
  ## # DESC
  ## If a single key is specified it is returned.
  ##
  ## To modify values, specify one or more key value pairs
  local optv=''
  while [ $# -gt 0 ]
  do
    case "$1" in
      -v) optv="$1" ;;
      *) break
    esac
    shift
  done
  [ $# -eq 0 ] && return 1
  local h="$1" ; shift

  hosts_plst ".cfg" $optv "$h" "$@"
}

hosts_pk() {
  ## set/get public keys
  ## # USAGE
  ##   hosts_pk [-v] <id> [<key> [val|'' [key val]]]
  ## # OPTIONS
  ## * -v - return key names on lookups
  ## * id - user to lookup or modify
  ## * key - key to lookup or modify
  ## * val - value to write, if '', the key is removed
  ## # DESC
  ## If a single key is specified it is returned.
  ##
  ## To modify values, specify one or more key value pairs
  local optv=''
  while [ $# -gt 0 ]
  do
    case "$1" in
      -v) optv="$1" ;;
      *) break
    esac
    shift
  done
  [ $# -eq 0 ] && return 1
  local h="$1" ; shift

  hosts_plst ".pub" $optv "$h" "$@"
}




hosts_new() {
  ## Creates new host records
  ## # USAGE
  ##   hosts_new <name> [output]
  ## # OPTIONS
  ## * name - hostname to create
  ## # RETURNS
  ## 0 on success, 1 on failure
  ## # OUTPUT
  ## A tarball containing private
  ## and public keys for the new file is generated.
  local n="$1" o

  if ! n=$(hosts_namechk "$n") ; then
    echo "invalid name specified" 1>&2
    return 1
  fi

  if hosts_exists "$n" ; then
    echo "$n: already exists!" 1>&2
    return 1
  fi

  exec 3>&1 ; exec 1>&2

  mkdir -p "$hosts_db"

  local workdir=$(mktemp -d)
  for type in $hosts_key_types
  do
    ssh-keygen -q -N '' -t $type  -C "host:${type}@$n" \
	-f "$workdir/ssh_host_${type}_key"
  done
  find "$workdir" -name "*.pub" | (
    while read f
    do
      cat "$f"
    done
  ) > "$hosts_db/$n.pub"

  local uuid=$(cat /proc/sys/kernel/random/uuid | tee "$workdir/uuid")
  hosts_plst ".cfg" "$n" uuid "$uuid"

  tar -C "$workdir" -zcf - . 1>&3
  rm -rf "$workdir"
  return 0
}

# TODO: Add test case for this
hosts_add() {
  ## Imports new hosts
  ## # USAGE
  ##   hosts_new <name> [uuid <uuid>]
  ## # OPTIONS
  ## * name - hostname to create
  ## # DESC
  ## This will create a new host and initialize its public keys from
  ## stdin.
  ## # RETURNS
  ## 0 on success, 1 on failure
  local n="$1" o ; shift
  local uuid=""

  while [ $# -gt 1 ]
  do
    case "$1" in
    uuid)
      uuid="$2"
      shift
      ;;
    *)
      break
      ;;
    esac
    shift
  done
  [ -z "$uuid" ] && uuid=$(cat /proc/sys/kernel/random/uuid)

  if ! n=$(hosts_namechk "$n") ; then
    echo "invalid name specified" 1>&2
    return 1
  fi

  if hosts_exists "$n" ; then
    echo "$n: already exists!" 1>&2
    return 1
  fi

  mkdir -p "$hosts_db"

  cat > "$hosts_db/$n.pub"
  hosts_plst ".cfg" "$n" uuid "$uuid"
  echo "$n $uuid"
  return 0
}


#~ hosts_keytype_tag() {
  #~ case "$1" in
    #~ ssh-rsa) echo "rsa" ;;
    #~ ssh-ed25519) echo "ed25519" ;;
    #~ ecdsa-sha2-nistp256) echo "ecdsa" ;;
    #~ ssh-dss) echo "$dsa" ;;
  #~ esac
#~ }
#~ ssh-keygen -q -N '' -t $type -C "host:${type}@$host" -f "$dir/ssh_host_${type}_key"
#~ $TLR_DATA/hosts.d/$n.${type}.key'
#~ ssh_host_${type}_key"
#~ ssh-keygen -q -N '' -C 'provisional admin' -f "$dir/admin_key"
#~ for type in $key_types
#~ do
#~ done

