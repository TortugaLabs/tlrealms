#!/bin/sh

### START-INCLUDE-SECTION ###
set -euf -o pipefail
export INC_PATH=""
die() {
  local rc="$1" ; shift
  echo "$@" 1>&2
  exit $rc
}
has() {
  local i word="$1" ; shift
  for i in "$@"
  do
    [ x"$i" = x"$word" ] && return 0
  done
  return 1
}
required_file_list=""
require() {
  local inc dir
  for inc in "$@"
  do
    if [ "${inc:0:1}" != "/" ] ; then
      for dir in $INC_PATH
      do
	if [ -x "$dir/$inc" ] ; then
	  inc="$dir/$inc"
	  break
	fi
      done
    fi
    if [ ! -x "$inc" ] ; then
      echo "$inc: not found" 1>&2
      continue
    fi
    inc="$(readlink -f "$inc")"
    has "$inc" $required_file_list && continue
    
    if [ -z "$required_file_list" ] ; then
      required_file_list="$inc"
    else
      required_file_list="$required_file_list $inc"
    fi
    . "$inc"
  done
}
ckexport() {
  local i mkdir=false
  while [ $# -gt 0 ]
  do
    case "$1" in
    -c) mkdir=true ;;
    *) break
    esac
    shift
  done
  eval "local v=\"\${$1:-}\""
  if [ -z "$v" ] ; then
    eval "export $1=\"\$2\""
    v="$2"
  fi
  for i in $v
  do
    if [ ! -d "$i" ] ; then
      if $mkdir ; then
	mkdir -p "$i"
      else
	die 120 "$1: Missing $i"
      fi
    fi
  done
  return 0
}

ckexport TLR_ETC /etc
ckexport TLR_HOME "$TLR_ETC/tlr"	# sync'ed data
ckexport TLR_LOCAL "$TLR_ETC/tlr-local"	# local only data

ckexport -c TLR_LOGS "/var/log/tlr"

ckexport TLR_SCRIPTS "$TLR_HOME/scripts"
ckexport TLR_DATA "$TLR_HOME/data"
ckexport TLR_POLICIES "$TLR_HOME/policies"
ckexport TLR_LIB "$TLR_HOME/lib"

export INC_PATH="$TLR_LIB"

#
# Stuff that we always have
#
require common.sh

### END-INCLUDE-SECTION ###


