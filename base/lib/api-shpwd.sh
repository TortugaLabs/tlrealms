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
## Functions to work with shadow passwords
##
## Configurable variables
## - GRNAME_USERS
## - GID_USERS
## - GID_MIN
## - UID_MIN
## - XID_MAX
##
#*####################################################################

include -1 api-users.sh
include -1 api-groups.sh
include -1 fixfile.sh

shpwd_xid_filter() {
  ## Filter out accounts|groups by id
  ## # USAGE
  ##   shpwd_xid_filter [-i|-x] [--min=MIN] [--max=MAX]
  ## # DESC
  ## Will filter out /etc/passwd or /etc/group data from stdin
  ## to stdout
  ##
  ## Use --min or --max to specify the range values to test.
  ## -i will show the values inside that range.
  ## -x will show the values outside that range.
  local mode='<<&&' min='' max=''

  while [ $# -gt 0 ]
  do
    case "$1" in
      --include|-i) mode='<<&&' ;;
      --exclude|-x) mode='>>||' ;;
      --min=*) min=${1#--min=} ;;
      --max=*) max=${1#--max=} ;;
      *) break ;;
    esac
    shift
  done
  local cond=""
  if [ -n "$min" ] ; then
    cond="$min ${mode:0:1} \$3"
  fi
  if [ -n "$max" ] ; then
    [ -n "$cond" ] && cond="$cond ${mode:2:2} "
    cond="$cond\$3 ${mode:1:1} $max"
  fi
  #~ echo "xxxx $cond " 1>&2
  awk -F: "$cond {print}"
}

shpwd_acct_validate1() {
  ## Validate accounts|groups from a list of names
  ## # USAGE
  ##    shpwd_acct_validate [-i|-x] [...]
  ## # DESC
  ## Will filter stdin to stdout, making sure that the names
  ## are in the argument list.
  ##
  ## -i will show matching names.  -x will show non-matching namges
  local mode=''

  while [ $# -gt 0 ]
  do
    case "$1" in
      --include|-i) mode='' ;;
      --exclude|-x) mode='!' ;;
      *) break ;;
    esac
    shift
  done

  local begin="BEGIN {" i
  for i in "$@"
  do
    begin="$begin
		db[\"$i\"] = 1;"
  done
  begin="$begin
	}"
  awk -F: "$begin
		$mode(\$1 in db) { print }"
}

shpwd_acct_validate() {
  ## Validate accounts|groups from a list of names
  ## # USAGE
  ##    shpwd_acct_validate [...]
  ## # DESC
  ## Will filter stdin to stdout, making sure that the names
  ## are in the argument list.
  ##
  ## This version will also sort records according to match the
  ## names in the argument list
  local begin="BEGIN {" i c=1
  for i in "$@"
  do
    begin="$begin
		db[\"$i\"] = $c;"
    c=$(expr $c + 1)
  done
  begin="$begin
	}"
  awk -F: "$begin
		(\$1 in db) { ln[db[\$1]] = \$0 }
		END {
		  for (x = 1; x < $c ; x++) print ln[x];
		}
		"
}

shpwd_gen_users() {
  ## Generate user data
  ## # USAGE
  ##   shpwd_gen_users
  ## # DESC
  ## Generate /etc/passwd like records from the users database
  local u ln fd f d v
  for u in $(users_list)
  do
    ln="$u:x"
    for fd in uid: gid: gecos:unknown pw_dir:/ pw_shell:/sbin/nologin
    do
      f="$(echo "$fd" | cut -d: -f1)"
      d="$(echo "$fd" | cut -d: -f2)"
      v="$(users_cfg "$u" "$f")"
      if [ -z "$v" ] ; then
	[ -n "$d" ] && continue
	v="$d"
      fi
      ln="$ln:$v"
    done
    echo "$ln"
  done
}
shpwd_gen_pwds() {
  ## Generate password data
  ## # USAGE
  ##   shpwd_gen_pwds
  ## # DESC
  ## Generate /etc/shadow like records from the users database
  local u ln uid f
  for u in $(users_list)
  do
    uid="$(users_cfg "$u" uid)"
    [ -z "$uid" ] && continue
    ln="$u:$(users_passwd "$u" "unix")"
    for f in sp_lstchg sp_min sp_max sp_warn sp_inact "" ""
    do
      ln="$ln:$(users_cfg "$u" "$f")"
    done
    echo "$ln"
  done
}
shpwd_gen_usrgrps() {
  ## Generate user related groups
  ## # USAGE
  ##   shpwd_gen_usrgrps
  ## # DESC
  ## Generate /etc/group like records from the users in the
  ## users database.  These are the [user private groups](https://wiki.debian.org/UserPrivateGroups)
  ## and the group containing all users.
  ##
  ## The group containing all users is named using environment
  ## variable GRNAME_USERS and its gid is in environment
  ## variable GID_USERS.
  ##
  local u g all_users="" q=""
  for u in $(users_list)
  do
    g="$(users_cfg "$u" gid)"
    [ -z "$g" ] && continue
    all_users="$all_users$q$u" ; q=","
    echo "$u:x:$g:"
  done
  echo "${GRNAME_USERS:-_users}:x:${GID_USERS:-11000}:$all_users"
}
shpwd_gen_grps() {
  ## Generate groups
  ## # USAGE
  ##   shpwd_gen_grps
  ## # DESC
  ## Generate /etc/group like records from the groups database
  local g gid
  for g in $(groups_list)
  do
    gid=$(groups_gid "$g")
    [ -z "$gid" ] && continue
    echo "$g:x:$gid:$(groups_members $g | tr ' ' ,)"
  done
}
shpwd_gen_gshadow() {
  ## Generate gshadow file
  ## # USAGE
  ##   shpwd_gen_gshadow
  ## # DESC
  ## Reads /etc/group records in stdin and write
  ## /etc/gshado records in stdout.
  awk -F: -vOFS=: '{ $2="!" ; $3="" ; print }'
}

