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
## Functions to manage hosts data
##
## Configurable items:
##
## - TLR_DATA : location of groups_db directory
## - groups_db
## - groups_exts
## - GID_MIN
#*####################################################################
include -1 api-plist.sh

groups_exts=".cfg"
groups_db="$TLR_DATA/groups.d"

groups_namechk() {
  ## Make sure valid group names
  ## # USAGE
  ##   groups_namechk <name>
  ## # OPTIONS
  ## * name - name candidate to check
  ## # RETURNS
  ## 0 if name is valid, 1 if it is invalid
  ## # OUTPUT
  ## Outputs a sanitized version of the name

  local in="$(echo "$1" | tr A-Z a-z)"
  local out="$(echo "$in" | tr -dc 'a-z0-9_-')"
  echo "$out"
  [ "$out" = "$in" ] && return 0
  return 1
}

groups_exists() {
  ## checks if a group exists
  ## # USAGE
  ##   groups_exists <id>
  ## # OPTIONS
  ## * id - group to verify
  ## # DESC
  ## Tests if a group exists
  ## # RETURNS
  ## 0 if found, 1 if not found
  plst_exists "$1" "$groups_db" $groups_exts
  return $?
}

groups_list() {
  ## List all groups
  ## # USAGE
  ##   groups_list
  ## # DESC
  ## List all groups
  ##
  plst_list "$groups_db" $groups_exts
}


groups_usergroups() {
  ## Return groups that a user is member of
  ## # USAGE
  ##   groups_usergroups [--no-resolve|--resolve] <user>
  ## # OPTIONS
  ## * --resolve : expand group references
  ## * --no-resolve : do not expand group references
  ## * user - user to check, prefix '@' for nested group references
  local resolve=true

  while [ $# -gt 0 ]
  do
    case "$1" in
      --resolve) resolve=true ;;
      --no-resolve) resolve=false ;;
      *) break ;;
    esac
    shift
  done

  local g m
  (
    if $resolve ; then
      for g in $(groups_list)
      do
	for m in $(groups_members "$g")
	do
	  [ $m = "$1" ] && echo "$g" || :
	done
      done
    else
      for g in $(groups_list)
      do
	for m in $(plst_get "$g" "$groups_db" ".cfg" "mem")
	do
	  [ $m = "$1" ] && echo "$g" || :
	done
      done
    fi
  ) | xargs
}

