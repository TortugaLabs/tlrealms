#!/bin/sh
#
# Assumes:
#	TLR_BASE, TLR_LIB, TLR_BIN, ASHLIB, ASHLIB_PATH
#
. $ASHLIB/ashlib.sh
set -euf -o pipefail

include -1 cfv.sh

sysname() {
  [ -z "${TLR_SYSNAME:-}" ] && TLR_SYSNAME=$(uname -n)
  echo $TLR_SYSNAME
}

add_host() { :; }
add_role() { :; }


# Load local overrides
cfv TLR_CFG /etc/tlr.cfg
[ -r "$TLR_CFG" ] && . "$TLR_CFG"

cfv TLR_DATA /etc/tlr
cfv TLR_LOCAL /etc/tlr-local

# Load global configurations
# settings.sh are general, secrets.sh are restricted values
[ -r "$TLR_DATA/settings.sh" ] && . "$TLR_DATA/settings.sh"
[ -r "$TLR_DATA/secrets.sh" ] && . "$TLR_DATA/secrets.sh"

:
