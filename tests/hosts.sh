#!/usr/bin/atf-sh

if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi

. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh

include -1 api-hosts.sh
include -1 api-users.sh

xt_hosts_add() {
  : =descr "Create a sample database"
  hosts_setup || atf_fail "hosts_setup"
}

xt_hosts_rw() {
  : =descr "Reading users data"

  hosts_setup || atf_fail "hosts_setup"

  (xtf hosts_exists sys1) || atf_fail "hosts_exists(sys1) : NOT exsits"
  (xtf hosts_exists zys1) && atf_fail "hosts_exists(zys1) : exists"
  (xtf hosts_new zys1 > /dev/null) || atf_fail "hosts_new(zys1)"
  (xtf hosts_exists zys1) || atf_fail "hosts_exists(zys1) : NOT exists"
  (xtf hosts_del zys1) || atf_fail "hosts_del(zys1)"
  (xtf hosts_exists zys1) && atf_fail "hosts_exists(zys1) : exists"

  (xtf hosts_cfg zys1 value) && atf_fail "hosts_cfg(zys1):1"
  (xtf hosts_cfg zys1 key value) && atf_fail "hosts_cfg(zys1):2"
  (xtf hosts_cfg sys1 value) || atf_fail "hosts_cfg(sys1):1"
  (xtf hosts_cfg sys1 key value) || atf_fail "hosts_cfg(sys1):2"
  (xtf hosts_cfg sys1 key '') || atf_fail "hosts_cfg(sys1):2"
  (xtf hosts_cfg -v sys1) || atf_fail "hosts_cfg(sys1):3"
  atf_check_equal 2	$(xtf hosts_cfg -v sys1 | wc -w)

  (xtf hosts_new zys1 | tar ztvf -) || atf_fail "hosts_add(zys1):2"
  (xtf hosts_cfg zys1 rand "$(users_pwgen 64)") || atf_fail "hosts_cfg(zys1,uuid) write"
  atf_check_equal 65	"$(xtf hosts_cfg zys1 rand | wc -c)"
  (xtf hosts_del zys1) || atf_fail "hosts_del(zys1):2"

  atf_check_equal 6	$(xtf hosts_list | wc -l)
  atf_check_equal 2	$(xtf hosts_pk sys1 ssh-rsa | wc -w)
  atf_check_equal 3	$(xtf hosts_pk -v sys2 ssh-ed25519 | wc -w)

  atf_check_equal 4	$(xtf hosts_pk -v sys1 | wc -l)
  atf_check_equal 12	$(xtf hosts_pk -v sys2 | wc -w)

  (xtf hosts_namechk '*junk*') && atf_fail "hosts_namechk(*junk*)"
  (xtf hosts_namechk mEaN-s45) || atf_fail "hosts_namechk(mean-s45)"
}

xatf_init





