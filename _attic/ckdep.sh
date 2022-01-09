#!/bin/sh

ckdep() {
  local output="$1" ; shift
  
  [ ! -e "$output" ] && return 0
  local i
  for i in "$@"
  do
    [ "$i" -nt "$output" ] && return 0
  done
  return 1
}