groups_add() {
  ## Create a new group
  ## # USAGE
  ##   groups_add [--gid=<gid>] <grname> [members]
  ## # OPTIONS
  ## * --gid=<gid> : Specify a group id to create, if omitted a new one is generated
  ## * grname : group name to create
  ## * members : if specified, the members of the group.
  local gid=""

  while [ $# -gt 0 ]
  do
    case "$1" in
    --gid=*)
      gid=${1#--gid=}
      ;;
    *)
      break
    esac
    shift
  done

  [ $# -eq 0 ] && return 1

  local grname=$(groups_namechk "$1") || return 2 ; shift
  groups_exists "$grname" && return 3

  mkdir -p "$groups_db"


  local mem="$(echo "$@" | tr ' ' '\n' | sort -u | xargs)"

  if [ -z "$gid" ] ; then
    gid=$(expr ${GID_MIN:-5000} - 1) # We add one later...
    local g
    for g in $(groups_list)
    do
      g=$(plst_get "$g" "$groups_db" ".cfg" gid)
      [ $g -gt $gid ] && gid=$g
    done
    gid=$(expr $gid + 1)
  fi
  plst_set "$grname" "$groups_db" .cfg "gid" "$gid" "mem" "$mem"
  return $?
}

groups_gid() {
  ## Get or set groups' gid
  ## # USAGE
  ##   groups_gid <grname> [ngid]
  ## # OPTIONS
  ## * <grname> : group name to read or set
  ## * ngid : if not specified, returns the current gid, if specified, the gid will be set to ngid
  local grname="$1" ; shift
  groups_exists "$grname" || return 1
  if [ $# -eq 0 ] ; then
    plst_get "$grname" "$groups_db" ".cfg" gid
    return $?
  fi

  [ $# -ne 1 ] && return 100
  local newgid="$1" gid="$(plst_get "$grname" "$groups_db" ".cfg" gid)"
  [ x"$gid" = x"$newgid" ] && return 0

  plst_set "$grname" "$groups_db" ".cfg" gid "$1"
  return $?
}

_groups_members_resolv() {
  local grname="$1"

  # Resolve group references...
  local gid=$(plst_get "$grname" "$groups_db" ".cfg" gid)
  eval local cached=\${__GROUPS_C_${gid}:-}
  if [ -n "$cached" ] ; then
    echo ${cached:1}
    return 0
  fi
  local mem= q= i
  eval "__GROUPS_C_${gid}='-'"		# Prevent recursion loops
  for i in $(plst_get "$grname" "$groups_db" ".cfg" mem)
  do
    [ x"${i:0:1}" = x"@" ] && i=$(groups_members "${i:1}")
    mem="$mem$q$i"
    q=" "
  done
  eval "__GROUPS_C_${gid}=\"+\$mem\"" 	# Cache result
  echo $mem | tr ' ' '\n' | sort -u | xargs
  return 0
}


groups_members() {
  ## Get or set groups' members
  ## # USAGE
  ##   groups_members [--no-resolve] <grname> [members]
  ## # OPTIONS
  ## * --no-resolve: if specified, nested groups are not resolved
  ## * <grname>: group to lookup or set
  ## * [members]: if not specified, returns group members.  If specified,
  ##   sets the membership list.  If set to '' membership set to an empty list.
  local resolve=true
  while [ $# -gt 0 ]
  do
    case "$1" in
      --no-resolve) resolve=false ;;
      --resolve) resolve=true ;;
      *) break ;;
    esac
    shift
  done
  local grname="$1" ; shift
  groups_exists "$grname" || return 1

  if [ $# -eq 0 ] ; then
    # Lookup....
    if $resolve ; then
      (_groups_members_resolv "$grname")
      return $?
    else
      plst_get "$grname" "$groups_db" ".cfg" mem
      return $?
    fi
    return
  fi

  local newmem mem
  if [ $# -eq 1 ] && [ -z "$1" ] ; then
    newmem=''
  else
    newmem=$(echo "$@" | tr ' ' '\n' | sort -u | xargs)
  fi
  mem=$(plst_get "$grname" "$groups_db" ".cfg" mem)

  [ x"$mem" = x"$newmem" ] && return 0
  plst_set "$grname" "$groups_db" ".cfg" mem "$newmem"
  return $?
}

groups_adduser() {
  ## Add user to a group as a member
  ## # USAGE
  ##   groups_adduser <grname> member
  ## # OPTIONS
  ## * <grname> : group to modify
  ## * member : one or more members to add
  [ $# -lt 2 ] && return 1
  local grname="$1" ; shift
  groups_exists "$grname" || return 1

  local \
	mem=$(plst_get "$grname" "$groups_db" ".cfg" mem)
	newmem=$(echo $mem "$@" | tr ' ' '\n' | sort -u | xargs)

  [ x"$newmem" = x"$mem" ] && return 0
  plst_set "$grname" "$groups_db" ".cfg" mem "$newmem"
  return $?
}

groups_deluser() {
  ## Delete user from a group membership
  ## # USAGE
  ##   groups_deluser <grname> member
  ## # OPTIONS
  ## * <grname> : group to modify
  ## * member : one or more members to remove
  ##
  [ $# -lt 2 ] && return 1
  local grname="$1" ; shift

  if [ x"$grname" = x"--all" ] || [ x"$grname" = x"#" ] ; then
    for n in "$@"
    do
      for g in $(groups_usergroups --no-resolve "$n")
      do
	groups_deluser "$g" "$n"
      done
    done
    return 0
  fi

  groups_exists "$grname" || return 1

  local \
	mem=$(plst_get "$grname" "$groups_db" ".cfg" mem) \
	newmem='' q='' i

  for i in $mem
  do
    if ! (
      for n in "$@"
      do
        [ "$n" = "$i" ] && exit 0
      done
      exit 1
    ) ; then
      newmem="$newmem$q$i"
      q=" "
    fi
  done

  [ x"$newmem" = x"$mem" ] && return 0
  plst_set "$grname" "$groups_db" ".cfg" mem "$newmem"
  return $?
}

##################################
groups_cleanup() {
  ## Check if the given item is in any groups and remove it
  ## # USAGE
  ##   groups_cleanup <item>
  local n i
  for n in "$@"
  do
    for i in $(groups_usergroups --no-resolve "$n")
    do
      groups_deluser "$i" "$n"
    done
  done
}

groups_del() {
  ## Deletes groups
  ## # USAGE
  ##   groups_del <host>
  ## # OPTIONS
  ## * group - group name to delete (can be specified multiple times)
  ##
  local n
  for n in "$@"
  do
    groups_exists "$n" || continue
    groups_cleanup '@'"$n"
    plst_del "$n" "$groups_db" $groups_exts
  done
}
