#!/bin/sh
#
## Functions to extend ATF
##
## These functions are used for convenience to enhance
## [atf](https://github.com/jmmv/atf) libraries to be used
## with [kyua](https://github.com/jmmv/kyua/) testing engine.
##
#
[ -z "${XTF_OUTPUT_TRACE:-}" ] && XTF_OUTPUT_TRACE=false

xatf_auto_init_test_cases() {
  ## Create `atf_init_test_cases`
  ## # USAGE
  ## N/A - used by `xatf_init`
  ## # DESC
  ## This function creates the `atf_init_test_cases` function
  ## that initializes test cases.  It does so by creating a list
  ## of functions and picking the ones that end with `_head`.
  ##
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
  ## Initalize Test cases
  ## # USAGE
  ## xatf_init
  ## # DESC
  ## This function is meant to be called at the end of the shell
  ## script used for testing.
  ##
  ## It will scan for all the defined functions that begin with `xt_`
  ## and it will create the relevant `_head` and `_body` functions.
  ##
  ## Afterwards, it will use `xatf_auto_init_test_cases` to create
  ## the required `atf_init_cases`.
  ##
  ## The `_head` function is created from the main function by
  ## scanning for : =<attr> "value"
  ##
  ## The `_body` function will simply call the `xt_` function.
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
  ## Sets strict `sh` modes and excute command
  ## # USAGE
  ## ( xtf cmd [cmd-args] )
  ## # DESC
  ## Typically this function is meant to be called in a
  ## sub shell, to execute a command with strict settings.
  ##
  set -euf -o pipefail
  "$@"
}

xtf_rc() {
  ## Executes a command with return code as output
  ## # USAGE
  ## xtf_rc cmd
  ## # DESC
  ## Executes a command, and returns the return code (on stdout)
  ##
  ## The actual std output of the command is either discarded or
  ## if `XTF_OUTPUT_TRACE` is `true`, the output is sent to
  ## stderr
  ##
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
  ## Execute command like `xtf` but showing output to stderr
  ## # USAGE
  ## xtf_ck cmd
  ## # DESC
  ## Execute the given command.  The command and its output
  ## are shown on stderr
  echo "$* => $(xtf "$@")" 1>&2
}
