#!/bin/sh
#
#
# Given a "target" will make sure that it is newer of all the
# dependancies
#
depcheck() {
  local target="$1" ; shift
  [ ! -f "$target" ] && return 0
  find "$@" -type f | (
    while read f
    do
      if [ $(date -r "$target" '+%s') -lt $(date -r "$f" +'%s') ] ; then
	echo $target $(date -r "$target" '+%s'):  $(date -r "$f" +'%s') $f
	exit 0
      fi
    done
    exit 1
  )
  return $?
}
