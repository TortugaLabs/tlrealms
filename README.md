# TL Realms

This is a simple distributed config database for managing
UNIX password files.

Data is synchronized on a regular basis from a central server.

* * *

/usr/local/bin/tlr -> xx -> /usr/local/lib/tlr/bin/tlr

/usr/local/lib/tlr (TLR_BASE)
  - lib (env TLR_LIB)
  - bin (env TLR_BIN)
  - ashlib (env ASHLIB)

* * *

- TLR_CFG
  - /etc/tlr.cfg - site overrides
- TLR_DATA
  - /etc/tlr (folder or symlink)
    - TLR_DATA/settings.sh
    - TLR_DATA/secrets.sh
- TLR_LOCAL
  - /var/local/tlr-local
  - /etc/tlr-local
  - /var/lib/tlr-local

* * *



## misc

- [ ] setup
- [ ] setup-demo

## others

- autonom (bottle-api)
- www-api: enroll (busybox-extras httpd?)
- basic-auth|digest-auth : password checker (apache?)



