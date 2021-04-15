#!/bin/sh
#
# basic test...

. ${TESTDIR:=$(cd $(dirname "$0") ; pwd)}/common.sh
mkdir -p $TESTDIR/t.priv
export TLR_DATA=$TESTDIR/t.priv
include -1 api-hosts

hosts_del $(for n in $(seq 1 6) ; do echo tstsys$n ; done)

for c in $(seq 1 2)
do
  rm -rf $TESTDIR/t.priv/host-tstsys$c
  mkdir -p $TESTDIR/t.priv/host-tstsys$c
  hosts_new tstsys$c $TESTDIR/t.priv/h_tstsys$c.tar.gz
  [ $(wc -c < $TESTDIR/t.priv/h_tstsys$c.tar.gz) -gt 100 ]
  tar -C $TESTDIR/t.priv/host-tstsys$c -zxvf $TESTDIR/t.priv/h_tstsys$c.tar.gz
done

for c in $(seq 3 6)
do
  hosts_new tstsys$c /dev/null
done

if ! hosts_exists tstsys6 ; then
 quit 16 "hosts_exists(tstsys6) should be true"
fi
hosts_del tstsys6
if hosts_exists tstsys6 ; then
 quit 16 "hosts_exists(tstsys6) should be false"
fi

if ! try=$(hosts_namechk mean-s45) ; then
  quit 28 "hosts_namechk(mean-s45) should be good"
fi
if try=$(hosts_namechk Hxyz'$@') ; then
  quit 31 "hosts_namechk($try) should be bad"
fi
if [ $(hosts_list | wc -w) -ne 5 ] ; then
  quit 34 "hosts_list should return 5 names"
fi

myroles="one two thre"
pubkey="be2AixeiSh5iu4rohS5Ux4arah6ThieZoo8aeg5mahfoi2chez6mee4Loo2foo9zeeYeireithahngaiveeJiu2iepoj1Iejaa3Goh8bie2uru8jep1goitienai3see"

if [ $(hosts_get -v --pub tstsys3 | wc -l) -lt 3 ] ; then
  quit 41 "hosts_get(-v --pub tstsys3) was incomplete"
fi

hosts_set tstsys3 myroles "" pubkey
if [ -n "$(hosts_get tstsys3 myroles || :)" ] ; then
  quit 46 "hosts_get(tsstsys3,myroles) should return empty"
fi

hosts_set tstsys3 myroles "$myroles" pubkey "$pubkey"
if [ x"$(hosts_get tstsys3 myroles)" != x"$myroles" ] ; then
  quit 53 "hosts_get(tstsys3,myroles) != $myroles"
fi
if [ x"$(hosts_get tstsys3 pubkey)" != x"$pubkey" ] ; then
  quit 53 "hosts_get(tstsys3,pubkey) != $pubkey"
fi

hosts_set tstsys3 myroles "" pubkey
if [ -n "$(hosts_get tstsys3 myroles || :)" ] ; then
  quit 46 "hosts_get(tsstsys3,myroles) should return empty"
fi

if [ $(hosts_pub -v tstsys3 | wc -l) -lt 3 ] ; then
  quit 41 "hosts_pub(-v tstsys3) was incomplete"
fi
hosts_cfg tstsys3 myroles "" pubkey
if [ -n "$(hosts_cfg tstsys3 myroles || :)" ] ; then
  quit 46 "hosts_cfg(tsstsys3,myroles) should return empty"
fi
hosts_cfg tstsys3 myroles "$myroles" pubkey "$pubkey"
if [ x"$(hosts_cfg tstsys3 myroles)" != x"$myroles" ] ; then
  quit 53 "hosts_cfg(tstsys3,myroles) != $myroles"
fi
if [ x"$(hosts_cfg tstsys3 pubkey)" != x"$pubkey" ] ; then
  quit 53 "hosts_cfg(tstsys3,pubkey) != $pubkey"
fi

hosts_cfg tstsys3 myroles "" pubkey
if [ -n "$(hosts_cfg tstsys3 myroles || :)" ] ; then
  quit 46 "hosts_cfg(tsstsys3,myroles) should return empty"
fi

