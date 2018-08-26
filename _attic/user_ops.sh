#!/bin/sh
#
# TLRealms User Commands
#
set -euf -o pipefail

### START-INCLUDE-SECTION ###
verb_adduser() {
  [ $# -eq 0 ] && exec cat <<-EOF
	Usage: adduser [OPTIONS] USER [GROUP]

	Create new user, or add USER to GROUP

	      -h DIR	Home directory
	      -G GECOS	GECOS field
	      -s SHELL	Login shell
	      -u UID	User id
	      -g GID	Group id
	EOF
  local opt_h="" opt_G="" opt_s="" opt_g="" opt_u=""
  while [ $# -gt 0 ]
  do
    case "$1" in
    -h) opt_h="--home=$(shell_escape "$2")" ; shift ;;
    -G) opt_G="--gecos=$(shell_escape "$2")" ; shift ;;
    -s) opt_s="--shell=$(shell_escape "$2")" ; shift ;;
    -u) opt_u="--uid=$(shell_escape "$2")" ; shift ;;
    -g) opt_g="--gid=$(shell_escape "$2")" ; shift ;;
    *) break ;;
    esac
    shift
  done
  if [ $# -eq 1 ] ; then
    # Creating user
    local user="$1"
    eval new_user "$TLR_HOME" "$opt_h $opt_G $opt_s $opt_u $opt_g" "$user"
  elif [ $# -eq 2 ] ; then
    # Adding user to group
    local user="$1" group="$2"
    if ([ -n "$opt_h" ] || [ -n "$opt_G" ] || [ -n "$opt_s" ] || [ -n "$opt_g" ] || [ -n "$opt_u" ] ) ; then
      die 3 "Invalid options for adding user to group"
    fi
    die 4 "Un-implemented!" #############################!###
  else
    die 3 "Wrong usage"
  fi
}
verb_addgroup() {
  [ $# -eq 0 ] && exec cat <<-EOF
	Usage: addgroup [-g GID] [USER] GROUP

	Add a group or add a user to a group

	      -g GID	Group id
	EOF
  die 4 "Un-implemented!" #############################!###
}
verb_deluser() {
  [ $# -eq 0 ] && exec cat <<-EOF
	Usage: deluser USER

	Delete USER from the system
	EOF
  die 4 "Un-implemented!" #############################!###
}
verb_delgroup() {
  [ $# -eq 0 ] && exec cat <<-EOF
	Usage: delgroup [USER] GROUP

	Delete group GROUP from the system or user USER from group GROUP
	EOF
  die 4 "Un-implemented!" #############################!###
}
verb_passwd() {
  [ $# -eq 0 ] && exec cat <<-EOF
	Usage: passwd [OPTIONS] USER [password]

	Change USER's password

	      -l	Lock (disable) account
	      -u	Unlock (enable) account
	EOF
  die 4 "Un-implemented!" #############################!###
}


### END-INCLUDE-SECTION ###

