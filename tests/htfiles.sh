#!/usr/bin/atf-sh
#
# Test ht file generation
#
if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi
. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh
include -1 api-htfiles.sh

xt_htfiles_t() {
  : =descr "Test http file support"

  groups_setup || atf_fail "groups_setup failed"
  users_setup || atf_fail "users_setup failed"

  [ $(xtf htfile_gen_pwds htpasswd | wc -l) -gt 0 ] || atf_fail "htfile_gen_pwds:1"
  [ $(xtf htfile_gen_pwds htdigest | wc -l) -gt 0 ] || atf_fail "htfile_gen_pwds:2"
  (xtf htfile_gen_pwds htdigest $TLR_LOCAL/htdigest.$$) || atf_fail "htfile_gen_pwds:3"
  (xtf htfile_gen_pwds htpasswd $TLR_LOCAL/htpasswd.$$ --mode=0600) || atf_fail "htfile_gen_pwds:4"
  [ $(stat -c '%a' $TLR_LOCAL/htpasswd.$$) -eq 600 ] || atf_fail "htfile_gen_pwds:5"

  [ $(xtf htfile_gen_grps | wc -l) -gt 0 ] || atf_fail "htfile_gen_grps:1"
  (xtf htfile_gen_grps $TLR_LOCAL/groups.1) || atf_fail "htfile_gen_grps:2"
  (xtf htfile_gen_grps $TLR_LOCAL/groups.2 --mode=0600) || atf_fail "htfile_gen_grps:3"
  [ $(stat -c '%a' $TLR_LOCAL/groups.2) -eq 600 ] || atf_fail "htfile_gen_grps:4"

  [ $(xtf nginx_gen_grps htpasswd | wc -l) -gt 0 ] || atf_fail "nginx_gen_grps:1"
  [ $(xtf nginx_gen_grps htdigest | wc -l) -gt 0 ] || atf_fail "nginx_gen_grps:2"
  mkdir -p $TLR_LOCAL/nginx.d
  (xtf nginx_gen_grps htpasswd $TLR_LOCAL/nginx.d) || atf_fail "nginx_gen_grps:3"
  ls -l $TLR_LOCAL/nginx.d

  [ $(xtf htfile_gen_map ident_sso | wc -l) -gt 0 ] || atf_fail "htfile_gen_map:1"
  [ $(xtf htfile_gen_map social_logins | wc -l) -gt 0 ] || atf_fail "htfile_gen_map:2"
  (xtf htfile_gen_map ident_sso $TLR_LOCAL/ident_sso.map) || atf_fail "htfile_gen_map:3"
  (xtf htfile_gen_map social_logins $TLR_LOCAL/social.map --mode=0600) || atf_fail "htfile_gen_map:4"

}

xt_htfiles_cmd() {
  : =descr "Test http file gen commands"

  groups_setup || atf_fail "groups_setup failed"
  users_setup || atf_fail "users_setup failed"

  local genfile="$TLR_BASE/bin/tlr genfiles"

  [ $($genfile htpasswd | wc -l) -gt 0 ] || atf_fail "cmd:htpasswd:1"
  $genfile htpasswd --mode=0600 $TLR_LOCAL/htpasswd.$$
  [ $(stat -c '%a' $TLR_LOCAL/htpasswd.$$) -eq 600 ] || atf_fail "cmd:htpasswd:2"

  [ $($genfile htdigest | wc -l) -gt 0 ] || atf_fail "cmd:htdigest:1"
  $genfile htdigest --mode=0600 $TLR_LOCAL/htdigest.$$
  [ $(stat -c '%a' $TLR_LOCAL/htdigest.$$) -eq 600 ] || atf_fail "cmd:htdigest:2"

  [ $($genfile htgroup | wc -l) -gt 0 ] || atf_fail "cmd:htgroup:1"
  $genfile htgroup --mode=0600 $TLR_LOCAL/htgroup.$$
  [ $(stat -c '%a' $TLR_LOCAL/htgroup.$$) -eq 600 ] || atf_fail "cmd:htgroup:2"

  $genfile nginx-grps $TLR_LOCAL/nginx.d
  [ $(ls -l $TLR_LOCAL/nginx.d | wc -l) -gt 2 ] || atf_fail "cmd:nginx-grps:1"

  [ $($genfile ident-sso | wc -l) -gt 0 ] || atf_fail "cmd:ident-map:1"
  $genfile ident-sso --mode=0600 $TLR_LOCAL/ident-map.$$
  [ $(stat -c '%a' $TLR_LOCAL/ident-map.$$) -eq 600 ] || atf_fail "cmd:ident-map:2"

  [ $($genfile social-map | wc -l) -gt 0 ] || atf_fail "cmd:social-map:1"
  $genfile social-map --mode=0600 $TLR_LOCAL/social-map.$$
  [ $(stat -c '%a' $TLR_LOCAL/social-map.$$) -eq 600 ] || atf_fail "cmd:social-map:2"

}

xatf_init
