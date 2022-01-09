#!/usr/bin/atf-sh
#
# Test ssh utils
#
if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi
. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh
include -1 api-hosts.sh
include -1 api-sshutil.sh

xt_ssh_utils() {
  : =descr "Test ssh utils"

  hosts_setup || atf_fail "hosts_setup failed"

  (xtf sync_rpc_check x y z a b) && atf_fail "rpc_chck:1"
  (xtf sync_rpc_check --server --sender others . /etc/tlr) || atf_fail "rpc_chk:2"
  (rsync_cmd=echo ; sync_rpc_run xopts) || atf_fail "rpc_run:1"
  (rsync_cmd=echo ; sync_fetch master) || atf_faile "rpc_fetch:1"  
  
  atf_check_equal 24  $(xtf sync_gen_host_keys | wc -l)
}

xatf_init
