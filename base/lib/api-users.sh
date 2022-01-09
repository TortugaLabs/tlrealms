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
## Functions to manage users data
##
## Configurable variables
##
## - users_exts
## - users_db
## - users_pwlen
## - users_unixpw
## - TLR_DATA
## - TLR_LIB
## - DOMAIN
## - SP_MIN
## - SP_MAX
## - SP_WARN
## - SP_INACT
## - UID_MIN
#*####################################################################
include -1 api-plist.sh
users_exts=".cfg .pwd .map .pub .admpub"
users_db="$TLR_DATA/users.d"
users_pwlen=16
users_unixpw="--sha512"

users_namechk() {
  ## Make sure valid user names
  ## # USAGE
  ##   users_namechk <name>
  ## # OPTIONS
  ## * name - name candidate to check
  ## # RETURNS
  ## 0 if name is valid, 1 if it is invalid
  ## # OUTPUT
  ## Outputs a sanitized version of the name
  local in="$(echo "$1" | tr A-Z a-z)"
  local out="$(echo "$in" | tr -dc 'a-z0-9._-')"
  echo "$out"
  [ "$out" = "$in" ] && return 0
  return 1
}

users_exists() {
  ## checks if a user exists
  ## # USAGE
  ##   users_exists <id>
  ## # OPTIONS
  ## * id - user to verify
  ## # DESC
  ## Tests if user exists
  ## # RETURNS
  ## 0 if found, 1 if not found
  plst_exists "$1" "$users_db" $users_exts
  return $?
}

users_list() {
  ## list registered users
  ## # USAGE
  ##   users_list
  plst_list "$users_db" $users_exts
  return 0
}


