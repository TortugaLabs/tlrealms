#!/bin/sh
#
# starting point for tests
#
. ${TESTDIR:=$(cd $(dirname "$0") ; pwd)}/common.sh
export TLR_DATA=$TESTDIR/t.data/tlr

hostmgr && quit 1 "Should fail!" || :
hostmgr error && quit 1 "Should fail!" || :

hostmgr list

hostmgr del new1
hostmgr new --base64 new1
hostmgr new --base64 new1 && quit 1 "should fail!" || :
hostmgr new --clobber new1 | tar ztvf -

hostmgr del new1

hostmgr list --pub sys1
hostmgr list --pub -v sys1

hostmgr set sys1 potone p1
hostmgr get sys1 potone
hostmgr get -v sys1 potone

hostmgr cfg sys1 potwo p2
hostmgr cfg sys1 potwo
hostmgr cfg -v sys1 potwo
hostmgr cfg -v sys1
