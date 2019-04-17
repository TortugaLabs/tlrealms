# tlrealms

A realm/domain type system for Linux

## Quickstart

Set-up server

```
./dpl root@vms1
ssh root@vms1
/etc/tlr/scripts/setup www
/etc/tlr/scripts/setup demo
/etc/tlr/scripts/setup init
usermgr passwd arthur $passwd

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

