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
## Functions to keep data synchronized
##
## Configurable items:
##
## - TLR_DATA : location of hosts_db directory
## - TLR_SSH_USER : defaults to "root"
## - TLR_SSH_KEY : defaults to /etc/ssh/ssh_host_rsa_key ... private key
##   for current host.
## - TLR_SSH_FORCED_CMD: defaults to /usr/local/bin/tlr in.rpc
## - TLR_SSH_ARGS : Additional args for ssh command
#*####################################################################
include -1 api-hosts fixfile.sh

rsync_run_opts="-az --delete"
rsync_extra_opts="no-pty,no-agent-forwarding,no-port-forwarding,no-X11-forwarding"
rsync_cmd="rsync"
ssh_cmd="ssh"
ssh_opts="-o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

sync_rpc_check() {
  ## validate forced command input...
  ## # USAGE
  ##  sync_rpc_check [incoming rsync options]
  ## # DESC
  ## Used to verify rsync incoming options
  ## # RETURNS
  ## 0 on succes, 1 if error
  [ $# -ne 5 ] && return 1 || :
  [ x"$1" != x"--server" ] && return 1 || :
  [ x"$2" != x"--sender" ] && return 1 || :
  # [ x"$3" != x"$rsync_rpc_opts" ] && return 1 || :
  [ x"$4" != x"." ] && return 1 || :
  return 0
}

sync_rpc_run() {
  ## call rsync in server-sender mode
  ## # USAGE
  ##   sync_rpc_run {rsync_rpc_opts}
  ## # DESC
  ## This is called from the SSH forced command to start
  ## the actual rsync transfer.  Note, that the source folder
  ## is being overriden.
  $rsync_cmd --server --sender "$1" . "${TLR_DATA:-/etc/tlr}/"
}

sync_fetch() {
  ## retrieve sync data using rsync
  ## # USAGE
  ##   sync_fetch [master]
  local srcsys="$1" keyfile=${TLR_SSH_KEY:-/etc/ssh/ssh_host_rsa_key} \
    dstpath="${TLR_DATA:-/etc/tlr}"

  dstpath=$(echo "$dstpath" | sed -e 's!/*$!!')
  if [ ! -d "$dstpath" ] ; then
    if [ -L "$dstpath" ] ; then
      echo "$dstpath: points to a missing directory!" 1>&2
      return 1
    fi
    mkdir -p "$dstpath"
  fi

  env SSH_AUTH_SOCK= \
      $rsync_cmd $rsync_run_opts \
	-e "$ssh_cmd ${TLR_SSH_ARGS:-} -i $keyfile $ssh_opts" \
	"${srcsys}:/etc/tlr/" "$dstpath"
}

sync_ssh_cmd() {
  ## Remote command execution...
  ## # USAGE
  ##   sync_ssh_cmd srcsys [-i keyfile] [options]
  local keyfile=${TLR_SSH_KEY:-/etc/ssh/ssh_host_rsa_key}
  while [ $# -gt 0 ]
  do
    case "$1" in
      --key=*) keyfile=${1#--key=} ;;
      -i) keyfile=$2 ; shift ;;
      *) break ;;
    esac
    shift
  done
  env SSH_AUTH_SOCK= $ssh_cmd -i $keyfile -l ${TLR_SSH_USER:-root} ${TLR_SSH_ARGS:-} $ssh_opts "$@"
}

