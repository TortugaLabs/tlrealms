#!/bin/sh
#
# Functions to extend ATF
#
[ -z "${XTF_OUTPUT_TRACE:-}" ] && XTF_OUTPUT_TRACE=false

xatf_auto_init_test_cases() {
  local i fn="atf_init_test_cases() {"
  for i in $(declare -F | awk '$1 == "declare" && $2 == "-f" && $3 ~ /_head$/ && $3 !~ /^_atf_/ { print $3 }' | sed -e 's/_head$//')
  do
    fn="$fn
	atf_add_test_case $i"
  done
  fn="$fn
      }"
  eval "$fn"
}
xatf_init() {
  local i fn
  for i in $(declare -F | awk '$1 == "declare" && $2 == "-f" && $3 ~ /^xt_/ { print $3 }')
  do
    atf_test_case $i
    fn="${i}_head() { :;
	$(declare -f $i \
	| awk '$1 == ":" && $2 ~ /^=/ {
	  $1 = "atf_set";
	  $2 = "'\''" substr($2,2) "'\''";
	  print
	}')
	}
	${i}_body() {
		${i} \"\$@\"
	}"
    eval "$fn"
  done
  #~ (declare -F ; declare -f xx_mytest_case_body)> log
  xatf_auto_init_test_cases
}

#
# test helper functions
#
xtf() {
  set -euf -o pipefail
  "$@"
}

xtf_rc() {
  (
    if $XTF_OUTPUT_TRACE ; then
      exec 1>&2
    else
      exec >/dev/null 2>&1
    fi
    set -euf -o pipefail
    "$@"
  )
  echo "$?"
}
xtf_ck() {
  echo "$* => $(xtf "$@")" 1>&2
}
