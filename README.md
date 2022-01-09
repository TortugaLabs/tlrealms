# tlrealms

A realm/domain type system for Linux

## Quickstart

Set-up server

```
./rs --target=root@vx1 setup
ssh root@vx1
setup # sets-up demo database
```

or

```
./rs --target=root@vx1 migrate root@vms1
```

Set-up client:

On client

```
wget -O- "http://$host/tlr/enroll.cgi/me" | sh
```

On server
```
enrollmgr list
```
Look-up the `id`.
```
enrollmgr approve $id
```

Off-line enrollment:

On the installation client (as a `chroot`)
```
master=root@vx1
host=$(echo $master | cut -d'@' -f2-)
clobber=--clobber

export HOSTNAME=client TLR_STORE=/var/local/tlr OFFLINE=$master ENROLL_OPTS="$clobber"
wget -O- "http://$host/tlr/enroll.cgi/me" | sh
```

- HOSTNAME : name of the client being registered (defaults to the
  output of `hostname` but can be overriden using this environment
  variable.
- TLR_STORE : path to where persistant TLR data should be saved (/var/local/tlr)
- OFFLINE : master TLR server.  Actually it can also contain any SSH command line
  options, for example `-i ssh-private-key root@xyz`  or
  `-o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@kingdom`.
- ENROLL_OPTS : Options to pass to the enroll command.  Eg. `ENROLL_OPTS=--clobber`





## NOTES

- Add /etc/tlr-store config
  - scripts/cron
  - scripts/www-enrollme.sh.in
- Add batch enroll
- update doc
