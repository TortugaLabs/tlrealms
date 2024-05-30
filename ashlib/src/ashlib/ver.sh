#!/bin/sh
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
#****h* ashlib/ver
# FUNCTION
# Functions related to version names
#****

gitver() {
#****f* ver/gitver
# NAME
#   gitver -- Determine the current version information from git
# SYNOPSIS
#   gitver _git-directory_
# ARGUMENTS
# * git-directory : Directory to the git repository
# OUTPUT
# version information
#****

  local dir="$1" ; shift
  if [ -d "$dir/.git" ] ; then
    if type git >/dev/null 2>&1 ; then
      # Git exists...
      local gitdir="--git-dir=$dir/.git"
      desc=$(git $gitdir describe --dirty=,M 2>/dev/null)
      branch_name=$(git $gitdir symbolic-ref -q HEAD)
      branch_name=${branch_name##refs/heads/}
      branch_name=${branch_name:-HEAD}
      if [ "master" = "$branch_name" ] ; then
	branch_name=""
      else
	branch_name=":$branch_name"
      fi
      echo $desc$branch_name
      return 0
    fi
  fi
  if [ -f "$dir.id" ] ; then
    cat "$dir.id"
    return 0
  fi
  if [ -f "$dir/.id" ] ; then
    cat "$dir/.id"
    return 0
  fi
  if [ -f "$dir/version.txt" ] ; then
    cat "$dir/version.txt"
    return 0
  fi
  echo 'Unknown'
  return 1
}

