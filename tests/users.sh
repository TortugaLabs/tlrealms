#!/usr/bin/atf-sh

# TODO: add testcase for users_ckshell

if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi

. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh

include -1 api-users.sh

xt_users_add() {
  : =descr "Create a sample database"

  users_setup || atf_fail "users_setup failed"
  return 0
}

xt_users_read() {
  : =descr "Reading users data"

  users_setup || atf_fail "users_setup failed"
  atf_check_equal 10	$(xtf users_list | wc -l)
  atf_check_equal 501	"$(xtf users_cfg arthur uid)"
  atf_check_equal 501	"$(xtf users_cfg arthur gid)"
  atf_check_equal "gecos Arthur Pendragon"	"$(xtf users_cfg -v arthur gecos)"
  atf_check_equal 13	"$(xtf users_cfg -v arthur | wc -w)"
  atf_check_equal 6	"$(xtf users_cfg -v arthur | wc -l)"

  (xtf users_cfg morgana sp_min 1 sp_max 999 sp_warn 8 sp_inact 30) \
	|| atf_fail "users_cfg(morgana)"

  atf_check_equal 9999	"$(xtf users_cfg arthur sp_max)"
  atf_check_equal 999	"$(xtf users_cfg morgana sp_max)"

  (xtf users_cfg morgana sp_max '') \
      || atf_fail "users_cfg(morgana[sp_max] -> delete)"

  atf_check_equal 9999	"$(xtf users_cfg morgana sp_max)"

  atf_check_equal ""	"$(xtf users_cfg -v arthur sp_warn)"
  atf_check_equal "sp_warn 8"	"$(xtf users_cfg -v morgana sp_warn)"
  atf_check_equal ""	"$(xtf users_cfg lancelot something)"

  (xtf users_exists sid) || atf_fail "users_exists(sid) should exist"
  (xtf users_exists no-one) && atf_fail "users_exists(no-one) does not exist"
  :
}

xt_users_writes() {
  : =descr "Misc write functions"

  users_setup || atf_fail "users_setup failed"
  (xtf users_exists labrat) && atf_fail "users_exists(labrat) : NOT exists"
  (xtf users_add labrat) || atf_fail "users_add(labrat) failed"
  (xtf users_exists labrat) || atf_fail "users_exists(labrat) : exists"
  (xtf users_del labrat) || atf_fail "users_del(labrat) failed"
  (xtf users_exists labrat) && atf_fail "users_exists(labrat) : NOT exists"

  (xtf users_add a-brat) || atf_fail "users_add(a-brat) failed"
  (xtf users_map a-brat ident_sso "$(users_pwgen 64)") || atf_fail "users_map(a-brat)"
  atf_check_equal 65	"$(xtf users_map a-brat ident_sso | wc -c)"
  atf_check_equal "-rw-------"	"$(stat -c '%A' "$users_db/a-brat.map")"
}

xt_users_passwd() {
  : =descr "Password checks"

  for mode in --des --md5 --sha256 --sha512 --htpasswd
  do
    local inpw="$(users_pwgen 16)"
    local enpw="$($TLR_LIB/mkpasswd $mode "$inpw")" || atf_fail "mkpasswd($mode,$inpw)"
    local ckpw="$($TLR_LIB/mkpasswd --salt="$enpw" "$inpw")" || atf_fail "mkpasswd($enpw)"
    #~ echo inpw=$inpw
    #~ echo enpw=$enpw
    #~ echo ckpw=$ckpw
    atf_check_equal "$ckpw" "$enpw"
  done

  users_setup || atf_fail "users_setup failed"
  (xtf users_add labrat) || atf_fail "users_add(labrat) failed"
  atf_check_equal 6	"$(xtf users_passwd -v labrat | wc -w)"

  local tpwd="$(users_pwgen 16)"
  local wpwd="$tpwd"

  # Make sure that the wrong password is wrong!
  while [ x"$tpwd" = x"$wpwd" ]
  do
    wpwd="$(users_pwgen 16)"
  done

  (xtf users_passwd --set "labrat" "$tpwd") || atf_fail "unable to set password"
  (xtf users_pwck "labrat" "$tpwd") || atf_fail "correct pwck failed"
  (xtf users_pwck "labrat" "$wpwd") && atf_fail "wrong pwck failed"

  atf_check_equal "-rw-------"	"$(stat -c '%A' "$users_db/labrat.pwd")"
}

xatf_init
