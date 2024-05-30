#!/usr/bin/atf-sh

type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/common.sh

include -1 urlencode.sh

xt_syntax() {
  : =descr "verify syntax..."

  (
    set -euf -o pipefail
    urlencode abcdkf
    urldecode lakdjfs
    urlencode "$(dd if=/dev/urandom bs=128 count=1 | tr '\0' '\1')"
    echo ''
  ) || atf_fail "Failed compiled"

}

xt_encoding() {
  [ x"$(urlencode "https://www.notarealurl.com?id=50&name=namestring")" \
	= x"https%3A%2F%2Fwww.notarealurl.com%3Fid%3D50%26name%3Dnamestring" ] \
	|| atf_fail "Fail#1"
  [ x"$(urlencode "bar")" \
	= x"bar" ] \
	|| atf_fail "Fail#2"
  [ x"$(urlencode "some=weird/value")" \
	= x"some%3Dweird%2Fvalue" ] \
	|| atf_fail "Fail#3"
  # Support UTF-8 not there!
  #~ [ x"$(urlencode "Hello Günter")" \
	#~ = x"Hello%20G%C3%BCnter" ] \
	#~ || atf_fail "Fail#4"
  :
}

xt_decoding() {
  set -x
  [ x"$(urldecode "https%3A%2F%2Fwww.notarealurl.com%3Fid%3D50%26name%3Dnamestring")" \
	= x"https://www.notarealurl.com?id=50&name=namestring" ] \
	|| atf_fail "Fail#1"
  [ x"$(urldecode "bar")" \
	= x"bar" ] \
	|| atf_fail "Fail#2"
  [ x"$(urldecode "some%3Dweird%2Fvalue")" \
	= x"some=weird/value" ] \
	|| atf_fail "Fail#3"
  # Support UTF-8 not there!
  #~ [ x"$(urlencode "Hello Günter")" \
	#~ = x"Hello%20G%C3%BCnter" ] \
	#~ || atf_fail "Fail#4"
  :
}


xatf_init

