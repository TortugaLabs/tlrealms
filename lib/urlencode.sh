#!/bin/sh

urlencode() {
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
  local data=${1//+/ }
  printf '%b' "${data//%/\x}"
}
