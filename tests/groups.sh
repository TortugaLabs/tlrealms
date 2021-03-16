#!/usr/bin/atf-sh

if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi

. $(atf_get_srcdir)/common.sh
. $(atf_get_srcdir)/lib/data.sh

include -1 api-groups.sh


xt_groups_add() {
  : =descr "Create a sample database"

  groups_setup || atf_fail "groups_setup failed"
  return 0
}

xt_groups_read() {
  : =descr "Reading groups data"

  groups_setup || atf_fail "groups_setup failed"
  atf_check_equal 6	$(xtf groups_list | wc -l)

  (xtf groups_exists royals) || atf_fail "groups_exists(royals): FALSE"
  (xtf groups_exists missing) && atf_fail "groups_exists(missing): TRUE"

  atf_check_equal 5001	"$(xtf groups_gid royals)"
  atf_check_equal 5003	"$(xtf groups_gid nobles)"
  atf_check_equal "arthur guinie" \
			"$(xtf groups_members royals)"
  atf_check_equal "arthur galahad gawain guinie kay lancelot morgana percivale" \
			"$(xtf groups_members nobles)"
  atf_check_equal "arthur guinie" \
			"$(xtf groups_members --resolve royals)"
  atf_check_equal "arthur galahad gawain guinie kay lancelot morgana percivale" \
			"$(xtf groups_members --resolve nobles)"
  atf_check_equal "arthur guinie" \
			"$(xtf groups_members --no-resolve royals)"
  atf_check_equal "@knights @royals morgana" \
			"$(xtf groups_members --no-resolve nobles)"

  atf_check_equal "admins nobles royals" \
			"$(xtf groups_usergroups arthur)"
  atf_check_equal "knights nobles" \
			"$(xtf groups_usergroups kay)"
  atf_check_equal "commoners" \
			"$(xtf groups_usergroups sancho)"
  atf_check_equal "admins commoners soldiers" \
			"$(xtf groups_usergroups sid)"
  atf_check_equal "admins nobles royals" \
			"$(xtf groups_usergroups --resolve arthur)"
  atf_check_equal "knights nobles" \
			"$(xtf groups_usergroups --resolve kay)"
  atf_check_equal "commoners" \
			"$(xtf groups_usergroups --resolve sancho)"
  atf_check_equal "admins commoners soldiers" \
			"$(xtf groups_usergroups --resolve sid)"
  atf_check_equal "royals" \
			"$(xtf groups_usergroups --no-resolve arthur)"
  atf_check_equal "knights" \
			"$(xtf groups_usergroups --no-resolve kay)"
  atf_check_equal "admins commoners soldiers" \
			"$(xtf groups_usergroups --no-resolve sid)"
  atf_check_equal "commoners" \
			"$(xtf groups_usergroups --no-resolve sancho)"
}

xt_groups_writes() {
  : =descr "Misc write functions"

  groups_setup || atf_fail "groups_setup failed"

  (xtf groups_exists labrats) && atf_fail "groups_exists(labrats) : TRUE"
  (xtf groups_add labrats) || atf_fail "groups_add(labrats) : FAIL"
  (xtf groups_exists labrats) || atf_fail "groups_exists(labrats) : FALSE"

  atf_check_equal "" "$(xtf groups_members labrats)"
  (xtf groups_members labrats one two three) || atf_fail "groups_members(labrats,members) : FAIL"
  atf_check_equal "one three two" "$(xtf groups_members labrats)"
  (xtf groups_adduser labrats ivan "@royals") || atf_fail "groups_adduser(labrats,ivan) : FAIL"

  atf_check_equal "arthur guinie ivan one three two" \
			"$(xtf groups_members --resolve labrats)"
  atf_check_equal "@royals ivan one three two" \
			"$(xtf groups_members --no-resolve labrats)"

  atf_check_equal 5006 	"$(xtf groups_gid labrats)"
  (xtf groups_gid labrats 7000) || atf_fail "groups_gid(labrats,7000): FAIL"
  atf_check_equal 7000 	"$(xtf groups_gid labrats)"

  (xtf groups_deluser labrats ivan) || atf_fail "grups_deluser(labrats,ivan): FAIL"
  atf_check_equal "arthur guinie one three two" "$(xtf groups_members labrats)"
  (xtf groups_deluser labrats "@royals") || atf_fail "groups_deluser(labrats,@royals): FAIL"
  atf_check_equal "one three two" "$(xtf groups_members labrats)"

  atf_check_equal "royals" "$(xtf groups_usergroups --no-resolve arthur)"
  atf_check_equal "arthur guinie" "$(xtf groups_members --no-resolve royals)"
  (xtf groups_deluser '#' arthur) || atf_fail "groups_deluser(#,arthur): FAIL"
  atf_check_equal "" "$(xtf groups_usergroups --no-resolve arthur)"
  atf_check_equal "guinie" "$(xtf groups_members --no-resolve royals)"

  atf_check_equal "admins commoners soldiers" "$(xtf groups_usergroups --no-resolve sid)"
  atf_check_equal "@royals sid" "$(xtf groups_members --no-resolve admins)"
  atf_check_equal "sancho sid" "$(xtf groups_members --no-resolve commoners)"
  atf_check_equal "sid" "$(xtf groups_members --no-resolve soldiers)"
  (xtf groups_deluser '#' sid) || atf_fail "groups_deluser(#,sid): FAIL"
  atf_check_equal "" "$(xtf groups_usergroups --no-resolve sid)"
  atf_check_equal "@royals" "$(xtf groups_members --no-resolve admins)"
  atf_check_equal "sancho" "$(xtf groups_members --no-resolve commoners)"
  atf_check_equal "" "$(xtf groups_members --no-resolve soldiers)"

  (xtf groups_del labrats) || atf_fail "groups_del(labrats) : FAIL"
  (xtf groups_exists labrats) && atf_fail "groups_exists(labrats) : TRUE"
  :
}

xt_groups_grdels() {
  : =descr "Recursive group deletes"

  groups_setup || atf_fail "groups_setup failed"

  atf_check_equal "@knights @royals morgana" "$(xtf groups_members --no-resolve nobles)"
  atf_check_equal "@royals sid" "$(xtf groups_members --no-resolve admins)"
  (xtf groups_del royals) || atf_fail "groups_del(royals): FAIL"
  atf_check_equal "@knights morgana" "$(xtf groups_members --no-resolve nobles)"
  atf_check_equal "sid" "$(xtf groups_members --no-resolve admins)"
  :
}


xatf_init
