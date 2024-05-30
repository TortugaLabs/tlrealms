#!/bin/sh
#
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

#****h* ashlib/urlencode
# FUNCTION
# Functions releated to URL encoding and decoding
#****


urlencode() {
  #****f* urlencode/urlencode
  # NAME
  #   urlencode -- encode string according to URL escape rules
  # SYNOPSIS
  #   urlencode _string_
  # ARGUMENTS
  # * string : string to encode
  # OUTPUT
  # Encoded string
  #****
  local l=${#1}

  local i=0; while [ $i -lt $l ]
  do
    local c=${1:$i:1}
    case "$c" in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
      ' ') printf + ;;
      *) printf '%%%.2X' "'$c"
    esac
    i=$(expr $i + 1)
  done
}

urldecode() {
  #****f* urlencode/urldecode
  # NAME
  #   urldecode - decode URL encoded strings
  # SYNOPSIS
  #   urldecode _string_
  # ARGUMENTS
  # * string : string to decode
  # OUTPUT
  # Decoded strings
  #****
  local data=${1//+/ }
  printf '%b' "${data//%/\\x}"
}
