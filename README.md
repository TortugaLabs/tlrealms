# TL Realms

This is a simple distributed config database for managing
UNIX password files.

Data is synchronized on a regular basis from a central server.

* * *

/usr/local/bin/tlr -> xx -> /usr/local/lib/tlr/bin/tlr

/usr/local/lib/tlr (TLR_BASE)
  - lib
  - bin
  - ashlib

* * *

# TLR_BASE
# TLR_BIN
# TLR_LIB


/etc/tlr.cfg - site overrides TLR_CFG
/etc/tlr (folder or symlink) TLR_DATA
TLR_LOCAL
/var/local/tlr-local
/etc/tlr-local
/var/lib/tlr-local

TLR_DATA/settings.sh
TLR_DATA/secrets.sh

* * *

# usermgr

- [ ] query
- [ ] add
- [ ] del
- [ ] mod
- [ ] idmap
- [ ] passwd
- [ ] pwck
- [ ] pki

# groupmgr

- [ ] query
- [ ] add
- [ ] del
- [ ] adduser
- [ ] deluser

# misc

- [ ] setup
- [ ] setup-demo

