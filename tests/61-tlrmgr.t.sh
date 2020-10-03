#!/bin/sh
#
# starting point for tests
#
. ${TESTDIR:=$(cd $(dirname "$0") ; pwd)}/common.sh
export TLR_DATA=$TESTDIR/t.data/tlr TLR_LOCAL=$TESTDIR/t.data/local
export ETCDIR=$TESTDIR/t.data/etc

tlrmgr runpol
tlrmgr paths
tlrmgr setup
tlrmgr help
tlrmgr demodb --hosts=$TESTDIR/t.data/hosts



