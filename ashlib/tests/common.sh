#!/bin/sh
. $(atf_get_srcdir)/../xatflib/xatf.sh

if [ -d $(atf_get_srcdir)/../src/ashlib ] ; then
  export ASHLIB=$(atf_get_srcdir)/../src/ashlib
  . $ASHLIB/ashlib.sh
else
  exit 1
fi
export ASHLIB_PATH=$ASHLIB

