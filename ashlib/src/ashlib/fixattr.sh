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

fixattr() {
  ## Updates file attributes
  ## # USAGE
  ##   fixattr [options] file
  ## # OPTIONS
  ## * --mode=mode -- Target file mode
  ## * --user=user -- User to own the file
  ## * --group=group -- Group that owns the file
  ## * file -- file to modify.
  ## # DESC
  ## This function ensures that the given `file` has the defined file modes,
  ## owner user and owner groups.
  
  local mode="" user="" group=""
  
  while [ $# -gt 0 ]
  do
    case "$1" in
	--mode=*)
	    mode=${1#--mode=}
	    ;;
	--user=*)
	    user=${1#--user=}
	    ;;
	--group=*)
	    group=${1#--group=}
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

  if [ $# -eq 0 ] ; then
    echo "No file specified" 1>&2
    return 1
  elif [ $# -gt 1 ] ; then
    echo "Ignoring additional options: $*" 1>&2
  fi

  local file="$1"

  if [ -z "$group" ] ; then
    # Check if USER == {user}:{group}
    eval $(
	echo $user | (
	    IFS=:
	    a="" ; b=""
	    read a b
	    [ -z "$b" ] && return
	    echo "user='$a' ; group='$b'"
	)
    )
  fi

  local msg=

  if [ -n "$user" ] ; then
    if [ $(find "$file" -maxdepth 0 -user "$user" | wc -l) -eq 0 ] ; then
      chown "$user" "$file"
      msg=$(echo $msg chown)
    fi
  fi
  if [ -n "$group" ] ; then
    if [ $(find "$file" -maxdepth 0 -group "$group" | wc -l) -eq 0 ] ; then
      chgrp "$group" "$file"
      msg=$(echo $msg chgrp)
    fi
  fi
  if [ -n "$mode" ] ; then
    if [ $(find "$file" -maxdepth 0 -perm "$mode" | wc -l) -eq 0 ] ; then
      chmod "$mode" "$file"
      msg=$(echo $msg chmod)
    fi
  fi
  [ -n "$msg" ] && echo "$file $msg" 1>&2
}
