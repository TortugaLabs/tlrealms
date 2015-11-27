#
# Locking functions
#
lockfd=200

with_lock() {
  [ -z "$lockfile" ] && fatal "No lockfile specified"
  local mode="$1" ; shift
  (
    flock -x 200 || fatal "Unable to obtain lock"
    "$@"
  ) 200>$lockfile
}

