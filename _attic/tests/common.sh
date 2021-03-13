#!/bin/sh
#
# Prepare settings for tests
#

export SRCDIR=$TESTDIR/..

export \
	TLR_CFG=$TESTDIR/tlr.cfg \
	TLR_BASE=$SRCDIR/base \
	ASHLIB=$SRCDIR/.ashlib

#~ [ -d $TESTDIR/t.data ] && export TLR_DATA=$TESTDIR/t.data

. $TLR_BASE/crt.sh

