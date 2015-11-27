#
# Update databases
#
serial() {
  if [ x"$1" = x"read" ] ; then
    shift
    if [ -f "$2"/serial.txt ] ; then
      cat "$2"/serial.txt
    else
      date +%s
    fi
  else
    date +%s > "$1"/serial.txt
  fi
}

deps() {
  local target="$1" ; shift
  [ -f "$target" ] || return 0	# If doesn't exist... return true...
  local src
  for src in "$@"
  do
    [ -f "$src" ] || continue
    [ "$target" -ot "$src" ] && return 0  # src is newer... update
  done
  # No match... return false.. no change
  return 1
}

sysupd() {
  local dbdir="$1"
  local etcdir="$2"

  serial $dbdir

  if deps $sys_authkeys \
      $dbdir/known_hosts $dbdir/admin_keys $sys_authkeys.local ; then
    # Create new auth keys
    (
      (
	while read syshost key
	do
	  echo command=\"$hostkey_cmd $syshost\",$authkeys_opts $key
	done
      ) < $dbdir/known_hosts
      (
	while read admin key
	do
	  echo $key $admin
	done
      ) < $dbdir/admin_keys
      [ -f $sys_authkeys.local ] && cat $sys_authkeys.local
    ) >$sys_authkeys
  fi

  #if deps $sys_knownhosts $dbdir/known_hosts ; then
  #  # Create new known hosts database
  #  cat $dbdir/known_hosts > $sys_knownhosts
  #fi
}
