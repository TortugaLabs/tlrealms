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
#*####################################################################
include -1 api-plist.sh
users_exts=".cfg .pwd .map .pub .admpub"
users_db="$TLR_DATA/users.d"

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

users_add() {
  local gid="#" uid="#"

  while [ $# -gt 0 ]
  do
    case "$1" in
    --gid=*)
      gid=${1#--gid=}
      ;;
    --uid=*)
      uid=${1#--uid=}
      ;;
    *)
      break
    esac
    shift
  done
  [ $# -eq 0 ] && return 1
  local name=$(users_namechk "$1") || return 2 ; shift

  users_exists "$name" && return 3 || :

  [ $uid = "#" ] && uid=$(users_pickuid)
  [ $gid = "#" ] && gid=$uid


  mkdir -p "$users_db"
  plst_set "$name" "$users_db" .cfg \
	uid "$uid"  gid "$gid" gecos "$name" pw_dir "/home/$name" pw_shell "/bin/sh"
  users_passwd "$name" "$(users_pwgen)"
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
    for g in $(groups_usergroups --no-resolve "$n")
    do
      groups_deluser "$g" "$n"
    done
    plst_del "$n" "$users_db" $users_exts
  done
  return 0
}

users_pwgen() {
  ## Generate a random password
  local i
  (for i in $(seq 1 15)
  do
    echo -ne $(printf '\\x%02x' $(expr $RANDOM % 256))
  done) | base64
}

users_pickuid() {
  ## Automatically allocate a UID
  local uid=${UID_MIN:-500} u i
  for i in $(plst_list "$users_db" $users_ext)
  do
    u=($plst_get "$i" "$users_db" .cfg uid)
    [ -z "$u" ] && continue
    [ $u -gt $uid ] && uid=$u
  done
  expr $uid + 1
}

#################################################





t_users_cfg() {
  :
}
t_users_pwd() {
  :
}
t_users_map() {
  :
}
t_users_get() {
  :
}
t_users_set() {
  :
}

t_find_user_files() {
  local name="$1"
  # make sure we don't get false positives from user names with "." in them...
  find $TLR_DATA/users.d -maxdepth 1 -mindepth 1 -name "$name"'.*' \
	| grep '/'"$name"'\.[a-z0-9]*$'
}





t_users_user() {
  [ $# -eq 0 ] && return 1
  local user="$1" ; shift
  [ ! -f "$TLR_DATA/users.d/$user.cfg" ] && return 10
  if [ $# -eq 0 ] ; then
    cat "$TLR_DATA/users.d/$user.cfg"
    return 0
  fi

  (
    local \
      uid="#" gid="#" gecos="$user" pw_dir="/home/$user" pw_shell="/bin/bash" \
      sp_min="" sp_max="" sp_warn="" sp_inact=""
    . "$TLR_DATA/users.d/$user.cfg"

    while [ $# -gt 0 ]
    do
      if [ -n "$1" ] ; then
	case "$1" in
	--uid=*)		uid=${1#--uid=} ;;
	--gid=*)		gid=${1#--gid=} ;;
	--gecos=*)	gecos=${1#--gecos=} ;;
	--home=*)		pw_dir=${1#--home=} ;;
	--shell=*)	pw_shell=${1#--shell=} ;;
	--spmin=*)	sp_min=${1#--spmin=} ;;
	--spmax=*)	sp_max=${1#--spmax=} ;;
	--spwarn=*)	sp_warn=${1#--spwarn=} ;;
	--spinact=*)	sp_inact=${1#--spinact=} ;;
	esac
      fi
      shift
    done

    # Create user data...
    exec >"$TLR_DATA/users.d/$user.cfg"
    cat <<-EOF
	uid=$(shell_escape "$uid")
	gid=$(shell_escape "$gid")
	gecos=$(shell_escape "$gecos")
	pw_dir=$(shell_escape "$pw_dir")
	pw_shell=$(shell_escape "$pw_shell")
	EOF
    for k in sp_min sp_max sp_warn sp_inact
    do
      eval 'v="$'$k'"'
      [ -n "$v" ] && echo "${k}=$(shell_escape "$v")" || :
    done
  ) || return $?
  return 0
}

t_users_pwck() {
  [ $# -ne 2 ] && return 4

  local user="$1" pwd_in="$2"
  [ ! -f "$TLR_DATA/users.d/$user.cfg" ] && return 10

  [ -z "${domain:-}" ] && return 45

  local \
	of_digest="$(awk -vFS=: '$1 == "htdigest" { print }' < "$TLR_DATA/users.d/$user.pwd")" \
	cc_digest="htdigest:$($mkpasswd --htdigest "$user" "$domain" "$pwd_in")"

  [ x"$of_digest" = x"$cc_digest" ] && return 0
  return 1
}

mt_users_passwd() {
  [ $# -gt 2 ] && return 1
  local user="$1"
  [ ! -f "$TLR_DATA/users.d/$user.cfg" ] && return 10

  if [ $# -eq 1 ] ; then
    cat "$TLR_DATA/users.d/$user.pwd"
    return 0
  fi
  local pwd_in="$2"

  (
    exec 20> "$TLR_DATA/users.d/$user.pwd"
    for n in unix htpasswd htdigest
    do
      arg="--$n"
      [ $n = "unix" ] && arg="--sha512"
      if [ $n = "htdigest" ] ; then
	[ -n "${domain:-}" ] && echo "$n:$($TLR_LIB/mkpasswd $arg "$user" "$domain" "$pwd_in")" 1>&20
      else
	echo "$n:$($TLR_LIB/mkpasswd $arg "$pwd_in")" 1>&20
      fi
    done
    exec 20>&-
  )
  chmod 600 "$TLR_DATA/users.d/$user.pwd"
}

t_users_list() {
  find "$TLR_DATA/users.d" -maxdepth 1 -mindepth 1 -name '*.cfg' -type f \
	| sed -e "s!^$TLR_DATA/users.d/!!" -e 's/\.cfg$//'
}


