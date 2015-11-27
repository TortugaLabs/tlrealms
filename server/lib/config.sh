#
# Configuration
#
lockfile=/tmp/tlr.lock

authkeys_opts="no-agent-forwarding,no-port-forwarding,no-pty,no-X11-forwarding"

crypt="lua $lib/crypt.lua"

etcdir=/etc
dbdir=$etcdir/tlr-data

# PWD Files
pwdfile=$dbdir/pwds
htdigest=$dbdir/htdigest
kadmin=kadmin.local
shadow=$dbdir/shadow
htrealm=$(
  if [ -f /etc/krb5.conf ] ; then
    grep default_domain /etc/krb5.conf | tr -d '	 ' \
      | sed -e 's/^default_domain=//'
  else
    echo 'nodomain'
  fi
)

sys_authkeys=$etcdir/dropbear/authorized_keys
sys_knownhosts=$etcdir/dropbear/known_hosts
hostkey_cmd=$(which hostkey)

