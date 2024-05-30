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

_kvpparsekvp() {
  if [ x"$1" = x"--local" ] ; then
    local prefix="local "
    shift
  else
    local prefix=""
  fi
  
  local kvp="$*" sect="" key="" val=""
  val="$(echo "$kvp" | cut -d= -f2-)"
  key="$(echo "$kvp" | cut -d= -f1)"
  if echo "$key" | grep -q '\.' ; then
    sect="$(echo "$key" | cut -d. -f1)"
    key="$(echo "$key" | cut -d. -f2)"
  fi
  echo "${prefix}sect=\"$sect\" ; ${prefix}key=\"$key\" ; ${prefix}val=\"$val\""
}

_kvpappend() {
  local var="$1" i; shift
  for i in "$@"
  do
    eval 'if [ -z "$'"${var}"'" ] ; then '"${var}"'="$i" ; continue ; fi'
    eval "${var}=\"\$${var}
\$i\""
  done
}


_kvp_find_sect() {
  if [ "$ln" = ":[$sect]" ]; then
    sect=""
    sfound="yes"
  fi
  echo "$ln"
}
_kvp_in_sect() {
  if echo "$ln" | grep -q '^:\s*\[' ; then
    if [ $found = "no" ] ; then
      found=yes
      echo ":$key=$val"
    fi
    echo "$ln"
    return 1
  fi
  echo "$ln" | grep -q '^:\s*[#;]' && return 0
  echo "$ln" | grep -q '=' || return 0
  
  local lhs="$(echo "$ln" | cut -d= -f1)"
  local rhs="$(echo "$ln" | cut -d= -f2-)"
  [ "$lhs" = ":$key" ] || return 0
  found="yes"
  echo ":$key=$val"
  return 1
}

_kvpadd() {
  local key="$1" val="$2" sect="$sect" ln found="no"
  if [ -n "$sect" ] ; then
    local sfound="no"
  else
    local sfound="yes"
  fi
  while read ln
  do
    if [ -n "$sect" ] ; then
      # Looking for "sect"
      _kvp_find_sect
      continue
    fi
    _kvp_in_sect || break
    echo "$ln"
  done
  if [ $found = "no" ] ; then
    [ $sfound = "no" ] && echo ":[$sect]"
    echo ":$key=$val"
  fi
  cat
}

kvped() {
  ## Function to modify INI files in-place.
  ## # USAGE
  ##   kvped [options] file [modifiers]
  ## # OPTIONS
  ## * --nobackup -- disable creation of backups
  ## * --backupdir=dir -- if specified, backups are saved to the central dir.
  ## * --backupext=ext -- Backups are created by adding ext.  Defaults to "~".
  ## * file -- file to modify
  ## # DESC
  ## Files are modified in-place only if the contents change.  This means
  ## time stamps are kept accordingly.
  ##
  ## *kvped* will read the given `file` and will apply the respective
  ## modifiers.  The following modifiers are recognized:
  ##
  ## * key=value :: Sets the `key` to `value` in the global (default)
  ##   section.
  ## * section.key=value :: sets the `key` in `section` to `value`.
  ## * -key :: If a key begins with `-` it will be deleted.
  ## * -section.key :: The `key` from `section` will be deleted.
  ##

  local BACKUPDIR= BACKUPEXT="~" FILTER=no

  while [ $# -gt 0 ]
  do
    case "$1" in
	--nobackup)
	    BACKUPDIR=
	    BACKUPEXT=
	    ;;
	--backupext=*)
	    BACKUPDIR=
	    BACKUPEXT=${1#--backupext=}
	    ;;
        --backupdir=*)
	    BACKUPDIR=${1#--backupdir=}
	    BACKUPEXT=
	    ;;
	-*)
	    echo "Invalid option: $1" 1>&2
	    return 1
	    ;;
	*)
	    break
	    ;;
    esac
    shift
  done

  local FILE="$1" ; shift

  local ocont=""
  [ -f "$FILE" ] && ocont="$(sed 's/^/:/' < "$FILE")"
  local ncont="$ocont"

  local kvp
  for kvp in "$@"
  do
    [ -z "$kvp" ] && continue

    if [ x"$(expr substr "$kvp" 1 1)" = x"-" ] ; then
      local key="$(expr substr "$kvp" 2 1024)" sect=""
      if echo "$key" | grep -q '\.' ; then
	local sect="$(echo "$key" | cut -d. -f1)"
	local key="$( echo "$key" | cut -d. -f2)"
      fi
      #
      # Delete a key...
      #
      if [ -z "$sect" ] ; then
	ncont="$(echo "$ncont" | sed  '1,/^:\[/{/^:[ 	]*'"$key"'[ 	]*=/d}')"
      else
	ncont="$(echo "$ncont" | sed  '/^:\['"$sect"'\]/,/^:\[/{/^:[ 	]*'"$key"'[ 	]*=/d}')"
      fi
      continue
    fi

    eval "$(_kvpparsekvp $kvp)"
    
    ncont="$(echo "$ncont" | _kvpadd "$key" "$val" "$sect")"
  done
  
  [ x"$ncont" = x"$ocont" ] && return # No changes!
  
  if [ -f "$FILE" ] ; then
    if [ -z "$BACKUPDIR" ] ; then
      [ -n "$BACKUPEXT" ] && cp -dp $FILE $FILE$BACKUPEXT
    else
      cp -dp $FILE $BACKUPDIR/$(basename $FILE)
    fi
  fi
  echo "$ncont" |sed 's/^://' > "$FILE"
  echo "$FILE: updated" 1>&2 
}


