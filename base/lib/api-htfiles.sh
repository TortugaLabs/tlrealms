#!/bin/sh
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#*#####################################################################
## Functions to work with httpd files
#*####################################################################

include -1 api-users.sh
include -1 api-groups.sh
include -1 fixfile.sh

htfile_gen_pwds() {
  ## Generate password files files
  ## # USAGE
  ##   htfile_gen_pwds [pwd-type] [output] [fixfile options]
  ## # OPTIONS
  ## * pwd-type: One of htpasswd or htdigest (defaults to htpasswd)
  ## # DESC
  ## Generate pwd file based on the specified password type
  [ $# -eq 0 ] && set - htpasswd

  local u i j
  (
    for u in $(users_list)
    do
      i="$(users_passwd "$u" "$1")"
      [ -z "$i" ] && continue

      echo "$u:$i"
    done
  ) | (
    [ $# -eq 1 ] && exec cat
    [ x"$2" = x"-" ] && exec cat
    output="$2" ; shift 2
    fixfile "$@" "$output" || :
  )
}

htfile_gen_grps() {
  ## Generate group files
  ## # USAGE
  ##   htfile_gen_grps [output] [fixfile options]
  ## # DESC
  ## Generate apache style group files

  local g
  (
    for g in $(groups_list)
    do
      echo "$g: $(groups_members $g)"
    done
  ) | (
    [ $# -eq 0 ] && exec cat
    [ x"$1" = x"-" ] && exec cat
    output="$1" ; shift
    fixfile "$@" "$output" || :
  )
}

nginx_gen_grps() {
  ## Simulate groups in nginx
  ## # USAGE
  ##   nginx_gen_groups [pwdtype] [output-dir] [fixfile options]
  ## # DESC
  ## Since nginx doesn't support group files
  ## this will generate one file per group containing the
  ## passwords of users belonging to that group
  [ $# -eq 0 ] && set - htpasswd

  local u i j g
  for g in $(groups_list)
  do
    (
      for u in $(groups_members $g)
      do
        i="$(users_passwd "$u" "$1")"
        [ -z "$i" ] && continue
        echo "$u:$i"
      done
    ) | (
      if ([ $# -eq 1 ] || [ x"$2" = x"-" ]) ; then
        while read ln
        do
          echo "$g:$ln"
        done
      else
        output="$2/$g.$1" ; shift 2
        fixfile "$@" "$output" || :
      fi
    )
  done
}

#####################################################################

htfile_gen_map() {
  ## Generate map files
  ## # USAGE
  ##   htfile_gen_map {map-type} [output] [fixfile options]
  ## # OPTIONS
  ## * map-type : should be one of:
  ##   * ident_sso
  ##   * social_logins
  ## # DESC
  ## Generate mapping file based on the specified map attribute
  [ $# -eq 0 ] && return 1

  local u i j
  (
    for u in $(users_list)
    do
      i="$(users_map "$u" "$1")"
      [ -z "$i" ] && continue
      for j in $i
      do
        echo "$j:$u"
      done
    done
  ) | (
    [ $# -eq 1 ] && exec cat
    [ x"$2" = x"-" ] && exec cat
    output="$2" ; shift 2
    fixfile "$@" "$output" || :
  )

}



#~ echo ==== in ====
#~ shpwd_acct_validate -i root dbus avahi polkitd chrony rpc < /etc/passwd
#~ echo ==== '><' ====
#~ shpwd_acct_validate -x root dbus avahi polkitd chrony rpc < /etc/passwd

#~ shpwd_xid_filter -i </etc/passwd
#~ echo = $cond
#~ shpwd_xid_filter -i --min=50 </etc/passwd
#~ echo =
#~ shpwd_xid_filter -i --min=50 --max=2000 </etc/passwd
#~ echo =
#~ shpwd_xid_filter -i --max=2000 </etc/passwd
#~ echo =
#~ shpwd_xid_filter -x </etc/passwd
#~ echo =
#~ shpwd_xid_filter -x --min=50 </etc/passwd
#~ echo =
#~ shpwd_xid_filter -x --min=50 --max=2000 </etc/passwd
#~ echo =
#~ shpwd_xid_filter -x --max=2000 </etc/passwd
#~ echo =

