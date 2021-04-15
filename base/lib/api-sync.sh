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
## - TLR_SSH_KEY : defaults to /etc/ssh/ssh_host_rsa_key ... private key
##   for current host.
## - TLR_SSH_FORCED_CMD: defaults to /usr/local/bin/sshrpc
## - TLR_SSH_FORCED_ENV: forced command environment
## - TLR_SSH_ARGS : Additional args for ssh command
#*####################################################################
include -1 api-hosts

rsync_rpc_opts="-logDtprze.iLsfxC"
	      ##-logDtprze.iLsfxCIvu
rsync_run_opts="-az --delete"
rsync_extra_opts="no-pty,no-agent-forwarding,no-port-forwarding,no-X11-forwarding"

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
  ##   sync_rpc_run
  ## # DESC
  ## This is called from the SSH forced command to start
  ## the actual rsync transfer.  Note, that the source folder
  ## is being overriden.
  rsync --server --sender "$rsync_rpc_opts" . "${TLR_DATA}/"
}

sync_fetch() {
  ## retrieve sync data using rsync
  ## # USAGE
  ##   sync_fetch [master]
  local srcsys="$1" keyfile=${TLR_SSH_KEY:-/etc/ssh/ssh_host_rsa_key} \
    srcpath="$TLR_DATA" dstpath="$TLR_DATA"

  srcpath=$(echo "$srcpath" | sed -e 's!/*$!!')
  dstpath=$(echo "$dstpath" | sed -e 's!/*$!!')
  if [ ! -d "$dstpath" ] ; then
    if [ -L "$dstpath" ] ; then
      echo "$dstpath: points to a missing directory!" 1>&2
      return 1
    fi
    mkdir -p "$dstpath"
  fi

  env SSH_AUTH_SOCK= \
      rsync $rsync_run_opts \
	-e "ssh ${TLR_SSH_ARGS:-} -i $keyfile -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
	"${srcsys}:${srcpath}/" "$dstpath"
}

sync_check_hostkeys() {
  ## Check if hostkeys need to be updated.
  ## # USAGE
  ##   sync_check_hostkeys [target]
  ## # OPTIONS
  ## * target : target file to check
  ## # RETURNS
  ## 0 if the target needs to be re-build, 1 if target is up-to-date
  ## # DESC
  ## Uses `depcheck` (which needs to be included explicitly) to
  ## check if `target` needs to be updated.
  local target="$1"
  depcheck "$target" \
	$(find "$hosts_db" -maxdepth 1 -mindepth 1 -name '*.pub' -type f) && return 0
  return 1
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
  local fcmd="${TLR_SSH_FORCED_CMD:-/usr/local/bin/sshrpc}" v
  for v in ${TLR_SSH_FORCED_ENV:-}
  do
    fcmd="$v $fcmd"
  done
  fcmd="command=\"env TLR_CLIENT=<CLIENT> $fcmd\""

  for host in $(hosts_list)
  do
    hosts_pub -v $host | (
      fcmd=$(echo "$fcmd" | sed -e 's/<CLIENT>/'"$host"'/')
      while read -r line
      do
	echo "$fcmd$extra_opts $line"
      done
    )
  done
}

sync_sshdcfg_fixup() {
  ## Fix-up `sshd_config` file to allow for our customizations
  ## # USAGE
  ##  sync_sshdcfg_fixup [-v][-t] [sshd_config] [extra_keys]
  ## # OPTIONS
  ## * -v : verbose option
  ## * -t : test mode (no changes made)
  ## * sshd_config : path to sshd_config file
  ## * extra_keys : extra keys file
  local msg=":" check=":" run=""

  while [ $# -gt 0 ]
  do
    case "$1" in
      -v) msg="echo" ; check="wc" ;;
      -t) run="echo" ;;
      *) break ;;
    esac
    shift
  done
  local sshd_config="$1" extra_keys="$2"

  grep -q "$extra_keys" "$sshd_config" && return 0

  $msg "Updating $sshd_config"
  local ntxt="$(
	sed -e "s/^\(.*AuthorizedKeysFile\)/#TLR# \1/" -e 's/^/:/' $sshd_config
	echo ':'
	echo ":#TLR## Enabled $extra_keys for TLR deployed keys"
	echo ":AuthorizedKeysFile      .ssh/authorized_keys $extra_keys"
	)"
  (echo "$ntxt" | sed -e 's/^://' | $run tee $sshd_config | $check) || $msg $?
}

sync_sshd_restart() {
  ## Re-start ssh daemon
  ## # USAGE
  ##  sync_sshd_restart
  [ $(id -u) -ne 0 ] && return 0 # Skip this if not running as root
  # We need to restart sshd
  if type rc-service ; then
    $msg "Alpine OpenRC system"
    rc-service sshd restart
  elif type sv ; then
    $msg "Void-Linux runsvc"
    if [ ! -d /var/service/sshd ] ; then
      ln -s ${TLR_ETC:-/etc}/sv/sshd /var/service
    else
      sv restart sshd
    fi
  fi
}



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