users_add() {
  ## Add a new user
  ## # USAGE
  ##   users_add [options] <id>
  ## # OPTIONS
  ## * id - user id to create
  ## * --gid=nn - assign the given gid, otherwise is auto assigned
  ## * --uid=nn - assign the given uid, otherwise is auto assigned
  ## * --gecos=nn - gecos fields, defaults to id
  ## * --home=nn - home directory
  ## * --shell=nn - shell, defaults to /bin/sh
  ## * --spmin=nn - minimum password lifetime
  ## * --spmax=nn - max password lifetime
  ## * --spwarn=nn - warning time
  ## * --spinact=nn - password inactivity time
  ## * --
  ## # DESC
  ## Create the given user.  If uid is not specified
  ## it is auto assigned.
  ##
  ## If gid is not specified defaults to uid.
  ## # RETURNS
  ## 0 if found, 1 if not found
  local gid="" uid="" gecos="" homedir="" shell="" \
	sp_min="" sp_max="" sp_warn="" sp_inact=""

  while [ $# -gt 0 ]
  do
    case "$1" in
    --gid=*)
      gid=${1#--gid=}
      ;;
    --uid=*)
      uid=${1#--uid=}
      ;;
    --gecos=*)
      gecos=${1#--gecos=}
      ;;
    --home=*)
      homedir=${1#--home=}
      ;;
    --shell=*)
      shell=${1#--shell=}
      ;;
    --spmin=*) sp_min=${1#--spmin=} ;;
    --spmax=*) sp_max=${1#--spmax=} ;;
    --spwarn=*) sp_warn=${1#--spwarn=} ;;
    --spinact=*) sp_inact=${1#--spinact=} ;;
    *)
      break
    esac
    shift
  done
  [ $# -eq 0 ] && return 1
  local name=$(users_namechk "$1") || return 2 ; shift

  if [ -d "$users_db" ] ; then
    users_exists "$name" && return 3 || :
  else
    mkdir -p "$users_db"
  fi

  [ -z "$uid" ] && uid=$(users_pickuid)
  [ -z "$gid" ] && gid=$uid
  [ -z "$gecos" ] && gecos="$name"
  [ -z "$homedir" ] && homedir="/home/$name"
  [ -z "$shell" ] && shell="/bin/sh"

  mkdir -p "$users_db"
  plst_set "$name" "$users_db" .cfg \
	uid "$uid"  \
	gid "$gid" \
	gecos "$gecos" \
	pw_dir "$homedir" \
	pw_shell "$shell"
  [ -n "$sp_min" ] && plst_set "$name" "$users_db" .cfg sp_min "$sp_min"
  [ -n "$sp_max" ] && plst_set "$name" "$users_db" .cfg sp_max "$sp_max"
  [ -n "$sp_warn" ] && plst_set "$name" "$users_db" .cfg sp_warn "$sp_warn"
  [ -n "$sp_inact" ] && plst_set "$name" "$users_db" .cfg sp_inact "$sp_inact"

  users_passwd --set "$name" "$(users_pwgen)"
  set +x
}

users_del() {
  ## Deletes users
  ## # USAGE
  ##   users_del <name>
  ## # OPTIONS
  ## * name - user name to delete (can be specified multiple times)
  ##
  local n g
  for n in "$@"
  do
    plst_del "$n" "$users_db" $users_exts
  done
  return 0
}

users_pwgen() {
  ## Generate a random password
  ## # USAGE
  ##   users_pwgen [length]
  ## # OPTIONS
  ## * length - optional password length
  [ $# -eq 0 ] && set - $users_pwlen
  local i
  (for i in $(seq 1 "$1")
  do
    echo -ne $(printf '\\x%02x' $(expr $RANDOM % 256))
  done) | base64 | cut -c-"$1"
}

users_pickuid() {
  ## Automatically allocate a UID
  local uid=${UID_MIN:-500} u i
  for i in $(plst_list "$users_db" $users_exts)
  do
    u=$(plst_get "$i" "$users_db" .cfg uid)
    [ -z "$u" ] && continue
    [ $u -gt $uid ] && uid=$u
  done
  expr $uid + 1
}

users_plst() {
  ## Manipulate plst values
  ## # USAGE
  ##   users_plst [plist] [-v] <id> [<key> [val|'' [key val]]]
  ## # OPTIONS
  ## * plist - to use, one of $users_exts
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

  local user="$1" ; shift

  if [ $# -lt 2 ] ; then
    # read
    plst_get $optv "$user" "$users_db" "$ext" "$@"
    return $?
  fi
  # write
  plst_set "$user" "$users_db" "$ext" "$@"
}

users_cfg() {
  ## set/get cfg values
  ## # USAGE
  ##   users_cfg [-v] <id> [<key> [val|'' [key val]]]
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
  local user="$1" ; shift

  if [ $# -gt 1 ] ; then
    # writing
    users_plst ".cfg" $optv "$user" "$@"
    return $?
  fi
  if [ -z "$optv" ] && [ $# -eq 1 ] ; then
    # Keys that require special treatment
    case "$1" in
      sp_min)
	local val="$(users_plst ".cfg" $optv "$user" "$1")"
	[ -z "$val" ] && val=${SP_MIN:-0}
	echo "$val"
	return 0
	;;
      sp_max)
	local val="$(users_plst ".cfg" $optv "$user" "$1")"
	[ -z "$val" ] && val=${SP_MAX:-9999}
	echo "$val"
	return 0
	;;
      sp_warn)
	local val="$(users_plst ".cfg" $optv "$user" "$1")"
	[ -z "$val" ] && val=${SP_WARN:-7}
	echo "$val"
	return 0
	;;
      sp_inact)
	local val="$(users_plst ".cfg" $optv "$user" "$1")"
	[ -z "$val" ] && val=${SP_INACT:-}
	echo "$val"
	return 0
	;;
    esac
  fi

  users_plst ".cfg" $optv "$user" "$@"

}


users_passwd() {
  ## set/get passwd values
  ## # USAGE
  ##   users_passwd [-v][-w|--set] <user> [arg1]
  ## # OPTIONS
  ## * -v - return key names on lookups
  ## * -w|--set - set password
  ## * user - user to lookup or modify
  ## * arg1 - optional argument
  ## # DESC
  ## Default is to read, in that case
  ## if no arg1 is specified, it would list keys or key values (if -v)
  ## is specified
  ##
  ## If -w is set, arg1 is the new password.  If not specified,
  ## passwords are deleted.
  ##
  ## Note that htdigest password are not generated unless "DOMAIN"
  ## is defined.
  local optv='' write=false
  while [ $# -gt 0 ]
  do
    case "$1" in
      -v) optv="$1" ;;
      -w|--set) write=: ;;
      *) break
    esac
    shift
  done
  [ $# -eq 0 ] && return 1
  [ $# -gt 2 ] && return 2

  local user="$1" ; shift

  if $write ; then
    # Update
    users_exists "$user" || return 10
    if [ $# -eq 0 ] ; then
      # Delete the password
      rm -f "$users_db/$user.pwd"
      return 0
    fi
    local pwd_in="$1"

    > "$users_db/$user.pwd"
    chmod 600 "$users_db/$user.pwd"

    users_plst ".pwd" "$user" \
	unix "$($TLR_LIB/mkpasswd $users_unixpw "$pwd_in")" \
	htpasswd "$($TLR_LIB/mkpasswd --htpasswd "$pwd_in")"
    [ -n "${DOMAIN:-}" ] && users_plst ".pwd" "$user" \
	htdigest "$($TLR_LIB/mkpasswd --htdigest "$user" "$DOMAIN" "$pwd_in")"
    users_plst ".cfg" "$user" \
	sp_lstchg $(expr $(date +%s) / 86400)
  else
    # Read...
    users_plst ".pwd" $optv "$user" "$@"
    return $?
  fi
}


users_map() {
  ## set/get map values
  ## # USAGE
  ##   users_map [-v] <id> [<key> [val|'' [key val]]]
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
  local user="$1" ; shift

  if [ $# -lt 2 ] ; then
    # Reading...
    users_plst ".map" $optv "$user" "$@"
    return $?
  fi

  users_plst ".map" $optv "$user" "$@" || return $?
  [ -f "$users_db/$user.map" ] && chmod 600 "$users_db/$user.map"
  return $?
}

users_pwck() {
  ## Check for password correctness
  ## # USAGE
  ##   users_pwck <user> <pwd-in>
  ## # OPTIONS
  ## * user : user to check
  ## * pwd : clear-text password
  ## # RETURNS
  ## 0 if correct, 1 otherwise
  [ $# -ne 2 ] && return 4

  local user="$1" pwd_in="$2"

  users_exists "$user" || return 10
  local cpwd="$(users_passwd "$user" unix)"
  local ipwd="$($TLR_LIB/mkpasswd --salt="$cpwd" "$pwd_in")"

  [ x"$cpwd" = x"$ipwd" ] && return 0
  return 1
}

users_ckshell() {
  ## Validate if the given shell can be used
  ## # USAGE
  ##  users_ckshell <shell>
  ## # OPTIONS
  ## * shell - shell to check
  ## # RETURNS
  ## 0 if OK, 1 if not allowed
  awk -vSHELL="$1" '
        BEGIN { rc=1 }
        $1 == SHELL { rc=0 }
        END { exit(rc); }
        ' ${TLR_ETC:-/etc}/shells
}

#~ users_findfiles() {
  #~ ## list files in $users_db for the given user.
  #~ ## # USAGE
  #~ ##   users_findfiles <name>
  #~ ## #
  #~ ## # DESC
  #~ ## Show on stdout all the files currently in $users_db
  #~ find "$users_db" -maxdepth 1 -mindepth 1 -type f -name "$name"'.*' \
	#~ | grep '/'"$name"'\.[a-z]+$'
#~ }







