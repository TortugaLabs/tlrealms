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
rotate() {
  ## Function to rotate log files
  ## # USAGE
  ##    rotate [options] file [files ...]
  ## # OPTIONS
  ## * --count=n -- number of archive files (defaults to 10)
  ## # DESC
  ## Rotates a logfile file by subsequently creating up to
  ## count archive files of it. Archive files are
  ## named "file.number[compress-suffix]" where number is the version
  ## number, 0 being the newest and "count-1" the oldest.
  local count=10

  while [ $# -gt 0 ]
  do
    case "$1" in
      --count=*)
	count=${1#--count=}
	;;
      *)
	break
	;;
    esac
    shift
  done

  if [ $# -eq 0 ] ; then
    echo "No files specified" 1>&2
    return 1
  fi
  local f
  for f in "$@"
  do
    [ -s "$f" ] || continue # Skip if missing or empty

    local j=$count
    while [ $j -gt 0 ]
    do
      i=$(expr $j - 1)
      if [ $j -eq $count ] ; then
	[ -f "$f.$i" ] && rm -f "$f.$i"
      else
	[ -f "$f.$i" ] && mv "$f.$i" "$f.$j"
      fi
      j=$i
    done

    cp -a "$f" "$f.0" # This is the simplest way to preserve permissions
    > "$f"
  done
}
