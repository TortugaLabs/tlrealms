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
#****h* ashlib/randpw
# FUNCTION
# Generate random passwords
#****

randpw() {
  #****f* randpw/randpw
  # NAME
  #   randpw -- Genrate random password
  # SYNOPSIS
  #   randpw [length]
  # ARGUMENTS
  # * length : password length
  # OUTPUT
  # random password of the specified length
  #****
  local chrs="1234567890abcdefghijklmnopqrstuvwxuyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#%^&*()-+_[]{};:,./<>?~'"
  local cc=$(expr length "$chrs")

  local cnt=32 i=''
  [ $# -gt 0 ] && cnt="$1"

  while [ $cnt -gt 0 ]
  do
    cnt=$(expr $cnt - 1)
    i="$i${chrs:$(expr $RANDOM % $cc):1}"
  done
  echo "$i"
}
echo $(randpw)



