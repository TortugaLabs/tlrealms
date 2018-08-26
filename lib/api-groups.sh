#!/bin/sh
require api-serial.sh

groups_namechk() {
  local in="$(echo "$1" | tr A-Z a-z)"
  local out="$(echo "$in" | tr -dc 'a-z0-9_-')"
  echo "$out"
  [ "$out" = "$in" ] && return 0
  return 1
}

groups_del() {
  local grname supdate=false
  for grname in "$@"
  do
    local grfiles=$(find $TLR_DATA/groups.d -name "$grname"'.*' -maxdepth 1 -mindepth 1)
    [ -z "$grfiles" ] && continue
    rm -rf "$grfiles" && supdate=true || :
    
    # Check if this groups is referred to elsewhere...
    find "$TLR_DATA/groups.d" -maxdepth 1 -mindepth 1 -type f -name '*.cfg' | while read sgrp
    do
      [ "$(basename "$sgrp" .cfg)" = "$grname" ] && continue
      grep -q "@$grname" $sgrp || continue
      (
	. "$sgrp"
	newmem=""
	q=""
	
	for i in $mem
	do
	  [ "@$grname" = "$i" ] && continue
	  newmem="$newmem$q$i"
	  q=" "
	done
	if [ x"$mem" != x"$newmem" ] ; then
	  cat > "$sgrp" <<-EOF
		gid=$gid
		mem="$newmem"
		EOF
	fi
      )
    done
  done
  $supdate && serial_update
}

groups_add() {
  local gid="#" force=false
  
  while [ $# -gt 0 ]
  do
    case "$1" in
    --gid=*)
      gid=${1#--gid=}
      ;;
    *)
      break
    esac
    shift
  done
  [ $# -eq 0 ] && return 1
  local grname=$(groups_namechk "$1") || return 2 ; shift
  local mem="$*"
  [ -f "$TLR_DATA/groups.d/$grname.cfg" ] && return 3
  if [ $gid = "#" ] ; then
    gid=${GID_MIN:-5000}
    local g
    for g in $(find $TLR_DATA/groups.d -mindepth 1 -maxdepth 1 -type f -name '*.cfg')
    do
      g=$(. $g ; echo $gid)
      [ $g -gt $gid ] && gid=$g
    done
    gid=$(expr $gid + 1)
  fi
  cat >"$TLR_DATA/groups.d/$grname.cfg" <<-EOF
	gid=$gid
	mem="$mem"
	EOF
  local rc=$?
  serial_update
  return $rc
}

groups_members() {
  if [ $# -eq 1 ] ; then
    [ ! -f "$TLR_DATA/groups.d/$1.cfg" ] && return 1
    local gid=$(. $TLR_DATA/groups.d/"$1".cfg ; echo $gid)
    eval local cached=\${_GROUPS_C_${gid}:-}
    if [ -n "$cached" ] ; then 
      echo ${cached:1}
      return 0
    fi
    local mem= q= i
    eval "_GROUPS_C_${gid}='-'" # This prevents circular references
    for i in $(. $TLR_DATA/groups.d/"$1".cfg ; echo $mem)
    do
      [ x"${i:0:1}" = x"@" ] && i=$(groups_members "${i:1}")
      mem="$mem$q$i"
      q=" "
    done
    eval "_GROUPS_C_${gid}=\"+\$mem\"" # Cache result...
    echo $mem
    return 0
  elif [ $# -eq 2 ] ; then
    if [ x"$1" = x"-n" ] ; then
      # Disabled recursion...
      [ ! -f "$TLR_DATA/groups.d/$2.cfg" ] && return 1
      (. $TLR_DATA/groups.d/"$2".cfg ; echo $mem)
      return $?
    fi
  fi
  local grname="$1"  ; shift
  [ ! -f "$TLR_DATA/groups.d/$grname.cfg" ] && return 1
  local \
	gid=$(. $TLR_DATA/groups.d/"$grname".cfg ; echo $gid) \
	mem=$(. $TLR_DATA/groups.d/"$grname".cfg ; echo $mem) \
	newmem="$*"

  [ x"$mem" = x"$newmem" ] && return 0
  
  cat > $TLR_DATA/groups.d/"$grname".cfg <<-EOF
	gid=$gid
	mem="$newmem"
	EOF
  rc=$?
  serial_update
  return $rc
}

groups_gid() {
  local grname="$1" ; shift
  [ ! -f "$TLR_DATA/groups.d/$grname.cfg" ] && return 1
  if [ $# -eq 0 ] ; then
    (. $TLR_DATA/groups.d/"$grname".cfg ; echo $gid)
    return $?
  fi
  [ $# -ne 1 ] && return 100
  local \
	gid=$(. $TLR_DATA/groups.d/"$grname".cfg ; echo $gid) \
	mem=$(. $TLR_DATA/groups.d/"$grname".cfg ; echo $mem) \
	newgid="$1"
  [ x"$gid" = x"$newgid" ] && return 0
  
  cat > $TLR_DATA/groups.d/"$grname".cfg <<-EOF
	gid=$newgid
	mem="$mem"
	EOF
  rc=$?
  serial_update
  return $rc
}

groups_adduser() {
  [ $# -lt 2 ] && return 1
  local grname="$1" ; shift
  [ ! -f "$TLR_DATA/groups.d/$grname.cfg" ] && return 1
  (
    . "$TLR_DATA/groups.d/$grname.cfg"
    newmem="$(echo $mem "$*" | tr " " "\n" | sort -u | tr "\n" " ")"
    [ x"$newmem" = x"$mem" ] && return 0
    cat > $TLR_DATA/groups.d/"$grname".cfg <<-EOF
	gid=$gid
	mem="$newmem"
	EOF
    rc=$?
    serial_update
    return $rc
  )
  return $?
}

groups_deluser() {
  [ $# -lt 2 ] && return 1
  local grname="$1" ; shift
  [ ! -f "$TLR_DATA/groups.d/$grname.cfg" ] && return 1
  (
    . "$TLR_DATA/groups.d/$grname.cfg"
    newmem=""
    q=""
    for i in $mem
    do
      if ! has $i "$@" ; then
	newmem="$newmem$q$i"
	q=" "
      fi
    done
    [ x"$newmem" = x"$mem" ] && return 0
    mem="$(echo $mem "$*" | tr " " "\n" | sort -u | tr "\n" " ")"
    cat > $TLR_DATA/groups.d/"$grname".cfg <<-EOF
	gid=$gid
	mem="$newmem"
	EOF
    rc=$?
    serial_update
    return $rc
  )
  return $?
  
}

groups_list() {
  find "$TLR_DATA/groups.d" -name '*.cfg' -maxdepth 1 -mindepth 1 -type f \
	| sed -e "s!^$TLR_DATA/groups.d/!!" -e 's/\.cfg$//'
}

groups_exists() {
  if [ -f "$TLR_DATA/groups.d/$1.cfg" ] ; then
    return 0
  else
    return 1
  fi
}
