#!/usr/bin/atf-sh

if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi
. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh

include -1 api-groups.sh
include -1 api-users.sh

xt_grpmgr_ops() {
  : =descr "Group management"

  groups_setup || atf_fail "groups_setup failed"
  users_setup || atf_fail "users_setup failed"
  policy_setup || atf_fail "policy_setup failed"

  local grpmgr="$TLR_BIN/tlr grpmgr"

  atf_check_equal 6 "$($grpmgr list | wc -l)"

  $grpmgr add --gid=8000 labrats || atf_fail "create grp labrats"
  groups_exists labrats || atf_fail "Failed to create labrats"
  atf_check_equal 8000 "$(groups_gid labrats)"
  $grpmgr add nolabs || atf_fail "Create grp nolabs"
  $grpmgr add nolabs && atf_fail "Group already exists" || :

  atf_check_equal 8000 "$($grpmgr gid labrats)"
  $grpmgr gid --gid=7000 labrats || atf_fail "Unable to set gid"
  atf_check_equal 7000 "$($grpmgr gid labrats)"

  atf_check_equal "" "$($grpmgr members labrats)"
  atf_check_equal "arthur galahad gawain guinie kay lancelot morgana percivale" \
			"$($grpmgr members nobles)"
  $grpmgr members noone arthur sid && atf_fail "setmembers noone : did not fail" || :
  $grpmgr members labrats arthur sid kaku coco @xyz && atf_fail "setmembers labrats : did not fail" || :
  $grpmgr members labrats arthur sid @royals || atf_fail "setmemebers labrats : failed"
  atf_check_equal "arthur guinie sid" \
			"$($grpmgr members labrats)"

  $grpmgr adduser nogrp arthur sid && atf_fail "adduser: did not fail"
  $grpmgr adduser labrats @xyz coco kaku && atf_fail "adduser: did not fail"
  $grpmgr adduser labrats sancho @soldiers || atf_fail "adduser: failed!" || :
  atf_check_equal "arthur guinie sancho sid" \
			"$($grpmgr members labrats)"

  $grpmgr deluser nogrp arthur sid && atf_fail "deluser: did not fail"
  $grpmgr deluser labrats x y z @bla || atf_fail "deluser: failed"
  atf_check_equal "arthur guinie sancho sid" \
			"$($grpmgr members labrats)"
  $grpmgr deluser labrats sid @royals || atf_fail "deluser: failed"
  atf_check_equal "arthur sancho sid" \
			"$($grpmgr members labrats)"

  atf_check_equal "admins labrats nobles royals" \
			"$($grpmgr usergroups arthur)"

  $grpmgr del labrats royals
  atf_check_equal "@knights morgana" "$(xtf groups_members --no-resolve nobles)"
  xtf groups_exists royals && atf_fail "royals was not deleted" || :
  groups_exists labrats && atf_fail "labrats was not deleted" || :

}

xatf_init
