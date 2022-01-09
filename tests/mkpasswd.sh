#!/usr/bin/atf-sh
#
# Test password generation scripts
#
if ! type atf_get_srcdir >/dev/null 2>&1 ; then
  atf_get_srcdir() { pwd; }
fi
. $(atf_get_srcdir)/common.sh

mkpasswd="python3 $TLR_LIB/mkpasswd.py"


xt_pwd_check() {
  : =descr "Make sure the script exists"
  $mkpasswd -h
}

xt_pwd_enc() {
  : =descr "Check different password encodings"

  local cleartext="$RANDOM$RANDOM$RANDOM$$"

  c=0
  for enc in --des --md5 --sha256 --sha512 --htpasswd
  do
    cypher=$($mkpasswd $enc $cleartext)
    salted=$($mkpasswd -S "$cypher" "$cleartext")
    echo : $cypher- $salted
    if [ x"$cypher" = x"$salted" ] ; then
      echo $enc $cleartext '->' $cypher : $salted "(OK)"
    else
      echo $enc $cleartext '->' $cypher : $salted "(BAD)"
      c=$(expr $c + 1)
    fi
  done
  return $c
  
}

xt_pw_digest() {
  : =descr "Check digest authentication"
  local cleartext="$RANDOM$RANDOM$RANDOM$$"

  local cypher=$($mkpasswd --htdigest 'the-kingdom' 'the-king' "$cleartext")

  echo "$cleartext : $cypher"
  [ -n "$cypher" ]
}

xatf_init
