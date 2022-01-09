#!/bin/sh
require api-serial.sh
require api-groups.sh
require shescape.sh

users_namechk() {
  local in="$(echo "$1" | tr A-Z a-z)"
  local out="$(echo "$in" | tr -dc 'a-z0-9._-')"
  echo "$out"
  [ "$out" = "$in" ] && return 0
  return 1
}

find_user_files() {
  local name="$1"
  # make sure we don't get false positives from user names with "." in them...
  find $TLR_DATA/users.d -maxdepth 1 -mindepth 1 -name "$name"'.*' \
	| grep '/'"$name"'\.[a-z0-9]*$'
}

users_del() {
  local name supdate=false i
  for name in "$@"
  do
    #set -x
    local pwfiles=$(find_user_files "$name")
    [ -z "$pwfiles" ] && continue
    rm -rf $pwfiles && supdate=true || :
    
    # Check if this user is referred to elsewhere...
    for i in $(groups_list)
    do
      has $name $(groups_members -n $i) && groups_deluser $i $name
    done
  done
  $supdate && serial_update
  return 0
}

users_pwgen() {
  local i
  (for i in $(seq 1 15)
  do
    echo -ne $(printf '\\x%02x' $(expr $RANDOM % 256))
  done) | base64
}

users_pickuid() {
  local uid=${UID_MIN:-500} u i
  for i in $(find $TLR_DATA/users.d -mindepth 1 -maxdepth 1 -type f -name '*.cfg')
  do
    u=$(. $i ; echo $uid)
    [ $u -gt $uid ] && uid=$u
  done
  expr $uid + 1
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

  [ -f "$TLR_DATA/users.d/$name.cfg" ] && return 3 || :

  [ $uid = "#" ] && uid=$(users_pickuid)
  [ $gid = "#" ] && gid=$uid

  (
    cat >"$TLR_DATA/users.d/$name.cfg" <<-EOF
	uid=$uid
	gid=$gid
	gecos="$name"
	pw_dir="/home/$name"
	pw_shell="/bin/sh"
	EOF
    users_passwd "$name" "$(users_pwgen)"
    serial_update
  ) && return 0
  local i
  for i in .cfg .admpub .pwd .pub
  do
    rm -f "$TLR_DATA/users.d/$name$i"
  done
  return 15
}

users_user() {
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
  serial_update
  return 0
}

users_pwck() {
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

users_passwd() {
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
	[ -n "${domain:-}" ] && echo "$n:$($TLR_SCRIPTS/mkpasswd $arg "$user" "$domain" "$pwd_in")" 1>&20
      else
	echo "$n:$($TLR_SCRIPTS/mkpasswd $arg "$pwd_in")" 1>&20
      fi
    done
    exec 20>&-
  )
  chmod 600 "$TLR_DATA/users.d/$user.pwd"
  serial_update
}

users_list() {
  find "$TLR_DATA/users.d" -maxdepth 1 -mindepth 1 -name '*.cfg' -type f \
	| sed -e "s!^$TLR_DATA/users.d/!!" -e 's/\.cfg$//'
}

users_exists() {
  local i
  for i in .cfg .pwd
  do
    [ ! -f "$TLR_DATA/users.d/$1$i" ] && return 1
  done
  return 0
}



