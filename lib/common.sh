#!/bin/sh
#
# Common configurations
#
get_master() {
  echo $master
}

is_master() {
  if [ $# -eq 0 ] ; then
    local myname=$(uname -n)
  else
    local myname="$1"
  fi
  [ -z "${master:-}" ] && return 1
  if [ "$master" = "$myname" ] ; then
    return 0
  fi
  return 1
}

apply_policies() {
  $TLR_SCRIPTS/apply_policies "$@"
}

roles="default"
role() {
  local role
  for role in "$@"
  do
    has "$role" $roles && continue
    roles="$roles $role"
  done
}
add_role() {
  if ( echo "$*" | grep -q : ) ; then
    # Only one host specified...
    if [ "$(hostname)" = "$1" ] ; then
      shift
      role "$@"
    fi
  else
    matched=false
    while [ $# -gt 0 ]
    do
      if [ "$1" = ":" ] ; then
	shift
	break
      elif [ "$1" = "$(hostname)" ] ; then
	matched=:
      fi
      shift
    done
    [ $# -eq 0 ] && return 0
    if $matched ; then
      role "$@"
    fi
  fi
}
has_role() {
  local role
  for role in "$@"
  do
    has "$role" $roles && return 0
  done
  return 1
}
has_all_roles() {
  local role
  for role in "$@"
  do
    has "$role" $roles || return 1
  done
  return 0
}

[ -f "$TLR_HOME/settings.sh" ] && . "$TLR_HOME/settings.sh"
[ -f "$TLR_DATA/hosts.d/$(hostname).cfg" ] && . "$TLR_DATA/hosts.d/$(hostname).cfg"
[ -f "$TLR_ETC/tlr-settings.sh" ] && . "$TLR_ETC/tlr-settings.sh"

is_master && role master || :


