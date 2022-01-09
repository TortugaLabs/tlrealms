#!/usr/bin/atf-sh

if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi
. $(atf_get_srcdir)/common.sh
include -1 api-plist.sh

db=$(mktemp -d)
trap "rm -rf $db" EXIT

plist_setup() {
  exts=".dat .cfg"
  (
    exec 1>&2
    set -euf -o pipefail
    plst_set "box1" "$db" .dat one 1box1 two 2box1 three 3box1
    plst_set "box2" "$db" .cfg uno 1box1sp dos 2box1sp tres 3box1sp
    for i in $(seq 2 4)
    do
      plst_set "box$i" "$db" .dat qq1 $RANDOM qq2 $RANDOM qq3 $RANDOM
    done

    for i in $(seq 5 7)
    do
      plst_set "box$i" "$db" .dat qq1 $RANDOM qq2 $RANDOM qq3 $RANDOM
    done
  )
  return $?
}

xt_plist_set() {
  : =descr "test setting property lists"

  plist_setup || atf_fail "plist_setup failed"
  return 0
}

xt_plist_get() {
  : =descr "get kv from property lists"

  plist_setup || atf_fail "plist_setup failed"

  atf_check_equal "1box1"	"$(xtf plst_get "box1" "$db" .dat one four)"
  atf_check_equal "uno 1box1sp"	"$(xtf plst_get -v "box2" "$db" .cfg uno cuatro)"
}

xt_plist_lst() {
  : =descr "List property list"

  plist_setup || atf_fail "plist_setup failed"
  atf_check_equal 7	"$(xtf plst_list "$db" $exts | wc -l)"
}

xt_plist_chk() {
  : =descr "Check if keys exist or not"

  plist_setup || atf_fail "plist_setup failed"
  plst_exists nobox "$db" $exts && atf_fail "nobox should NOT exist"
  local box
  for box in box1 box2 box5
  do
    plst_exists "$box" "$db" $exts || atf_fail "$box should exist"
  done
}

xt_plist_kvps() {
  : =descr "Additional tests...."

  plist_setup || atf_fail "plist_setup failed"

  plst_set "box1" "$db" .dat mega junk
  plst_set "box1" "$db" .dat mega ''
  [ -n "$(plst_get "box1" "$db" .dat mega)" ] && atf_fail "box1:mega should be empty"
  for tron in abc cba dba
  do
    plst_set "box1" "$db" .dat mega $tron
    atf_check_equal "$tron"	"$(xtf plst_get "box1" "$db" .dat mega)"
  done

  plst_set "box1" "$db" .dat mega
  [ -n "$(plst_get "box1" "$db" .dat mega)" ] && atf_fail "box1:mega should be empty"

  atf_check_equal 3	$(xtf plst_get "box1" "$db" .dat | wc -l)
  atf_check_equal 3	$(xtf plst_get -v "box1" "$db" .dat | wc -l)
}


xatf_init
