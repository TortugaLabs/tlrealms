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

## Some simple misc functions
#
warn() {
  ##   Show a warning on stderr
  ## # USAGE
  ##   warn message
  echo "$@" 1>&2
}

fatal() {
  ## Fatal error
  ## # USAGE
  ##    fatal message
  ## # DESC
  ## Show the fatal error on stderr and terminates the script.
  echo "$@" 1>&2
  exit 1
}

quit() {
  ## Exit with status
  ## # USAGE
  ##    quit exit_code message
  ## # DESC
  ## Show the fatal error on stderr and terminates the script with
  ## exit_code.
  local code="$1" ; shift
  echo "$@" 1>&2
  exit $code
}
