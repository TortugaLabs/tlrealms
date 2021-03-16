#!/bin/sh
#
# Assumes:
#	TLR_BASE, TLR_LIB, TLR_BIN, ASHLIB, ASHLIB_PATH
#
. $ASHLIB/ashlib.sh
set -euf -o pipefail

include -1 cfv.sh
add_host() { :; }
add_role() { :; }

cfv TLR_LOCAL $(
  for d in /var/local/tlr-local /var/lib/tlr-local /etc/tlr-local
  do
    [ ! -d "$d" ] && continue
    echo "$d"
    return
  done
  echo $d)

# Load local overrides
cfv TLR_CFG /etc/tlr.cfg
[ -r "$TLR_CFG" ] && . "$TLR_CFG"

cfv TLR_DATA /etc/tlr
# Load global configurations
# settings.sh are general, secrets.sh are restricted values
[ -r "$TLR_DATA/settings.sh" ] && . "$TLR_DATA/settings.sh"
[ -r "$TLR_DATA/secrets.sh" ] && . "$TLR_DATA/secrets.sh"

:
