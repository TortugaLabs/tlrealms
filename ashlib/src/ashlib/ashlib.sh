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
## This is a implicit module automatically invoked by:
##
##    eval $(ashlib)
##
## The `core` module is included automatically.
#*####################################################################

find_in_path() {
  ##   Find a file in a path
  ## # USAGE
  ##   find_in_path [--path=PATH] file
  ## # OPTIONS
  ## * --path=PATH : don't use $PATH but the provided PATH
  ## # DESC
  ## Find a file in the provided path or PATH environment
  ## variable.
  ## # RETURNS
  ## 0 if found, 1 if not found
  ## # OUTPUT
  ## full path of found file
  ##
  local spath="$PATH"
  while [ $# -gt 0 ]
  do
    case "$1" in
    --path=*)
      spath="${1#--path=}"
      ;;
    *)
      break
      ;;
    esac
    shift
  done
  if [ x"${1:0:1}" = x"/" ] ; then
    [ -f "$1" ] && echo "$1" && return 0
    return 1
  fi
  local d oIFS="$IFS" ; IFS=":"
  for d in $spath
  do
    if [ -f "$d/$1" ] ; then
      echo "$d/$1"
      IFS="$oIFS"
      return 0
    fi
  done
  IFS="$oIFS"
  return 1
}


ifind_in_path() {
    ## Determines if the specified file is in the path variable
    ## # USAGE
    ##   ifind_in_path needle haystack_variable
    ## # ARGS
    ## * needle -- item to find in the path variable
    ## * haystack_variable -- name of the variable contining path
    ## # RETURNS
    ## 0 if found, 1 if not found
    ## # OUTPUT
    ## full path of found file
    local cmd="$1"
    local dirs="$(eval echo \$$2 | tr ':' ' ')"
    local dd
    for dd in $dirs
    do
      if [ -e $dd/$cmd ] ; then
	echo $dd/$cmd
	return 0
      fi
    done
    return 1
}

include() {
  ## Include an `ashlib` module.
  ## # USAGE
  ##   include [--once] module [other modules ...]
  ## # ARGS
  ## * --once|-1 : if specified, modules will not be included more than once
  ## * module -- module to include
  ## # RETURNS
  ## 0 on success, otherwise the number of failed modules.
  [ -z "${ASHLIB_PATH:-}" ] && export ASHLIB_PATH="${ASHLIB:-.}"

  local once=false

  while [ $# -gt 0 ]
  do
    case "$1" in
    --once|-1)
      once=true
      ;;
    *)
      break
      ;;
    esac
    shift
  done

  local ext fn i c=0
  for i in "$@"
  do
    for ext in ".sh" ""
    do
      if fn=$(find_in_path --path="$ASHLIB_PATH" $i$ext) ; then
	if $once ; then
	  # Make sure this fn has not been included before...
	  if (echo "${_included_once_file_list:-}" | grep -q '^'"$fn"'$') ; then
	    # OK, included before...
	    continue 2
	  fi
	  # remember that we found it before...
	  if [ -z "${_included_once_file_list:-}" ] ; then
	    _included_once_file_list="$fn"
	  else
	    _included_once_file_list="$(echo "$_included_once_file_list"; echo "$fn")"
	  fi
	fi
	. $fn
	break
      fi
    done
    if [ -z "$fn" ] ; then
      echo "$i: not found" 1>&2
      c=$(expr $c + 1)
    fi
  done
  return $c
}
include core
