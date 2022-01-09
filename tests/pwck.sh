#!/usr/bin/atf-sh

if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi
. $(atf_get_srcdir)/common.sh
include -1 api-polrun.sh

xt_pwck() {
  : =descr "Password checks"

  (xtf polrun_pwck 12345678) || atf_fail "no-policy"
  (
    password_policy() {
      minlen 8
      maxlen 16
    }
    xtf polrun_pwck 1234 && exit 1
    xtf polrun_pwck 12345678901234567890123 && exit 2
    xtf polrun_pwck 12345678 || exit 3
    xtf polrun_pwck 1234567890123456 || exit 4
    xtf polrun_pwck 1234567890 || exit 5
    exit 0
  ) || atf_fail "pwlen:$?"

  (
    password_policy() {
      charset A-Z
      charset a-z
      charset 0-9
      only_valid_sets
    }
    xtf polrun_pwck ABCabc0123 || exit 1
    xtf polrun_pwck ABC0123 && exit 2
    xtf polrun_pwck abc0123 && exit 3
    xtf polrun_pwck ABCabcd && exit 4
    xtf polrun_pwck "ABCabc123!@#" && exit 5
    exit 0
  ) || atf_fail "charsets:$?"

  (
    password_policy() {
      minlen 8
      charset A-Z
      charset a-z
      charset 0-9'-!@#$%^&*()_+-='\\'[]{}|''"'"'"';:,./<>?'
      only_valid_sets 
    }
    xtf polrun_pwck Aeiou343 || exit 1
  ) || atf_fail "full-policy:$?"
}

xatf_init
