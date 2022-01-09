#!/usr/bin/atf-sh

if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi

. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh

include -1 api-hosts.sh

xt_hostmgr_ops() {
  : =descr "Test hostmgr ops"

  hosts_setup || atf_fail "hosts_setup failed"
  policy_setup || atf_fail "policy_setup failed"

  local mgr="$TLR_BIN/tlr hostmgr"

  $mgr || atf_fail "hostmgr"
  atf_check_equal 6	$($mgr list | wc -l)
  $mgr cfg sys1 role myrole
  atf_check_equal 4	$($mgr cfg -v sys1 | wc -w)
  atf_check_equal 12	$($mgr pk -v sys1 | wc -w)

  $mgr new -b sys1 && atf_fail "hosts_new:1"
  ($mgr new -b zys1 | base64 -d | tar ztvf -) || atf_fail "hosts_new:2"
  $mgr del zys1 zys2 || atf_fail "hosts_del:1"

  pubkeys="$(
    d=$(mktemp -d)
    for type in $hosts_key_types
    do
       ssh-keygen -q -N '' -t $type -C "host:${type}@sys$RANDOM" \
	  -f "$d/ssh_host_${type}_key"
    done
    cat $d/ssh_host_*_key.pub
    rm -rf "$d"
  )"
  echo "$pubkeys" | $mgr add sys20 || atf_fail "host_add:1"
  echo "$pubkeys" | $mgr add sys21 uuid $(cat /proc/sys/kernel/random/uuid)  || atf_fail "host_add:2"


}

xatf_init
