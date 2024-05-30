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
## Shell escape function.  Quotes strings so they can be safefly included
## parsed by eval or in other scripts.

_do_shesc() {
  case "$*" in
  *\'*)
    ;;
  *)
    echo "'$*'"
    return
    ;;
  esac

  local in="$*" ; shift
  local ln=${#in}
  local oo="" q=""
  local i=0; while [ $i -lt $ln ]
  do
    local ch=${in:$i:1}
    case "$ch" in
    [a-zA-Z0-9.~_/+-])
      oo="$oo$ch"
      ;;
    \')
      q="'"
      oo="$oo'\\''"
      ;;
    *)
      q="'"
      oo="$oo$ch"
      ;;
    esac
    i=$(expr $i + 1)
  done
  echo "$q$oo$q"
}


shell_escape() {
  ##   Escape string for shell parsing
  ## # USAGE
  ##   shell_escape [options] "string"
  ## # OPTIONS
  ## * -q : Always include single quotes
  ## * - : End of options
  ## # DESC
  ## shell_escape will examine the passed string in the
  ## arguments and add any appropriate meta characters so that
  ## it can be safely parsed by a UNIX shell.
  ##
  ## It does so by enclosing the string with single quotes (if
  ## it the string contains "unsafe" characters.).  If the string
  ## only contains safe characters, nothing is actually done.
  ##
  [ $# -eq 0 ] && return 0 # Trivial case...
  if [ x"$1" = x"-q" ] ; then
    # Always include single quotes... makes code simpler...
    shift
    _do_shesc "$@"
    return $?
  elif [ x"$1" = x"-" ] ; then
    shift
  fi
  if [ -z "$(echo "$*" | tr -d 'a-zA-Z0-9.~_/+-]')" ] ; then
    # All valid chars, nothing to be done...
    echo "$*"
    return 0
  fi
  _do_shesc "$@"
  return $?
}

