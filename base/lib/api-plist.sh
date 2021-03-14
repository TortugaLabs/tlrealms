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
## Handle property list files
##
## These are files with multiple lines with the format:
##
## <key> <space> <value>
##
#*####################################################################

plst_list() {
  ## List all property lists in a folder
  ## # USAGE
  ##   plst_list <dir> [exts]
  ## # OPTIONS
  ## * dir - folder containing property lists
  ## * exts - list of property list extensions
  ## # DESC
  ## Look in the property list directory <dir> for files with
  ## matching the given extensions.  Returns the relevant names
  ## without extensions.
  ##
  local dir="$1" ; shift

  (
    for ext in "$@"
    do
      find "$dir" -maxdepth 1 -mindepth 1 -name '*'"$ext" -type f \
	| while read ln
	do
	  basename "$ln" "$ext"
	done
    done
  ) | sort -u
}

plst_exists() {
  ## Returns if a property list id exists
  ## # USAGE
  ##   plst_exists <id> <dir> [exts]
  ## # OPTIONS
  ## * id - plist identifier
  ## * dir - folder containing property lists
  ## * exts - list of property list extensions
  ## # DESC
  ## Tests if an identifier exists
  ## # RETURNS
  ## 0 if found, 1 if not found
  ##
  local n="$1" dir="$2" ext; shift 2
  for ext in "$@"
  do
    if [ -f "$dir/$n$ext" ] ; then
      return 0
    fi
  done
  return 1
}

plst_del() {
  ## Deletes property lists
  ## # USAGE
  ##   plst_del <id> <dir> [exts]
  ## # OPTIONS
  ## * id - plist identifier
  ## * dir - folder containing property lists
  ## * exts - list of property list extensions
  ## # DESC
  ## Given the property list, it will delete them
  ##
  local n="$1" dir="$2" ext; shift 2
  for ext in "$@"
  do
    if [ -f "$dir/$n$ext" ] ; then
      rm -f "$dir/$n$ext"
    fi
  done
}

plst_set() {
  ## Writes values to property list
  ## # USAGE
  ##   plst_set <id> <dir> <ext> [key val] or [key ''] or [key]
  ## # OPTIONS
  ## * id - plist identifier
  ## * dir - folder containing property lists
  ## * ext - property list extension to use
  ## * key - key to modify
  ## * val - value to write to key, if '' or missing, the key is removed
  ##
  local n="$1" dir="$2" ext="$3" data=""; shift 3

  if [ -f "$dir/$n$ext" ] ; then
    data="$(grep . "$dir/$n$ext" || :)"
  fi
  local otxt="$data"
  while [ $# -gt 0 ]
  do
    local key="$1" val="" ; shift
    if [ $# -gt 0 ] ; then
      val="$1" ; shift
    fi

    data="$(echo "$data" | (
      awk '$1 != "'"$key"'" { print }'
      [ -n "$val" ] && echo "$key $val" || :
    ))"
  done

  if [ x"$otxt" != x"$data" ] ; then
    echo "$data" | (grep . || :) > "$dir/$n$ext"
  fi
}

plst_get() {
  ## Reads values from property list
  ## # USAGE
  ##   plst_get [-v] <id> <dir> <ext> [key]
  ## # OPTIONS
  ## * -v - return the key also
  ## * id - plist identifier
  ## * dir - folder containing property lists
  ## * ext - property list extension to use
  ## * key - key to return
  ## * val - value to write to key, if '' or missing, the key is removed
  ## # DESC
  ## Reads values for the given keys.  If no key specified it lists
  ## the keys that are defined.  If `-v` is used when no keys are
  ## specified, it returns key values.
  local optv=false
  while [ $# -gt 0 ]
  do
    case "$1" in
    -v) optv=true ;;
    *) break
    esac
    shift
  done

  local n="$1" dir="$2" ext="$3" key ; shift 3
  [ ! -f "$dir/$n$ext" ] && return 1

  if [ $# -eq 0 ] ; then
    if $optv ; then
      grep . "$dir/$n$ext"
    else
      grep . "$dir/$n$ext" | cut -d' ' -f1
    fi
    return
  fi

  local awktxt="$(
      for key in "$@"
      do
        echo '$1 == "'"$key"'" { print }'
      done
    )"

  if $optv ; then
    awk "$awktxt" "$dir/$n$ext"
  else
    awk "$awktxt" "$dir/$n$ext" | cut -d' ' -f2-
  fi
}

