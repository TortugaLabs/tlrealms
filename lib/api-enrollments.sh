#!/bin/sh
require api-serial.sh
require api-hosts.sh

enrolls_key_types() {
  echo "dsa ecdsa ed25519 rsa"
}

enrolls_queue_dir() {
  echo "$TLR_LOCAL/qdir"
}

enrolls_add() {
  local \
	result_name="$1"
	inp_host="$2" \
	tstamp=$(date +"%Y%m%d-%H%M%S") \
	serial=0 \
	remote="$REMOTE_ADDR" \
	queue_dir=$(enrolls_queue_dir) \
	key_types=$(enrolls_key_types) \
	host= \
	dir=
  
  if ! host=$(hosts_namechk "$inp_host") ; then
    echo "Invalid characters in hostname: $FORM_host"
    return 1
  fi
  if hosts_exists "$host" ; then
    echo "MSG: ******************************"
    echo "MSG: WARNING, $host already exists!"
    echo "MSG: ******************************"
  fi

  while [ -d "$queue_dir/$tstamp,$serial,$remote,$host.d" ] ; do
    serial=$(expr $serial + 1)
  done
  dir="$queue_dir/$tstamp,$serial,$remote,$host.d"
  mkdir -p "$dir"
  cat > "$dir/metadata.cfg" <<-EOF
	tstamp=$tstamp
	remote=$REMOTE_ADDR
	name=$host
	serial=$serial
	id=$tstamp,$serial,$remote,$host
	EOF
  ssh-keygen -q -N '' -C 'provisional admin' -f "$dir/admin_key"
  for type in $key_types
  do
    ssh-keygen -q -N '' -t $type -C "host:${type}@$host" -f "$dir/ssh_host_${type}_key"
  done
  eval $result_name=\"\$dir\"
  return 0
}

_enrolls_field() {
  case "$1" in
  tstamp) echo 1;;
  serial) echo 2;;
  remote) echo 3;;
  host) echo 4;;
  dup) echo 5;;
  log) echo 6;;
  id) echo 1-4;;
  *) echo 1-;;
  esac
}

enrolls_payload() {
  local dir="$1"
  ( cd "$dir" && find . -mindepth 1 -maxdepth 1 | cut -d/ -f2-| tr '\n' '\0') | xargs -0 tar -C "$dir" -zcf - | base64
}


enrolls_get() {
  echo "$2" | cut -d, -f$(_enrolls_field "$1")
}

enrolls_exists() {
  if [ -f "$(enrolls_queue_dir)/$1.d/metadata.cfg" ] ; then
    return 0
  fi
  return 1
}

enrolls_list() {
  find "$(enrolls_queue_dir)" -maxdepth 1 -mindepth 1 -type d | (
    local d rhost status logs
    while read d
    do
      d=$(basename "$d" .d)
      rhost=$(enrolls_get host "$d")
      if hosts_exists "$rhost" ; then
	status="true"
      else
	status="false"
      fi
      if [ -f $TLR_LOGS/enroll-$d ] ; then
	logs=true
      else
	logs=false
      fi
      echo $d,$status,$logs
    done
  )
  find "$TLR_LOGS" -maxdepth 1 -mindepth 1 -type f -name 'enroll-*' | (
    local queue_dir=$(enrolls_queue_dir) cnt=0
    while read d
    do
      d=$(basename "$d" | sed -e 's/^enroll-//')
      [ -d "$queue_dir/$d.d" ] && continue # We already listed this one...
      rhost=$(enrolls_get host "$d")
      if hosts_exists "$rhost" ; then
	status="true"
      else
	status="false"
      fi
      echo $d,$status,true
    done
  )
}

enrolls_del() {
  local logs=: queue=:
  while [ $# -gt 0 ]
  do
    case "$1" in
    --logs) logs=: ;;
    --no-logs) logs=false ;;
    --queue) queue=: ;;
    --no-queue) queue=false ;;
    *) break;
    esac
    shift
  done
  local d queue_dir=$(enrolls_queue_dir)
  for d in "$@"
  do
    if $logs ; then
      rm -rf "$TLR_LOGS/enroll-$d"
    fi
    if $queue ; then
      rm -rf "$queue_dir/$d.d"
    fi
  done
}

_enrolls_register() {
  local vv="$1" clobber="$2"
  local \
	queue_dir=$(enrolls_queue_dir) \

  if [ ! -f "$queue_dir/$vv.d/metadata.cfg" ] ; then
    echo "Error enrolling $vv, missing metadata.cfg" 1>&2
    return 1
  fi
  
  local name remip
  if ! name="$(hosts_namechk "$(echo "$vv" | cut -d, -f4)")" ; then
    echo "Invalid ENROLL name: $vv" 1>&2
    return 1
  fi

  if hosts_exists "$name" ; then
    if ! $clobber ; then
      echo "Host \"$name\" already exists!" 1>&2
      return 1
    else
      echo "Overwriting \"$name\"" 1>&2
    fi
  fi

  remip="$(echo "$vv" | cut -d, -f3)"
  echo "ENROLLING \"$name\" ($remip)" 1>&2
  echo "$name"
  echo "$remip"
  exec 1>&2

  # - add keys to TLR_DATA/hosts.d
  find "$queue_dir/$vv.d" -maxdepth 1 -mindepth 1 -type f -name "ssh_host_*.pub" -print0 \
	| xargs -0 cat | hosts_add "$name"

  # - apply local policy
  apply_policies
  # Make sure we don't have it in known_hosts
  local known_hosts=$HOME/.ssh/known_hosts
  if [ -f "$known_hosts" ] ; then
    ssh-keygen -R "$remip" -f "$known_hosts"
    ssh-keygen -R "$name" -f "$known_hosts"
  fi
  return 0
}

enrolls_this() {
  local clobber=false offline=false output=''
  while [ $# -gt 0 ] ; do
    case "$1" in
    --clobber|-f) clobber=true ;;
    --no-clobber|-i) clobber=false ;;
    --offline|-d) offline=true ;;
    --online|-n) offline=false ;;
    --tar=*) output="${1#--tar=}" ;;
    *) break ;;
    esac
    shift
  done
  local vv="$1" txt
  txt=$(_enrolls_register "$vv" "$clobber") || return 1
  [ -z "$txt" ] && return 1
  local name="$(echo "$txt" | ( read j ; echo $j))"
  local remip="$(echo "$txt" | ( read j ; read j ; echo $j))"


  if [ "$name" = "$(hostname)" ] ; then
    echo "Adding $name to itself..." 1>&2
    return 0
  fi
  if ! $offline ; then
    SSH_IP_OVERRIDE="$remip" SSH_IDENTITY="$queue_dir/$vv.d/admin_key" $TLR_SCRIPTS/syncr -v "$name"
    SSH_IP_OVERRIDE="$remip" SSH_IDENTITY="/etc/ssh/ssh_host_rsa_key" $TLR_SCRIPTS/syncr --rsh "$name" uptime
    return $?
  fi
  # This is an offline enrollment...
  local tmppath=$(mktemp -d)
  trap "rm -rf $tmppath" EXIT
  rsync -az --exclude='*~' --delete  "$TLR_HOME/" "$tmppath"
  if [ -n "$output" ] ; then
    tar -C "$tmppath" -zcvf "$output" .
    return $?
  fi
  echo ''
  echo '== begin here =='
  tar -C "$tmppath" -zcvf - . | base64
  echo ''
  echo '== end here =='
}


