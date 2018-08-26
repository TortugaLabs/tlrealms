#!/bin/sh

serial_get() {
  if [ -f "$TLR_DATA/serial.txt" ] ; then
    cat "$TLR_DATA/serial.txt"
  else
    echo "0.0"
  fi
}

serial_update() {
  local now=$(date +%s) current=$(serial_get)
  local left=$(echo "$current" | cut -d. -f1) right=$(echo "$current" | cut -d. -f2)
  if [ $left -eq $now ] ; then
    right=$(expr $right + 1)
  else
    left=$now
    right=0
  fi
  echo "$left.$right" | tee "$TLR_DATA/serial.txt"
}
