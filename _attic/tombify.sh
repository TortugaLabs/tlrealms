#!/bin/sh
#
set -euf -o pipefail

die() {
  local rc="$1" ; shift
  echo "$@" 1>&2
  exit $rc
}

[ $# -ne 2 ] && die 5 "Usage: $0 [input-dir] [output-dir]"

inp_dir="$1"
out_dir="$2"
size=32

[ ! -d "$inp_dir" ] && die 10 "$inp_dir: not found!"
[ ! -d "$out_dir" ] && die 10 "$out_dir: not found!"

check_tomb() {
  local file="$1" dir="$2"
  [ ! -f "$file" ] && return 0
  find "$dir" -type f | (
    while read src
    do
      if [ $(date -r "$file" '+%s') -lt $(date -r "$src" +'%s') ] ; then
	# $file is not newer than $src!
	echo $(date -r "$file" '+%s') -gt $(date -r "$src" +'%s') 
	exit 0
      fi
    done
    exit 1
  )
  # Nothing to be done...
  return $?
}
    
mntd=""
vfat=""
cleanup() {
  if [ -n "$vfat" ] ; then
    [ -f "$vfat.$$" ] && rm -f "$vfat.$$"
  fi
  [ -z "$mntd" ] && return
  umount "$mntd" || :
  rmdir "$mntd"
  mntd=""
}
trap "cleanup" EXIT

find "$inp_dir" -mindepth 1 -maxdepth 1 -type d | while read dir
do
  name="$(basename "$dir" .d)"
  vfat="$out_dir/$name.vfat"
  if check_tomb "$vfat" "$dir" ; then
    echo "$vfat"
    truncate -s $(expr $size \* 1024 \* 1024) "$vfat.$$"
    mkdosfs -n "$name" "$vfat.$$"
    
    mntd=$(mktemp -d)
    mount -o loop -t vfat "$vfat.$$" "$mntd"
    
    ln=$(expr $(expr length "$dir") + 2)
    
    find "$dir" | while read fp
    do
      rp=$(expr substr "$fp" "$ln" $(expr length "$fp")) || :
      [ -z "$rp" ] && continue

      if [ -d "$fp" ] ; then
	mkdir $mntd/$rp
      elif [ -f "$fp" ] ; then
	cp $fp $mntd/$rp
      fi
    done

    rm -f "$vfat"
    mv "$vfat.$$" "$vfat"
    
    cleanup
    
  fi
done

