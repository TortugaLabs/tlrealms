#!/bin/sh
#
## Network functions
##
## Some utilities used to manage network and related tasks
##
#

find_nic() {
## find a nic from a MAC address
## # Usage
##    find_nic mac
## # ARGS
## * mac -- mac address to find (xx:xx:xx:xx:xx)
## # OUTPUT
## The device name that belongs to that mac address
## # DESC
## Given a mac address, returns the network interface to use in
## ifconfig or other commands.
##
  local l_mac="$1"
  local dev
  for dev in $(find "/sys/class/net" -maxdepth 1 -mindepth 1)
  do
    [ ! -e "$dev/device" ] && continue
    dev=$(basename "$dev")
    local cmac=$(sudo ip addr show dev "$dev" | awk '/link\/ether/ {print $2}')
    [ -z "$cmac" ] && continue
    [ "$cmac" = "$l_mac" ] && echo "$dev"
  done
}
