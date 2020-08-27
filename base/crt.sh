#!/bin/sh
#
# Configuration settings...
#
set -euf -o pipefail
tlcfg() {
  eval local n=\${$1:-}
  if [ -n "$n" ] ; then
    export $1
    return
  fi
  eval export ${1}='"$2"'
}

tlcfg TLR_CFG /etc/tlr.cfg
[ -f "$TLR_CFG" ] && . $TLR_CFG

tlcfg TLR_BASE /usr/local/lib/tlr
if [ ! -d "$TLR_BASE" ] ; then
  echo "TLR_BASE=$TLR_BASE: not found" 1>&2
  exit 1
fi

tlcfg ASHLIB $TLR_BASE/ashlib
tlcfg ASHLIB_PATH $TLR_BASE/lib:$ASHLIB

tlcfg TLR_DATA /etc/tlr-data
tlcfg TLR_LOCAL /var/local/tlr
tlcfg TLR_SETTINGS $TLR_DATA/settings.sh

[ -f "$TLR_SETTINGS" ] && . "$TLR_SETTINGS"

. $ASHLIB/ashlib.sh
