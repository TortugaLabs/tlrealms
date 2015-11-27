# TL Realms

This is a lightweight directory like service with kerberos
compatibility and uses UNIX standard db password files.

Data is synchronized on a regular basis from a central server.

## Core functionality

- kerberos password
- user database (like an offline central directory)
    - passwd/shadow/group
- ssh
   - central known_hosts
   - admin keys
- sync passwords
    - htdigest : for http digest authentication
    - pwds : is the actual password hash (shadow data is populated
      from this also usable for http basic authentication)
- admin support
    - op.pwds (for use with pam_pwdfile) for secure passwords
    - *TODO:* Central `sudores`.
- secret store `secrets.txt` for `msys` and `tlcfg`.

### NOTES

1. Group definitions allow nested groups (@groupname notation)
2. User own group automatically generated
2. NFS only supports up to 16 groups, Linux 32 groups.

# Server

## Configuration

1. Follow the standard OpenWRT Kerberos configuration
    [howto](http://wiki.openwrt.org/doc/howto/kerberos).
2. Configure /opt/tlr/lib/config.sh
3. Modify /opt/tlr/lib/sysupd.sh
4. Add groups
   * shadm groupadd <group>
5. Add users
   * shadm useradd <user>
   * chpwd <user>
6. Configure admins
7. Add hosts

## Usage

* `adm`  
   This is the main admin command.  Available sub-commands:
   * adm shell - Enter a shell mode.  
     This shell mode is intended for remote applications.
   * adm host - manage host keys using `khfm`
   * adm admins - manage admin keys with `khfm`
   * adm setpwd [user] - set user passwords
   * adm admpw - change admin pwd
   * adm krb [shortcut] - Execute Kerberos shortcuts
     * ls - list principals
     * adduser [user] - add    user
     * deluser [user] - delete user
   * adm sysgen - update system files
   * `khfm`  
     This command is used to managed key files.  Sub commands:
     * khfm add hostname *keyline*  
       Adds hostname keys.  If *keyline* is not specified it is read
       for stndard input.
     * khfm ls [-l] - List keys
     * khfm find host *type* - find keys for host
     * khfm rm host
* `hostkey`  
  This command is the ssh force command for host keys.
* `shadm`  
  This is a shadow utils like command interface.
* `chpwd`  
  change password utility

# Client

* chpwd - TK interface to change password
* tlr-agent - Background task that syncs with the domain controller
* tlr-adm - wrapper that runs adm on the domain controller
* tlr-ed - wrapper that lets you modify files in the domain
  controller.  `tlr-ed` would download config files to the local system
  and run the specified command on them.  When the command exists,
  changes are sent to the domain controller.
* pwfix - mk and pl, scripts to update system files when data changes.

# Use cases

## Updating users

## Adding/Removing hosts

This command is used to add a new _host_ to the realm.

    cat /etc/ssh/*.pub |  ssh root@domain_controller adm host add `hostname`

## admin management

This command is used to add a new _admin_ key to the realm:

    cat $HOME/.ssh/id_rsa.pub \
    	| ssh root@domain_controller adm admins add <user>

## SSO

# ID name space

* Normal users: 2000 - 9999
* System domain groups: 10000 - 10999
* Normal groups: 11001 - 19999
  * users: 11000
* System domain accounts: 500 - 999
* System local accounts: 100 - 499

## Local configuration

* users
  * alex: 2001
* normal groups
  * admins: 11001
  * liuli: 11002
  * finance: 11003
  * homeuser : 11004
* system domain groups
  * vmadm: 10001

# Managed Files

Data is located in `/etc/tlr-data`.  The following files are used:

* admin_keys  
  Contains the `ssh` keys for users with root access.
* group  
  Input `group` file.  Includes `@` extensions and lacks auto
  generated user groups.
* htdigest (0400)  
  User with apache `htdigest` passwords.
* known_hosts  
  Containts the `ssh` public keys for known hosts.  This is for:
  1. takes over the prompt to confirm new `known_hosts`.
  2. Used by forced command so that hosts can update database.
* secrets.cfg (0640)  
  Contain pre-shared secrets.  This is configured as shell variables.
* op.pwds (0400)  
  Allow admins to have a normal user password and a priviledge password.
* passwd  
  Contains `/etc/passwd` data.
* pwds,0400  
  Contains the actual passwords.
* shadow  
  Contains shadow data like expiration, etc, but not the actual
  password (for that, see `pwds`)



# TODO

* BUG: empty lines appeared (adding user pwds after initial install
  and also admpw)
* backup or replication
* sudoers
* gui
  - gnome system tools (as an example? for UI design)
  - General process:
    * download files
    * make changes
    * upload files

# Notes

## KERBEROS STUFF

principals at start:

* K/M@<domain>
* kadmin/admin@<domain>
* kadmin/changepw@<domain>
* kadmin/history@<domain>
* kadmin/<hostname>@<domain>
* krbtgt/<domain>@<domain>


* * *

- groupmems - admin group members
- groupadd - create new group
- useradd - create new user
- userdel - delete user account
- groupdel - delete group
- chage - change user password expiry info
- usermod - modify user account
- groupmod - modify group settings

1 - user
2 - passwd
3 - date of last change (0 - expired)
4 - min password age
5 - max password age
6 - warning period (usually 7)
7 - inactivity (empty means disabled this feature)
8 - expiration date (days since 1970)
9 - reserved




NO:

* gpasswd - administer /etc/group + /etc/passwd
* expiry - check & enforce pwd expiration policy
* grpck - verify integrity of group files
* newusers - update/create users in batch
* pwck - verify integrity of pwd files
* chgpasswd - update group passwd in batch
* chpasswd - update passwd in batch
* faillog - display failed logins
* groups - display current group names
* lastlog - most recent loging of all users or a given user
* sg - execute command as differeng gid
* pwconv, pwunconv, grpconv, grpunconv - convert to and from shaddow
  passwords and groups
* newgidmap - dont get it
* newuidmap - gont get it

* * *

### KUSER

- menu
  - user
    - add
    - edit
    - delete
    - set pwd
  - group
    - add
    - edit
    - delete

TOOLBAR: Add User, Add Group, Edit, Delete, ?Reload?


* TABS (users|groups)
  * List:
    * UID | Username | Full name | Home | Shell |
    * GID | Group name |
  * ADD|EDIT GROUP
    * GrpId [ ]
    * GrpName [ ]
    * [Users In Group] <-> [Users Not in Group]
    * [ ok ] [cancel ]
  * ADD|EDIT USER
Tabs (User Info|Groups)
User login: <user> [Set Passwd]
User Id:
Full Name:
Login shell:
Home folder:
Account: disabled|x]

Group Tab
[_] group

Primary Group: <>

----
