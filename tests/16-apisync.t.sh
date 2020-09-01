#!/bin/sh
#
# basic test...

. ${TESTDIR:=$(cd $(dirname "$0") ; pwd)}/common.sh
mkdir -p $TESTDIR/t.priv
export TLR_DATA=$TESTDIR/t.priv
include -1 api-hosts api-sync depcheck

  ##  sync_rpc_check [incoming rsync options]

if sync_rpc_check 1 2 3 4 5 ; then
  quit 10 "Invalid rsync arguments"
fi
if ! sync_rpc_check --server --sender "$rsync_rpc_opts" . $TLR_DATA ; then
  quit 16 "Valid rsync arguments"
fi

auth_keys=$TESTDIR/t.priv/hostkeys
rm -f $auth_keys

if ! sync_check_hostkeys "$auth_keys" ; then
  quit 23 "sync_check_hostkeys - $auth_keys did not trigger"
fi

TLR_SSH_FORCED_CMD=$TLR_BASE/bin/sshrpc sync_gen_host_keys | tee "$auth_keys" | (head -4;echo ... $(wc -l) lines omitted ...)

if sync_check_hostkeys "$auth_keys" ; then
  quit 27 "sync_check_hostkeys - $auth_keys DID trigger"
fi

cp -a $TESTDIR/data/sshd_config $TESTDIR/t.priv/sshd_config
sync_sshdcfg_fixup -v $TESTDIR/t.priv/sshd_config $auth_keys
diff -u $TESTDIR/data/sshd_config $TESTDIR/t.priv/sshd_config \
	&& quit 34 "Fixup failed"

sync_sshd_restart

