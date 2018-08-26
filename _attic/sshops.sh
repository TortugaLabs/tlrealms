#!/bin/sh
mydir=$(dirname $(readlink -f "$0"))
export PATH=$PATH:$mydir/../scripts

set -euf -o pipefail

. $mydir/lib.sh

### START-INCLUDE-SECTION ###

ssh_newkey() {
  local data="$1" user="$2" pwd_in;shift 2
  if [ ! -f "$data/users.d/$user.cfg" ] ; then
    echo "$user does not exist!" 1>&2
    return 1
  fi
  if [ $# -eq 0 ] ; then
    echo -n "Password: " 1>&2
    read pwd_in
  else
    local pwd_in="$*"
  fi
  
  tmpkey=$(mktemp -d)
  if (
    ssh-keygen -q -N "$pwd_in" -C "user:$user" -f "$tmpkey/id_rsa"
    ssh_package "$data/users.d/$user.ssh.tar" "$tmpkey"
  ) ; then
    rc=0
  else
    rc=$?
  fi
  rm -rf "$tmpkey"
}



#~ u_chpasswd() {
  #~ local data="$1" user="$2" pwd_old pwd_new;shift 2

  #~ if [ ! -f "$data/users.d/$user.cfg" ] ; then
    #~ echo "$user does not exist!" 1>&2
    #~ return 1
  #~ fi
  #~ if [ $# -eq 0 ] ; then
    #~ echo -n "Current Password: " 1>&2
    #~ read pwd_old
  #~ else
    #~ local pwd_old="$1" ; shift
  #~ fi
  #~ if [ $# -eq 0 ] ; then
    #~ echo -n "New Password: " 1>&2
    #~ read pwd_new
  #~ else
    #~ local pwd_new="$1" ; shift
  #~ fi
  #~ if [ ! -f "$data/users.d/$user.cfg" ] ; then
    #~ echo "$user: Missing private key!" 1>&2
    #~ return 1
  #~ elif  ssh-keygen -p -P "$pwd_old" -N "$pwd_new" -f "$data/users.d/$user.key" ; then
    #~ u_passwd "$data" "$user" "$pwd_new"
  #~ fi
#~ }

  



### END-INCLUDE-SECTION ###

ssh_newkey "../sample" hella
