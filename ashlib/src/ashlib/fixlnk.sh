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

fixlnk() {
## Function to update symlinks
## # USAGE
##    fixlnk [-D] target lnk
## # ARGS
## * -D -- if specified, link directory is created.
## * target -- where the link should be pointing to
## * lnk -- where the link is to be created
## # DESC
## Note that this will first check if the symlink needs to be corrected.
## Otherwise no action is taken.
  local mkdir=false

  while [ $# -gt 0 ]
  do
    case "$1" in
    -D) mkdir=true ;;
    *) break
    esac
    shift
  done

  if [ $# -ne 2 ] ; then
    echo "Usage: fixlnk {target} {lnk}" 1>&2
    return 1
  fi

  local lnkdat="$1"
  local lnkloc="$2"

  if [ -L "$lnkloc" ] ; then
    clnkdat=$(readlink "$lnkloc")
    [ x"$clnkdat" = x"$lnkdat" ] && return 0
    echo "Updating $lnkloc" 1>&2
    rm -f "$lnkloc"
  elif [ -e "$lnkloc" ] ; then
    echo "Fixing $lnkloc" 1>&2
    rm -rf "$lnkloc"
  else
    echo "Creating $lnkloc" 1>&2
  fi
  if $mkdir ; then
    [ ! -d "$(dirname "$lnkloc")" ] && mkdir -p "$(dirname "$lnkloc")"
  fi
  ln -s "$lnkdat" "$lnkloc"
}

