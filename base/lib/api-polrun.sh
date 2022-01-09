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
## Functions to handle apply policies
#*####################################################################
include -1 shesc.sh
include -1 api-users.sh

is_master() {
  [ x"$(sysname)" = x"${TLR_MASTER:-}" ] && return 0
  return 1
}

# Password policy statements
minlen() {
  [ $(expr length "$password") -lt "$1" ] && quit 1 "password too short"
  return 0
}
maxlen() {
  [ $(expr length "$password") -gt "$1" ] && quit 2 "password too long"
  return 0
}
charset() {
  [ -z "$(echo "$password" | tr -dc "$1")" ] && quit 3 "Missing charset: $1"
  left="$(echo "$left" | tr -d "$1")"
}
only_valid_sets() {
  [ -n "$left" ] && quit 4 "Invalid characters found (not matching sets): $left"
  return 0
}

polrun_pwck() {
  local password="$1" left="$1"

  type password_policy >/dev/null 2>&1 || return 0 # No policy defined, so always true...
  (password_policy;exit 0)
  return $?
}

polrun_perms() {
  local hook="$1" action="$2" object="$3" ; shift 3

  if type policy_hook_${hook}_${action} >/dev/null 2>&1 ; then
    policy_hook_${hook}_${action} "$object" "$@"
    return $?
  fi
  if type policy_hook_${hook} >/dev/null 2>&1 ; then
    policy_hook_${hook} "$action" "$object" "$@"
    return $?
  fi
  if type default_perms_${hook}_${action} >/dev/null 2>&1 ; then
    default_perms_${hook}_${action} "$object" "$@"
    return $?
  fi

  return 0
}

default_perms_user_chshell() {
  # Default user change shell policy
  local cshell=$(users_cfg "$1" shell)

  users_ckshell "$cshell" || return 1
  [ $# -eq 0 ] && return 1
  users_ckshell "$2" || return 1
  return 0
}

polrun_update_serial() {
  local serial=${TLR_DATA:-/etc/tlr}/serial.txt
  [ -w "$serial" ] || return 0	# We skip this if we can't write to it!
  if [ -f "$serial" ] ; then
    local newserial="$(expr $(cat "$serial") + 1)" || :
    if [ -n "$newserial" ] ; then
      echo $newserial > $serial
      return 0
    fi
  fi
  echo $RANDOM > $serial
}

polrun_apply() {
  local poldir=${TLR_DATA:-/etc/tlr}/policy.d policies=""
  export TLR_POLDIR="$poldir"

  #~ [ $EUID -ne 0 ] && return # Only run policies if root

  case "$1" in
    users) policies="users" ;;
    groups) policies="groups" ;;
    hosts) policies="hosts" ;;
    cron) policies="cron" ;;
    all) policies="users groups hosts" ;;
    *)
      echo "Unknown policy: $1" 1>&2
      return 1
  esac

  for policy in $policies
  do
    if [ -f "$poldir/$policy.sh" ] ; then
      ( . "$poldir/$policy.sh" ) 1>&2 || return 2
    fi
  done
}
