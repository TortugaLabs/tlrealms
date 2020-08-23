# TL Realms

This is a simple distributed config database for managing
UNIX password files.

Data is synchronized on a regular basis from a central server.

## Sprint



## Backlog

- devtools
  - test infrastructure
  - soft dependancy on ashlib
  - travis-ci
- plist management
  - <key><spc><value>
  - `awk '{$1="";$0=$0;$1=$1}1'`
- self-configuration
  - Directory to transfer
  - location of lib files + ashlib
  - location of bin files
  - environment overrides
- file-transfer
  - fixup sshd-config
  - rsync force command
- rpc-ops
  - rpc-ops force command
- hosts db
  - host enrollment
    - host pre-load
    - host post-reg
- user db
- mkpasswd: use python3 or openssl_passwd
- snippets
  - migrate from src to dst
  - newdb
  - reset existing db
  - host setup
  - host update
  - backup
  - restore from backup

