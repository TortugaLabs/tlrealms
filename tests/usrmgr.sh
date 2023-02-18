#!/usr/bin/atf-sh

if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi

. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh

include -1 api-groups.sh
include -1 api-users.sh

xt_usrmgr_ops() {
  : =descr "Test usrmgr ops"

  groups_setup || atf_fail "groups_setup failed"
  users_setup || atf_fail "users_setup failed"
  policy_setup || atf_fail "policy_setup failed"

  local usrmgr="$TLR_BIN/tlr usrmgr"

  atf_check_equal 10 "$($usrmgr list | wc -l)"
  atf_check_equal 13 "$($usrmgr cfg arthur | wc -w)"
  atf_check_equal 28 "$($usrmgr cfg arthur sid |wc -w)"

  $usrmgr add labrat < /dev/null || atf_fail "Error adding user"
  atf_check_equal 11 "$($usrmgr list | wc -l)"

  $usrmgr mod --spmax=999 labrat || atf_fail "Error mod(labrat)"
  atf_check_equal "sp_max 999" "$($usrmgr cfg labrat | awk '$1 == "sp_max"')"
  $usrmgr mod --spmax= labrat || atf_fail "Error mod(labrat)"
  atf_check_equal "" "$($usrmgr cfg labrat | awk '$1 == "sp_max"')"

  local opwd="$(cat $users_db/labrat.pwd)"
  $usrmgr passwd labrat "$(users_pwgen 8)" || atf_fail "usrmgr passwd labrat"
  local npwd="$(cat $users_db/labrat.pwd )"
  [ x"$opwd" != x"$npwd" ] || atf_fail "Failed to change passwords"

  local zpwd="$(users_pwgen 8)"
  $usrmgr passwd labrat "$zpwd" || atf_fail "usermgr passwd labrat (2)"
  $usrmgr testpasswd labrat "$zpwd" || atf_fail "usermgr testpasswd (1)"
  (echo "$zpwd" | $usrmgr testpasswd labrat ) || atf_fail "usermgr testpasswd (1)"
  $usrmgr testpasswd labrat "$RANDOM$RANDOM$zpwd" && atf_fail "usermgr testpasswd (2)"

  $usrmgr del arthur labrat

  users_exists labrat && atf_fail "user_exists(labrat): TRUE" || :
  users_exists arthur && atf_fail "user_exists(arthur): TRUE" || :
}

xatf_init
