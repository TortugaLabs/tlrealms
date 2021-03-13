#!/bin/sh
#
# starting point for tests
#
. ${TESTDIR:=$(cd $(dirname "$0") ; pwd)}/common.sh
export TLR_DATA=$TESTDIR/t.data/tlr

include -1 api-hosts api-sync


sshdir=$TESTDIR/t.data/ssh
auth_keys=$sshdir/hostkeys
sshd_port=$(expr 2222 + $(expr $RANDOM % 200))
master=sys1

mkdir -p $sshdir

rm -f $auth_keys

TLR_SSH_FORCED_CMD=$TLR_BASE/bin/sshrpc \
TLR_SSH_FORCED_ENV="TLR_DATA=$TLR_DATA ASHLIB=$ASHLIB TLR_BASE=$TLR_BASE" \
      sync_gen_host_keys | tee "$auth_keys" | (head -4;echo ... $(wc -l) lines omitted ...)

(
  cat <<-_EOF_
	Port $sshd_port

	$(
	  for kt in $hosts_key_types
	  do
	    echo HostKey $TESTDIR/t.data/hosts/$master/ssh_host_${kt}_key
	  done
	)
	AuthorizedKeysFile  $auth_keys
	ChallengeResponseAuthentication no
	UsePAM no
	Subsystem   sftp    /usr/lib/ssh/sftp-server
	PidFile $sshdir/sshd.pid
	_EOF_
) > $sshdir/sshd_config

run_sshd() {
  exec /usr/sbin/sshd -E $sshdir/debug.log -f $sshdir/sshd_config -d
}

client=sys2
sshkey=$TESTDIR/t.data/hosts/$client/ssh_host_rsa_key

( run_sshd ) &
sshpid=$!
sleep 1

TLR_DATA=$TESTDIR/t.data/hosts/$client/tlr \
  TLR_SSH_ARGS="-p $sshd_port" \
  TLR_SSH_KEY=$sshkey \
  sync_fetch localhost

[ -d /proc/$sshpid ] && kill $sshpid

( run_sshd ) &
sshpid=$!
sleep 1

env SSH_AUTH_SOCK= \
	ssh -p $sshd_port -i $sshkey \
		-o BatchMode=yes \
		-o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null \
	localhost /usr/local/bin/sshrpc ping

[ -d /proc/$sshpid ] && kill $sshpid

#~ dk=rsa

#~ sleep 1
#~ : ssh -i $sshdir/ssh_host_${dk}_key -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	#~ -p $sshd_port localhost /bin/dash -c 'hostname;whoami;uptime;echo " "'

#~ rsync -az --delete \
	#~ -e "ssh -p 2222 -i $sshdir/ssh_host_${dk}_key -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
	#~ "localhost:$TLR_DATA/" "$sshdir/recv.d"


#~ wait

#~ (
  #~ sysname=$(hostname)
  #~ for kt in $keytypes
  #~ do
    #~ pubkey=$(cat $sshdir/ssh_host_${kt}_key.pub)
    #~ echo "command=\"/usr/bin/env TLR_CLIENT=$sysname TLR_DATA=$TESTDIR/tlr-data TLR_BASE=$TLR_BASE ASHLIB=$ASHLIB $TESTDIR/forcedcmd\",no-pty,no-agent-forwarding,no-port-forwarding $pubkey"
  #~ done
#~ ) > $sshdir/userkeys
