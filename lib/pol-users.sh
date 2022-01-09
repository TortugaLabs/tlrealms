#!/bin/sh

userspol_pwdfiles() {
  find "$TLR_DATA/users.d" -mindepth 1 -maxdepth 1 -type f -name '*.pwd' | while read f
  do
    c=$(echo "$f" | sed -e 's/\.pwd$/.cfg/')
    [ -f "$c" ] && echo $f
  done
}

gen_pwdfile() {
  local ff mode="$1" ; shift
  for ff in "$@"
  do
    local username=$(basename "$ff" .pwd)
    local pwd=$(awk -vOFS=: -F: '$1 == "'"$mode"'" { $1 = "" ; print }' < "$ff")
    echo "$username$pwd"
  done
}

gen_shadow() {
  local f
  
  # make sure we have reasonable defaults
  : ${sp_min:=0} ${sp_max:=99999} ${sp_warn:=7} ${sp_inact:=}
  
  for f in "$@"
  do
    local \
	c=$(echo "$f" | sed -e 's/\.pwd$/.cfg/') \
	user="$(basename "$f" .pwd)" \
	pwdchg=$(expr $(date -r "$f" +%s) / 86400) \
	pwddat=$(awk -vOFS=: -F: '$1 == "unix" { print $2 }' < "$f")
    (
      . "$c"
      echo "$uid:$user:$pwddat:$pwdchg:$sp_min:$sp_max:$sp_warn:$sp_inact::"
    )
  done
}

gen_etcpasswd() {
  local f
  
  for f in "$@"
  do
    local \
	c=$(echo "$f" | sed -e 's/\.pwd$/.cfg/') \
	user="$(basename "$f" .pwd)" \
	uid="" gid="" gecos="unknown" pw_dir="/" pw_shell="/sbin/nologin"
    (
      . "$c"
      echo "$user:x:$uid:$gid:$gecos:$pw_dir:$pw_shell"
    )
  done
}

gen_usersgroup() {
  local gr_name="$1" gr_gid="$2" ; shift 2
  
  local f q="" all_users=""
  for f in "$@"
  do
    local \
	c=$(echo "$f" | sed -e 's/\.pwd$/.cfg/') \
	user="$(basename "$f" .pwd)"
    eval $(. "$c" ; echo c_uid=$uid ";" c_gid=$gid)
    if [ $c_uid -eq $c_gid ] ; then
      echo "$user:x:$c_gid:"
    fi
    all_users="$all_users$q$user"
    q=","
  done
  echo "$gr_name:x:$gr_gid:$all_users"
}


#~ gen_pwds htpasswd *.pwd
#~ gen_pwds htdigest *.pwd
#~ gen_shadow *.pwd
#~ gen_etcpasswd *.pwd > passwd.txt
#~ new_user ../sample
#~ def_passwd
#~ u_chpasswd ../sample hella



