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
#****h* ashlib/mkid
# FUNCTION
# Create arbintrary id strings
#****

mkid() {
  #****f* mkid/mkid
  # NAME
  #   mkid -- create arbitrary id strings
  # SYNOPSIS
  #   mkid _text_
  # INPUTS
  # * text -- text to convert into id
  # OUTPUT
  # Sanitized text
  # FUNCTION
  # `mkid` accepts a string and sanitizes it so
  # that it can be used as a shell variable name
  #****
  echo "$*" | tr ' -' '__' | tr -dc '_A-Za-z0-9' \
  		| sed -e 's/^\([0-9]\)/_n\1/'
}