shpwd_gen_userfiles() {
  ## Generate user related shadow files
  ## # USAGE
  ##    [--passwd] [--shadow]
  ## # OPTIONS
  ## * --passwd : specify the /etc/passwd file (or use default)
  ## * --shadow: specify the /etc/shadow file (or use default)
  local \
    etc_passwd="${TLR_ETC}/passwd" \
    etc_shadow="${TLR_ETC}/shadow"

  while [ $# -gt 0 ]
  do
    case "$1" in
      --passwd) etc_passwd="${TLR_ETC}/passwd" ;;
      --passwd=*) etc_passwd="${1#--passwd=}" ;;
      --shadow) etc_shadow="${TLR_ETC}/shadow" ;;
      --shadow=*) etc_shadow="${1#--shadow=}" ;;
      --no-shadow) etc_shadow="" ;;
    *) break ;;
    esac
    shift
  done

  if [ -z "$etc_passwd" ] ; then
    warn "passwd is requred"
    return 39
  fi

  local \
    mgid=${GID_MIN:-5000} \
    muid=${UID_MIN:-500} \
    max=${XID_MAX:-65000}
  local min=$([ $mgid -lt $muid ] && echo $mgid || echo $muid)

  local sys_passwd="$(shpwd_xid_filter -x --min=$min --max=$max < $etc_passwd | sort -n -k3 -t:)"

  local root_user=$(echo "$sys_passwd" | awk -F: '$3 == 0 { print $1 }')
  if [ -z "$root_user" ] ; then
    warn "$etc_passwd: incomplete password files"
    return 53
  fi
  if [ -n "$etc_shadow" ] ; then
    local sys_shadow="$(shpwd_acct_validate $(echo "$sys_passwd" | cut -d: -f1) <$etc_shadow)"
    if [ -z "$(echo "$sys_shadow" | awk -F: '$1 == "'"$root_user"'"')" ] ; then
      warn "$etc_shadow: incomplete shadow file"
      return 68
    fi
  fi

  (
    echo "$sys_passwd"
    shpwd_gen_users | sort
  ) | fixfile --mode=644 "$etc_passwd" || :
  if [ -n "$etc_shadow" ] ; then
    (
      echo "$sys_shadow"
      shpwd_gen_pwds | sort
    ) | fixfile --mode=400 "$etc_shadow" || :
  fi
}

shpwd_gen_groupfiles() {
  ## Generate group related shadow files
  ## # USAGE
  ##    [--group] [--gshadow]
  ## # OPTIONS
  ## * --group : specify the /etc/group file (or use default)
  ## * --gshadow: specify the /etc/gshadow file (or use default)
  local \
    etc_group="${TLR_ETC}/group" \
    etc_gshadow=""

  while [ $# -gt 0 ]
  do
    case "$1" in
      --group) etc_group="${TLR_ETC}/group" ;;
      --group=*) etc_group="${1#--group=}" ;;
      --no-group) etc_group="" ;;
      --gshadow) etc_gshadow="${TLR_ETC}/gshadow" ;;
      --gshadow=*) etc_gshadow="${1#--gshadow=}" ;;
      --no-gshadow) etc_gshadow="" ;;
    *) break ;;
    esac
    shift
  done

  local \
    mgid=${GID_MIN:-5000} \
    muid=${UID_MIN:-500} \
    max=${XID_MAX:-65000}
  local min=$([ $mgid -lt $muid ] && echo $mgid || echo $muid)

  if [ -n "$etc_group" ] ; then
    local sys_group="$(shpwd_xid_filter -x --min=$min --max=$max < $etc_group | sort -n -k3 -t:)"
    (
      echo "$sys_group"
      shpwd_gen_usrgrps | sort
      shpwd_gen_grps | sort
    ) | fixfile --mode=644 "$etc_group"
  fi
  if [ -n "$etc_gshadow" ] ; then
    shpwd_gen_gshadow < "$etc_group" | fixfile --mode=400 "$etc_gshadow"
  fi
}

#####################################################################


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

