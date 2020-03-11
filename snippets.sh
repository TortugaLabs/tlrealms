#!/bin/sh

[ -z "${fixfile:-}" ] && fixfile="lib/fixfile.sh"
[ -z "${binder:-}" ] && binder="include/binder.php"
[ -z "${codelib:-}" ] && codelib="$mydir/../codelib1"
include_once $codelib/lib/snippetlib.sh

setup_init() {
  # install init scripts...
  if type rc-service ; then
    rm -f /etc/init.d/srvpriv
    ln -s $TLR_LIB/init.d-openrc/srvpriv /etc/init.d/srvpriv
    rc-update add srvpriv
    rc-service srvpriv start
  else
    echo "***"
    echo "*** Unknown init system"
    echo "***"
  fi
}

setup_www() {
  if [ $# -eq 0 ] ; then
    set - digest /var/www/localhost/htdocs
  fi
  local mode="$1" wwwdir="$2"
  
  mkdir -p $wwwdir/tlr $wwwdir/tlrsec
  mkdir -p $TLR_LOCAL/qdir ; chmod 777 $TLR_LOCAL/qdir
  mkdir -p $TLR_LOCAL/run
  mkdir -p $TLR_LOGS
  
  ln -sf $TLR_SCRIPTS/www-enroll.cgi $wwwdir/tlr/enroll.cgi
  ln -sf $TLR_SCRIPTS/www-enrollme.sh.in $wwwdir/tlr/enrollme.sh.in
  ln -sf $TLR_SCRIPTS/www-sync.cgi $wwwdir/tlr/sync.cgi
  ln -sf $TLR_SCRIPTS/swww-doenroll.cgi $wwwdir/tlrsec/doenroll.cgi
  
  if [ x"$mode" = x"digest" ] ; then
    basic="# "
    digest=""
    domain="${domain:-TL|Realm}"
  else
    basic=""
    digest="# "
    domain="${domain:-tl-domain}"
  fi
  (fixfile --mode=644 $wwwdir/tlrsec/.htaccess && echo 'Updated .htaccess' || :)<<-EOF
	# Secured zone
	
	${basic}AuthName "$domain Password Required"
	${basic}AuthType Basic
	${basic}AuthUserFile "/etc/tlr-local/htpasswd.txt"
	
	${digest}AuthName "$domain"
	${digest}AuthType Digest
	${digest}AuthDigestDomain /tlrsec/
	${digest}AuthDigestProvider file
	${digest}AuthUserFile "/etc/tlr-local/htdigest.txt"
	
	AuthGroupFile "/etc/tlr-local/htgroup.txt"
	Require group admins
	EOF

  local cf=/etc/apache2/httpd.conf
  local intxt="$(apache_cf_edit <"$cf")"
  (echo "$intxt" | fixfile "$cf" ) || :
}


ii_softdep="Update soft dependancies"
jl_softdep() {
  . "$mydir/sdep.sh"
  repo_url=https://raw.githubusercontent.com/TortugaLabs/ashlib/master

  sdep sdep.sh
  sdep fixfile.sh:lib/fixfile.sh
  sdep refs.sh:lib/refs.sh
  sdep shesc.sh:lib/shescape.sh
  sdep urlencode.sh:lib/urlencode.sh
}

ii_reset="Initialize environment, (will destroy existing database)"
ll_reset() {
  echo "WARNING: This will destroy existing environment" 1>&2
  echo -n "Enter \"yes\" to continue!: " 1>&2
  read yes
  if [ x"$yes" = x"yes" ] ; then
    echo "Continuing..." 1>&2
    return 0
  fi
  echo "ABORTING!" 1>&2
  exit 1
}
pl_reset() {
  if [ ! -L /etc/tlr-store ] ; then
    echo "A /etc/tlr-store symlink pointing to the data store must be created" 1>&2
    exit 1
  fi
  if [ ! -e /etc/tlr-store ] ; then
    echo "/etc/tlr-store does not point to an existing location" 1>&2
    exit 1
  fi

  # Removing existing install
  local d
  for d in /etc/tlr-store/tlr /etc/tlr-store/local /var/log/tlr
  do
    rm -rf "$d"
    mkdir -p "$d"
  done
  rm -f /etc/tlr /etc/tlr-local
  ln -s tlr-store/tlr /etc/tlr
  ln -s tlr-store/local /etc/tlr-local
  
  ( cd /etc/tlr && mkdir -p scripts policies lib data data/users.d data/hosts.d data/groups.d)
}

ii_newdb="Init new database on the basis of sample data"
ll_newdb() {
  local src mode
  for src in settings.sh secrets.cfg
  do
    mode=$(awk '$1 == "#mode" { print $2 }' sample/$src)
    [ -z "$mode" ] && mode=644
    send_file --src="sample/$src" --nobackup --mode=$mode /etc/tlr/$src
  done
  if [ -f $HOME/.ssh/authorized_keys ] ; then
    send_file --src="$HOME/.ssh/authorized_keys" --nobackup /etc/tlr/data/root_keys
  elif [ -f /etc/ssh/userkeys/root/authorized_keys ] ; then
    send_file --src="/etc/ssh/userkeys/root/authorized_keys" --nobackup /etc/tlr/data/root_keys
  else
    rcmd "> /etc/tlr/data/root_keys"
  fi
}
pl_newdb() {
  sed -i~ -e "s/\"<SERVER>\"/\"$(hostname)\"/" "/etc/tlr/settings.sh"
  if [ -z "$(/etc/tlr/scripts/groupmgr list admins)" ] ; then
    /etc/tlr/scripts/groupmgr add admins
  fi
}

ckdeps() {
  local cmd rc=0
  for cmd in python3 rsync haserl httpd
  do
    type $cmd >/dev/null 2>&1 && continue
    echo "Missing: $cmd" 1>&2
    rc=1
  done
  return $rc
}

ii_update="Install/Update scripts"
ll_update() {
  rcmd "ckdeps || exit 1"
  for assets in scripts policies lib
  do
    rcmd "if [ ! -d /etc/tlr/$assets ] ; then echo \"Missing /etc/tlr/$assets\" 1>&2 ; exit 1 ; fi"
    find $assets -type f | while read asset
    do
      rcmd "mkdir -p $(dirname /etc/tlr/$asset)"
      $binder -t "$asset" | send_file --nobackup --mode=755 /etc/tlr/$asset
    done
  done
}

ii_server="Set-up target as a server"
ll_server() {
  sshout echo 'prologue_sh() {'
  sshout cat 'include/prologue.sh'
  sshout echo '}'
}
pl_server() {
  sed \
      -i~ -e 's/^\(\s*\)master="[^"]*"\(.*\)/\1master="'$(hostname)'"\2/' \
      "/etc/tlr/settings.sh"
  prologue_sh
  . /etc/tlr/settings.sh
  setup_www default /var/www/localhost/htdocs
  setup_init
  sshd_cfg_tweak
  local hosts_d=/etc/tlr/data/hosts.d
  mkdir -p $hosts_d

  find /etc/ssh -name 'ssh_host_*_key.pub' -type f -print0 \
    | xargs -0 cat > $hosts_d/$(hostname).pub
  serial_txt=/etc/tlr/data/serial.txt
  if [ ! -f $serial_txt ] ; then
    echo 0.0 > $serial_txt
  fi
  /etc/tlr/scripts/apply_policies
}

ii_setup="Set-up a brand new server (reset+update+newdb+server)"
ll_setup() {
  ll_reset ; rcmd 'pl_reset'
  ll_update
  ll_newdb ; rcmd 'pl_newdb'
  ll_server ; rcmd 'pl_server'
}

ii_migrate="Migrate from an existing server (reset+copy+update+server)"
ll_migrate() {
  if [ $# -eq 0 ] ; then
    echo "Specifying the source system is required" 1>&2
    exit 1
  fi
  local rem_src="$1" ; shift
  # Check if the source system is targetable...
  if ! ssh -o BatchMode=true "$rem_src" true ; then
    echo "Unable to access remote system" 1>&2
    exit 2
  fi
  ll_reset ; rcmd 'pl_reset'
  local eofmark="__EOF__${RANDOM}_${RANDOM}_${RANDOM}__EOF__"
  rcmd "(base64 -d | tar -C /etc/tlr -zxvf - ) <<'$eofmark'"
  ssh "$rem_src" tar -C /etc/tlr -zcf - --exclude='*~' . | sshout base64
  rcmd "$eofmark"
  ll_update
  ll_server ; rcmd 'pl_server'
}
 
sshd_cfg_tweak() {
  local sshd_config=/etc/ssh/sshd_config \
        extra_keys=/etc/ssh/userkeys/%u/authorized_keys
  if ! grep -q "$extra_keys" "$sshd_config" ; then
    echo "Updating $sshd_config"
    local ntxt="$(
	sed -e "s/^\(.*AuthorizedKeysFile\)/#TLR# \1/" -e 's/^/:/' $sshd_config
	echo ':'
	echo ":#TLR## Enabled $extra_keys for TLR deployed keys"
	echo ":AuthorizedKeysFile      .ssh/authorized_keys $extra_keys"
	)"
    echo "$ntxt" | sed -e 's/^://' | tee $sshd_config | md5sum || echo $?
  fi
}

apache_cf_edit() {
 sed \
    -e 's!#*LoadModule auth_digest_module modules/mod_auth_digest.so!LoadModule auth_digest_module modules/mod_auth_digest.so!' \
    -e 's!#*LoadModule cgid_module modules/mod_cgid.so!LoadModule cgid_module modules/mod_cgid.so!' \
    -e 's!#*LoadModule cgi_module modules/mod_cgi.so!LoadModule cgi_module modules/mod_cgi.so!' \
    -e 's!#*AddHandler cgi-script .cgi!AddHandler cgi-script .cgi!' \
    -e 's/^/:/' \
  | (
    docroot=''
    while read -r l
    do
      echo "$l"
      if (echo "$l" | grep -q '^:\s*DocumentRoot*') ; then
        # Remember the directory for later...
        docroot="$(echo "$l" | awk '{ $1 = ""; print }' | sed -e 's/^ *//')"
        #~ echo "FOUND DOCROOT: $docroot" 1>&2
        break
      fi
    done
    [ -z "$docroot" ] && exit
    while read -r l
    do
      echo "$l"
      if (echo "$l" | grep -q '<Directory' ) && (echo "$l" | grep -q "$docroot") ; then
        #~ echo "FOUND DOCROOT SETTINGS $l" 1>&2
        while read -r l
        do
          if (echo "$l" | grep -q "^:\s*Options\s") ; then
            #~ echo "FOUND OPTIONS: $l" 1>&2
            if (echo "$l" | grep -qv "ExecCGI") ; then
              echo "$l ExecCGI"
              break 2
            fi
            echo "$l"
            break 2
          fi
          echo "$l"
        done
      fi
    done
    cat
  ) | sed -e 's/^://'
}

ii_try="Try stuff out"
jl_try() {
   # Configure apache2
    
#-    Options Indexes FollowSymLinks
#+    Options Indexes FollowSymLinks ExecCGI
#-    AllowOverride None
#+    AllowOverride All

 
  :  
}

