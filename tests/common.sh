#!/bin/sh
#
# Prepare settings for tests
#

export SRCDIR=$(cd $TESTDIR/.. && pwd)

export \
	TLR_CFG=$TESTDIR/tlr.cfg \
	TLR_BASE=$SRCDIR/base \
	ASHLIB=$SRCDIR/.ashlib \
	PATH=$SRCDIR/base/bin:$PATH

#~ [ -d $TESTDIR/t.data ] && export TLR_DATA=$TESTDIR/t.data

. $TLR_BASE/crt.sh

