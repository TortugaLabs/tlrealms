#!/usr/bin/atf-sh

type atf_get_srcdir >/dev/null 2>&1 || atf_get_srcdir() { pwd; }
. $(atf_get_srcdir)/common.sh

include -1 ver.sh

xt_gitver() {
  : =descr "Test gitver"

  local randtag=$RANDOM
  (
  	# exec >/dev/null 2>&1
  	set -euf -o pipefail
    mkdir t.gitver
    cd t.gitver
    git init .
    echo $RANDOM > $RANDOM
    git add .
    git commit -m $RANDOM
    git tag -a $randtag -m $RANDOM
    local gv=$(gitver $(pwd))
    echo "randtag: $randtag"
    echo "gv: $gv"
    [ x"$randtag" = x"$gv" ] ||  atf_fail "$gv != $randtag"
  )
  local rc="$?"
  rm -rf t.gitver
  return $rc
}

xatf_init

