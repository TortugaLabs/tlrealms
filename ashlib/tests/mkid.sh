#!/usr/bin/atf-sh

type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/common.sh

include -1 mkid.sh

xt_mkid() {
  : =descr "try random strings with mkid"

  local c p i
  for c in $(seq 1 500)
  do
  	p=$(dd if=/dev/urandom bs=64 count=1 2>/dev/null | tr '\0' '.')
  	i=$(mkid "$p")
  	( xtf local ${i}=true ) || atf_fail "Failed convesions $i"
  done
}

xatf_init
