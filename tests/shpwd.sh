#!/usr/bin/atf-sh
#
# Test shadow passwords
#
if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi
. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh
include -1 api-shpwd.sh

xt_shpwd_t() {
  : =descr "Test shadow suite support"

  groups_setup || atf_fail "groups_setup failed"
  users_setup || atf_fail "users_setup failed"
  etcdat_setup || atf_fail "etcdat_setup failed"

  local etc=${TLR_ETC:-/etc} k
  
  # Test xid_filter
  k=$(shpwd_xid_filter -x --min=500 --max=65500 < $etc/group | wc -l)
  [ $k -eq 0 ] && atf_fail "shpwd_xid_filter"

  # Test user group generation
  k=$(shpwd_gen_usrgrps|wc -l)
  [ $k -eq 0 ] && atf_fail "shpwd_gen_usrgrps"

  # Test groups generation
  k=$(shpwd_gen_grps | wc -l)
  [ $k -eq 0 ] && atf_fail "shpwd_gen_grps"

  # Test gshadow generation
  local prev=$(wc -l < $etc/group)
  k=$(shpwd_gen_gshadow < $etc/group | wc -l)
  [ $k -ne $prev ] && atf_fail "shpwd_gen_gshadow"

  # Test main entry point
  shpwd_gen_groupfiles --group --gshadow
  k=$(wc -l < $etc/group)
  [ $k -ne $(wc -l < $etc/gshadow) ] && atf_fail "shpwd_gen_groupfiles:1"
  [ $prev -eq $k ] && atf_fail "shpwd_gen_groupfiles:2"

  shpwd_gen_groupfiles --group --shadow
  [ $k -ne $(wc -l <$etc/group) ] && atf_fail "shpwd_gen_groupfiles:3"

  # Test file merging
  k=$(shpwd_merge_files | wc -l)
  [ $k -ne $(wc -l < $etc/shadow) ] && atf_fail "shpwd_merge_files:1"
  [ $k -ne $(wc -l < $etc/passwd) ] && atf_fail "shpwd_merge_files:2 - $k"

  # Test xid filter
  k=$(shpwd_xid_filter -x --min=500 --max=65500 < $etc/passwd | wc -l)
  [ $k -eq 0 ] && atf_fail "shpwd_xid_filter"

  # Test user data generation
  k=$(shpwd_gen_userdata | wc -l)
  [ $k -eq 0 ] && atf_fail "shpwd_gen_userdata"

  k=$(wc -l < $etc/passwd)
  shpwd_gen_userfiles --passwd --shadow
  [ $k -eq $(wc -l < $etc/passwd) ] && atf_fail "shpwd_gen_userfiles:1"
  [ $k -eq $(wc -l < $etc/shadow) ] && atf_fail "shpwd_gen_userfiles:2"
  k=$(wc -l < $etc/passwd)
  shpwd_gen_userfiles --passwd --shadow
  [ $k -ne $(wc -l < $etc/passwd) ] && atf_fail "shpwd_gen_userfiles:3"
  [ $k -ne $(wc -l < $etc/shadow) ] && atf_fail "shpwd_gen_userfiles:4"

  :
  
}


xatf_init
