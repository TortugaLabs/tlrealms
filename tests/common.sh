#!/bin/sh
#
# Prepare settings for tests
#

export SRCDIR=$TESTDIR/..

export \
	TLR_CFG=$TESTDIR/tlr.cfg \
	TLR_BASE=$SRCDIR/base \
	ASHLIB=$SRCDIR/.ashlib

. $TLR_BASE/crt.sh

