#!/bin/sh

shell_escape() {
  local in="$1" ; shift
  local ln=${#in}
  local oo="" q=""
  local i=0; while [ $i -lt $ln ]
  do
    local ch=${in:$i:1}
    case "$ch" in
    [a-zA-Z0-9.~_/+-])
      oo="$oo$ch"
      ;;
    \')
      q="'"
      oo="$oo'\\''"
      ;;
    *)
      q="'"
      oo="$oo$ch"
      ;;
    esac
    i=$(expr $i + 1)
  done
  echo "$q$oo$q"
}

