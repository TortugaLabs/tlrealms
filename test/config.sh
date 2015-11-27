#!/bin/sh

testdat=$(cd $lib/../testdata && pwd)
dbdir=$testdat/srcfile
etcdir=$tstdat/etc

export PATH=$PATH:$(cd $(dirname $0) ; pwd)

crypt="perl -w $(dirname $0)/../test/crypt.pl"

# PWD Files
pwdfile=$dbdir/pwds
htdigest=$dbdir/htdigest
kadmin=kadmin.local
shadow=$dbdir/shadow
htrealm='0ink.net'

sys_authkeys=$etcdir/dropbear/authorized_keys
sys_knownhosts=$etcdir/dropbear/known_hosts
hostkey_cmd=$(dirname $0)/hostkey