sync_dump_s() {
  tar -C "$TLR_DATA" -zcf - .
}
sync_dump_c() {
  ## Dump TLR_DATA (client-side)
  ## # USAGE
  ##   sync_dump_c [-v] [--base64|--no-base64] [--dump|--extract] [--master=the-master] [outdir]
  ## # OPTIONS
  ## * --base64|-b : use MIME base64 during data transfer
  ## * --no-base64|-B : use raw binary during data transfer
  ## * --dump : dump database data as a tarball (suitable for backup)
  ## * --extract : copy database data to outdir, if specified, otherwise to TLR_DATA
  ## * --master=master : master source system (defaults to TLR_MASTER)
  local encode=true dump=true v="" srcsys=${TLR_MASTER:-}
  while [ $# -gt 0 ]
  do
    case "$1" in
      -b|--base64) encode=true ;;
      -B|--no-base64) encode=false ;;
      -d|--dump) dump=true ;;
      -x|--extract) dump=false ;;
      -v) v=v ;;
      --master=*) srcsys=${1#--master=} ;;
      *) break ;;
    esac
    shift
  done
  [ -z "$srcsys"  ] && return 1

  sync_ssh_cmd "$srcsys" dump $($encode && echo -b || echo -B) | (
    $dump && exec cat
    if [ $# -eq 0 ] ; then
      local outdir=$TLR_DATA
    else
      local outdir="$1"
    fi
    ($encode && exec base64 -d || exec cat ) | (
      [ -L "$outdir" ] && outdir=$(readlink -f "$outdir" | sed -e 's!/*$!!')
      mkdir -p "$outdir.inc"
      chown "$(stat -c '%u' "$outdir"):$(stat -c '%g' "$outdir")" "$outdir.inc"
      chmod $(stat -c '%a' "$outdir") "$outdir.inc"
      tar -C "$outdir.inc" -zx${v}f -

      rm -rf "$outdir.old"
      mv "$outdir" "$outdir.old"
      mv "$outdir.inc" "$outdir"
    )
  )
}


sync_gen_host_keys() {
  ## Generate ssh auth key config from hosts
  ## # USAGE
  ##   sync_gen_host_keys
  local extra_opts="$rsync_extra_opts"
  if [ -n "$extra_opts" ] ; then
    if [ x"${extra_opts:0:1}" != x"," ] ; then
      extra_opts=",$extra_opts"
    fi
  fi
  local fcmd="${TLR_SSH_FORCED_CMD:-/usr/local/bin/tlr in.rpc}" v
  fcmd="command=\"env TLR_CLIENT=<CLIENT> $fcmd\""

  for host in $(hosts_list)
  do
    hosts_pk -v $host | (
      fcmd=$(echo "$fcmd" | sed -e 's/<CLIENT>/'"$host"'/')
      while read -r line
      do
	echo "$fcmd$extra_opts $line"
      done
    )
  done
}

sshdcfg_fixup() {
  ## Fix-up `sshd_config` file to allow for our customizations
  ## # USAGE
  ##  sshdcfg_fixup [-v][-t] [sshd_config] [extra_keys]
  ## # OPTIONS
  ## * -v : verbose option
  ## * sshd_config : path to sshd_config file
  ## * extra_keys : extra keys file
  local msg=":"

  while [ $# -gt 0 ]
  do
    case "$1" in
      -v) msg="echo" ;;
      *) break ;;
    esac
    shift
  done
  local sshd_config="$1" ; shift
  (fixfile --filter $sshd_config || :) <<-_EOF_
	grep -v AuthorizedKeysFile
	echo "AuthorizedKeysFile .ssh/authorized_keys $*"
	_EOF_
}

#~ sync_check_hostkeys() {
  #~ ## Check if hostkeys need to be updated.
  #~ ## # USAGE
  #~ ##   sync_check_hostkeys [target]
  #~ ## # OPTIONS
  #~ ## * target : target file to check
  #~ ## # RETURNS
  #~ ## 0 if the target needs to be re-build, 1 if target is up-to-date
  #~ ## # DESC
  #~ ## Uses `depcheck` (which needs to be included explicitly) to
  #~ ## check if `target` needs to be updated.
  #~ local target="$1"
  #~ depcheck "$target" \
	#~ $(find "$hosts_db" -maxdepth 1 -mindepth 1 -name '*.pub' -type f) && return 0
  #~ return 1
#~ }



