#!/usr/bin/atf-sh

type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/common.sh

include -1 randpw.sh

xt_randpw_len() {
  : =descr "check is generated passwords meet lenght criteria"
  local q p
  for q in $(seq 4 4 128)
  do
    p="$(randpw $q)"
    [ $q -eq "$(expr length "$p")" ] || atf_fail "$q: $p length error"
  done
}

xt_randpw_rando() {
  : =descr "Randomness test"
  local a b q
  for q in $(seq 4 32)
  do
    a="$(randpw "$q")"
    b="$(randpw "$q")"
    [ "$a" = "$b" ] && atf_fail "$a == $b"
    :
  done
}


xatf_init
