#!/bin/sh

#
# Extend the ATF stuff
#
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

##################################################################

if [ -d $(atf_get_srcdir)/../.ashlib ] ; then
  export ASHLIB=$(atf_get_srcdir)/../.ashlib
  . $ASHLIB/ashlib.sh
else
  exit 1
fi
export ASHLIB_PATH=$(atf_get_srcdir)/../base/lib:$ASHLIB
