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

## Used to manage multiple exit handlers
#
trap exit_handler EXIT
exit_cmd=""

exit_handler() {
  ## Actual exit function
  ## # USAGE
  ##   trap exit_handler EXIT
  ## # DESC
  ## Actual function that gets hooked into the standard EXIT trap
  ## and calls all the registered exit handlers.
  eval "$exit_cmd"
}
on_exit() {
  ## Register a command to be called on exit
  ## # USAGE
  ##   on_exit exit_command
  ## # DESC
  ## Adds a shell command to be executed on exit.
  ## Instead of hooking `trap` _cmd_ `exit`, **on_exit** is cumulative,
  ## so multiple calls to **on_exit** will not replace the exit handler
  ## but add to it.
  ##
  ## Only single commands are supported.  For more complex **on_exit**
  ## sequences, declare a function and call that instead.
  if [ -z "$exit_cmd" ] ; then
    exit_cmd="$*"
  else
    exit_cmd="$exit_cmd ; $*"
  fi
}
