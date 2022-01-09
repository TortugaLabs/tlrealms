#!/bin/sh

if [ -d $(atf_get_srcdir)/../.ashlib ] ; then
  export ASHLIB=$(readlink -f $(atf_get_srcdir)/../.ashlib/src/ashlib)
  . $ASHLIB/ashlib.sh
  . $(atf_get_srcdir)/../.ashlib/xatflib/xatf.sh
else
  exit 1
fi
export TLR_BASE=$(atf_get_srcdir)/../base
export TLR_LIB=$TLR_BASE/lib TLR_BIN=$TLR_BASE/bin
export ASHLIB_PATH=$TLR_LIB:$ASHLIB

