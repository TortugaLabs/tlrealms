#!/bin/sh
. $(atf_get_srcdir)/lib/xatf.sh

if [ -d $(atf_get_srcdir)/../.ashlib ] ; then
  export ASHLIB=$(atf_get_srcdir)/../.ashlib
  . $ASHLIB/ashlib.sh
else
  exit 1
fi
export TLR_BASE=$(atf_get_srcdir)/../base
export TLR_LIB=$TLR_BASE/lib
export ASHLIB_PATH=$TLR_LIB:$ASHLIB

