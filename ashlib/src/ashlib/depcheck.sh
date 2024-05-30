#!/bin/sh
#
#
# Given a "target" will make sure that it is newer of all the
# dependancies
#
depcheck() {
  ## Check file dependancies
  ## # USAGE
  ##  depcheck <target> [depends]
  ## # OPTIONS
  ## * target : file that would be built
  ## * depends : file components used to build target
  ## # RETURNS
  ## 0 if the target needs to be re-build, 1 if target is up-to-date
  ## # DESC
  ## `depcheck` would do a dependancy check (similar to what `make`
  ## does).  It finds all the files in `depends` and make sure that
  ## all files are older than the target.
  ##
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