#~ sync_sshd_restart() {
  #~ ## Re-start ssh daemon
  #~ ## # USAGE
  #~ ##  sync_sshd_restart
  #~ [ $(id -u) -ne 0 ] && return 0 # Skip this if not running as root
  #~ # We need to restart sshd
  #~ if type rc-service ; then
    #~ $msg "Alpine OpenRC system"
    #~ rc-service sshd restart
  #~ elif type sv ; then
    #~ $msg "Void-Linux runsvc"
    #~ if [ ! -d /var/service/sshd ] ; then
      #~ ln -s ${TLR_ETC:-/etc}/sv/sshd /var/service
    #~ else
      #~ sv restart sshd
    #~ fi
  #~ fi
#~ }



  #~ local srcsys="${TLR_MASTER:-}" srcpath="$TLR_HOME" dstpath="$TLR_HOME" keyfile=${TLR_ETC:-/etc}/ssh/ssh_host_rsa_key
  #~ while [ $# -gt 0 ]
  #~ do
    #~ case "$1" in
    #~ --master=*) srcsys=${1#--master=} ;;
    #~ --path=*) srcpath=${1#--path=} ; dstpath=${1#--path=} ;;
    #~ --src-path=*) srcpath=${1#--src-path=} ;;
    #~ --dst-path=*) dstpath=${1#--dst-path=} ;;
    #~ --key=*) keyfile=${1#--key=} ;;
    #~ *) srcsys=$1 ;;
    #~ esac
    #~ shift
  #~ done

#~ require spk_enc.sh

#~ http_encode() {
  #~ local srcpath="$TLR_HOME" sys=""
  #~ while [ $# -gt 0 ]
  #~ do
    #~ case "$1" in
    #~ --src-path=*) srcpath=${1#--src-path=} ;;
    #~ *) sys=$1 ;;
    #~ esac
    #~ shift
  #~ done
  #~ [ -z "$sys" ] && return 16
  #~ tar -C "$srcpath" -zcf - . | spk_encrypt --base64 "$TLR_DATA/hosts.d/$sys.pub"
#~ }
#~ http_decode() {
  #~ local dstpath="$TLR_HOME" keyfile=${TLR_ETC:-/etc}/ssh/ssh_host_rsa_key
  #~ while [ $# -gt 0 ]
  #~ do
    #~ case "$1" in
    #~ --dst-path=*) dstpath=${1#--dst-path=} ;;
    #~ *) keyfile=${1#--key=} ;;
    #~ esac
    #~ shift
  #~ done
  #~ local w=$(mktemp -d) rc=0
  #~ (
    #~ spk_decrypt --base64 "$keyfile" | tar -C "$w" -zxf -
    #~ rsync -az --delete "$w/" "$dstpath"
  #~ ) || rc=$?
  #~ rm -rf "$w"
  #~ return $rc
#~ }


#~ sync_gen_keys() {
  #~ local \
	#~ authkeys="$TLR_DATA/root_keys.d/syncdata.pub" \
	#~ hostsdb="$TLR_DATA/hosts.d" \
	#~ forced_cmd='env TLR_CLIENT=<HOST> rsync --server --sender -logDtprze.iLsfxC . <SRCPATH>' \
	#~ extra_opts="no-pty,no-agent-forwarding,no-port-forwarding" \
	#~ srcpath="$TLR_HOME"


  #~ while [ $# -gt 0 ]
  #~ do
    #~ case "$1" in
    #~ --hosts-dir=*) hostsdb="${1#--hosts-dir=}" ;;
    #~ --force-cmd=*) forced_cmd="${1#--force-cmd=}" ;;
    #~ --extra-opts=*) extra_opts="${1#--extra-opts=}" ;;
    #~ --src-path=*) srcpath="${1#--src-path=}" ;;
    #~ *) authkeys="${1}" ;;
    #~ esac
    #~ shift
  #~ done

  #~ if [ -n "$rsync_extra_opts" ] ; then
    #~ if [ x"${rsync_extra_opts:0:1}" != x"," ] ; then
      #~ extra_opts=",$rsync_extra_opts"
    #~ fi
  #~ fi
  #~ forced_cmd=$(echo "$forced_cmd" | sed -e 's!<SRCPATH>!'"$srcpath"'!')

#~ }
