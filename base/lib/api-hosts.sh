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
  ## checks if a hostname exists
  ## # USAGE
  ##   hosts_exists <id>
  ## # OPTIONS
  ## * id - host to verify
  ## # DESC
  ## Tests if a host exists
  ## # RETURNS
  ## 0 if found, 1 if not found
  plst_exists "$1" "$hosts_db" $hosts_exts
  return $?
}

hosts_del() {
  ## Deletes hosts
  ## # USAGE
  ##   hosts_del <host>
  ## # OPTIONS
  ## * host - host name to delete (can be specified multiple times)
  ##
  local n
  for n in "$@"
  do
    plst_del "$n" "$hosts_db" $hosts_exts
  done
}

hosts_list() {
  ## List all property lists in a folder
  ## # USAGE
  ##   hosts_list <dir> [exts]
  ## # OPTIONS
  ## * dir - folder containing property lists
  ## * exts - list of property list extensions
  ## # DESC
  ## Look in the property list directory <dir> for files with
  ## matching the given extensions.  Returns the relevant names
  ## without extensions.
  ##
  plst_list "$hosts_db" $hosts_exts
}

hosts_set() {
  ## Writes values to hosts data
  ## # USAGE
  ##   hosts_set [--pub|--cfg] <id> [key val] or [key ''] or [key]
  ## # OPTIONS
  ## * --pub - modify public keys
  ## * --cfg - modify cfg values (default)
  ## * id - host to modify
  ## * key - key to modify
  ## * val - value to write to key, if '' or missing, the key is removed
  ##
  local ext='.cfg'
  while [ $# -gt 0 ]
  do
    case "$1" in
    --pub|-p) ext=".pub" ;;
    --cfg|-c) ext=".cfg" ;;
    *) break
    esac
    shift
  done

  local host="$1" ; shift

  plst_set "$host" "$hosts_db" "$ext" "$@"
}
hosts_get() {
  ## Reads values from hosts data
  ## # USAGE
  ##   hosts_get [-v] [--pub|--cfg] <id> [key]
  ## # OPTIONS
  ## * -v - return the key also
  ## * --pub - modify public keys
  ## * --cfg - modify cfg values (default)
  ## * id - host name
  ## * key - key to return
  ## * val - value to write to key, if '' or missing, the key is removed
  ## # DESC
  ## Reads host values for the given keys.  If no key specified it lists
  ## the keys that are defined.  If `-v` is used when no keys are
  ## specified, it returns key values.
  local optv='' ext='.cfg'
  while [ $# -gt 0 ]
  do
    case "$1" in
    -v) optv="$1" ;;
    --pub|-p) ext=".pub" ;;
    --cfg|-c) ext=".cfg" ;;
    *) break
    esac
    shift
  done

  local host="$1" ; shift

  plst_get $optv "$host" "$hosts_db" "$ext" "$@"
}

hosts_new() {
  ## Creates new host records
  ## # USAGE
  ##   hosts_new <name> [output]
  ## # OPTIONS
  ## * name - hostname to create
  ## * output - where to save host data (- default, is stdout)
  ## # RETURNS
  ## 0 on success, 1 on failure
  ## # OUTPUT
  ## If output is (-) the default, then a tarball containing private
  ## and public keys for the new file is generated.
  local n="$1" output="-" o
  [ $# -gt 1 ] && local output="$2"

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
  tar -C "$workdir" -zcf "$output" . 1>&3
  rm -rf "$workdir"
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

