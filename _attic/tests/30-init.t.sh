#!/bin/sh
#
# starting point for tests
#
echo ${TESTDIR:=$(cd $(dirname "$0") ; pwd)}
mkdir -p $TESTDIR/t.data $TESTDIR/t.data/{tlr,hosts}
cp $TESTDIR/data/settings.sh $TESTDIR/t.data/tlr
. $TESTDIR/common.sh
export TLR_DATA=$TESTDIR/t.data/tlr

include -1 api-hosts

#
# Initialize a database with test host data
#
for id in $(seq 1 7)
do
  rm -rf $TESTDIR/t.data/hosts/sys$id
  mkdir $TESTDIR/t.data/hosts/sys$id
  hosts_del sys$id
  hosts_new sys$id | tar -C $TESTDIR/t.data/hosts/sys$id -zxf -
done

