#!/usr/bin/atf-sh
#
# Test RPC
#

if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi
. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh

include -1 api-hosts.sh
include -1 api-users.sh
include -1 api-groups.sh
include -1 api-sshutil.sh

run_sshd() {
  # exec /usr/sbin/sshd -f $sshdir/sshd_config -d
  #( exec /usr/sbin/sshd -E $sshdir/debug.log -f $sshdir/sshd_config -d ) &
  ( exec nc -l -p $sshd_port -e "/usr/sbin/sshd -E $sshdir/debug.log -f $sshdir/sshd_config -i" ) &
  sshpid=$!
  sleep 1
  [ $# -eq 0 ] && return 0
  local ret=0
  ( xtf "$@" ) || ret=$?
  [ -d /proc/$sshpid ] && kill $sshpid
  return $ret
}

append_rc() {
  echo "$*" 1>&2
  if [ -n "$rc" ] ; then
    rc="$(printf '%s\n%s' "$rc" "$*")"
  else
    rc="$*"
  fi
}

#
# PREPARE
#
test_env_setup() {
  groups_setup || atf_fail "groups_setup failed"
  users_setup || atf_fail "users_setup failed"
  etcdat_setup || atf_fail "etcdat_setup failed"
  hosts_setup || atf_fail "hosts_setup failed"

  # Create client test key
  ssh-keygen -q -N '' -t rsa -C "test-key" -f "$testkey"

  host_keys=$(find $TLR_DATA/systems/$master -mindepth 1 -maxdepth 1 -name 'ssh_*' | xargs)

  cp -al $host_keys $TLR_ETC/ssh
  (
    cat <<-_EOF_
	Port $sshd_port

	$(
	  for kt in $hosts_key_types
	  do
	    echo HostKey $sshdir/ssh_host_${kt}_key
	  done
	)
	AuthorizedKeysFile  $auth_keys $sshdir/test_rsa_key.pub
	ChallengeResponseAuthentication no
	UsePAM no
	Subsystem   sftp    /usr/lib/ssh/sftp-server
	PidFile $TLR_LOCAL/sshd.pid
        StrictModes no
	_EOF_
  ) | tee $TLR_ETC/ssh/sshd_config
  fenv="TLR_DATA=$TLR_DATA ASHLIB=$ASHLIB TLR_LOCAL=$TLR_LOCAL"
  fenv="$fenv TLR_ETC=$TLR_ETC"
  TLR_SSH_FORCED_CMD="$fenv $(readlink -f $TLR_BASE)/bin/tlr in.rpc" \
      $TLR_BIN/tlr genfiles host-keys "$auth_keys" || atf_fail "gen host-keys"
  grep ssh-rsa "$auth_keys" | head -2
  atf_check_equal 24	$(wc -l < "$auth_keys")

  client=sys2
  sshkey=$TLR_DATA/systems/$client/ssh_host_rsa_key
  bindir=$(readlink -f $TLR_BIN)
  export TLR_SSH_USER=$USER TLR_SSH_ARGS="-p $sshd_port" TLR_SSH_KEY=$sshkey TLR_MASTER=localhost
}

xt_rpc_ops() {
  : =descr "Test RPC ops"

  sshdir=$TLR_ETC/ssh
  auth_keys=$sshdir/hostkeys
  sshd_port=$(expr 2222 + $(expr $RANDOM % 200))
  master=sys1
  testkey=$sshdir/test_rsa_key

  test_env_setup
  rc=''

  run_sshd sync_ssh_cmd -i $testkey localhost /bin/sh -c 'uname -a' || append_rc "admin_key_test:1"
  run_sshd sync_ssh_cmd -i $sshkey localhost /bin/sh -c 'uname -a' && append_rc "hostkey forced cmd:1" || :
  run_sshd sync_ssh_cmd -i $sshkey localhost $bindir/tlr in.rpc ping || append_rc "hostkey forced cmd:2"
  run_sshd sync_ssh_cmd -i $sshkey localhost ping || append_rc "hostkey forced cmd:3"

  (run_sshd sync_ssh_cmd -i $testkey localhost env $fenv $bindir/tlr in.rpc dump | base64 -d | tar -ztvf - ) || append_rc "in.rpc-dump:1"
  (run_sshd $bindir/tlr rpc dump | base64 -d | tar ztvf - ) || append_rc "rpc-dump:1"
  mkdir -p $TLR_ETC/tlr-data
  run_sshd env TLR_DATA=$TLR_ETC/tlr-data $bindir/tlr rpc load  || append_rc "rpc-load:1"
  diff -qr $TLR_ETC/tlr-data $TLR_DATA || append_rc "rpc-load:2"

  (
    run_sshd sync_ssh_cmd -i $testkey localhost env $fenv $bindir/tlr hostmgr new -b zys1 \
	| base64 -d | tar -ztvf -
  ) || append_rc "rcmd-hostmgr-add:1"
  diff -qr $TLR_ETC/tlr-data $TLR_DATA && append_rc "rpc-load:3" || :


  run_sshd env TLR_DATA=$TLR_ETC/tlr-data $bindir/tlr rpc rsync || append_rc "rpc-sync:1"
  diff -qr $TLR_ETC/tlr-data $TLR_DATA || append_rc "rpc-sync:2"


  if [ -n "$rc" ] ; then
    echo "$rc"
    atf_fail "$rc"
  fi
}


xt_rpc_chxx() {
  : =descr "Test RPC chfn+chpw"

  sshdir=$TLR_ETC/ssh
  auth_keys=$sshdir/hostkeys
  sshd_port=$(expr 2222 + $(expr $RANDOM % 200))
  master=sys1
  testkey=$sshdir/test_rsa_key

  test_env_setup
  labrat="arthur"
  pw1=$(users_pwgen 16)
  pw2=$(users_pwgen 16)
  users_passwd --set "$labrat" "$pw1"
  (xtf users_pwck "$labrat" "$pw1") || atf_fail "correct pwck failed"

  rc=''

  # test case for chpw
  (printf "%s\n%s\n" "$pw1" "$pw2" | run_sshd $bindir/tlr rpc chpw "$labrat") \
      || append_rc "chpw($labrat):1"
  (xtf users_pwck "$labrat" "$pw2") || append_rc "correct pwck failed:1"
  (printf "%s\n%s\n" "$pw1" "nonen" | run_sshd $bindir/tlr rpc chpw "$labrat") \
      && append_rc "chpw($labrat):2"
  (xtf users_pwck "$labrat" "$pw2") || append_rc "correct pwck failed:2"

  # test case for ckfn
  cfile=$TLR_DATA/users.d/$labrat.cfg
  res="$(run_sshd $bindir/tlr rpc ckfn "$labrat")" || append_rc "ckfn($labrat):1"
  [ x"$(echo "$res"|sort)" = x"$(cat "$cfile"|sort)" ] || append_rc "ckfn($labrat):2"

  # test case for chfn
  cfile=$TLR_DATA/users.d/$labrat.cfg
  ( echo "$pw2" | run_sshd $bindir/tlr rpc chfn --shell=/bin/dash "$labrat") \
	|| append_rc "chfn($labrat):1"
  [ x"/bin/dash" = x"$(awk '$1 == "pw_shell" { print $2 }' $cfile)" ] \
      || append_rc "chfn($labrat):1-pwshell"
  ( echo "$pw2" | run_sshd $bindir/tlr rpc chfn --gecos="John Doe" "$labrat") \
	|| append_rc "chfn($labrat):2"
  [ x"John Doe" = x"$(awk '$1 == "gecos" { print }' $cfile| cut -d' ' -f2-)" ] \
      || append_rc "chfn($labrat):2-gecos"
  ( echo "$pw2" | run_sshd $bindir/tlr rpc chfn --shell=/bin/nologin --gecos="Disabled Guy" "$labrat") \
	|| append_rc "chfn($labrat):3"
  [ x"/bin/nologin" = x"$(awk '$1 == "pw_shell" { print $2 }' $cfile)" ] \
      || append_rc "chfn($labrat):3-pwshell"
  [ x"Disabled Guy" = x"$(awk '$1 == "gecos" { print }' $cfile| cut -d' ' -f2-)" ] \
      || append_rc "chfn($labrat):3-gecos"

  if [ -n "$rc" ] ; then
    echo "$rc"
    atf_fail "$rc"
  fi

}

xatf_init









