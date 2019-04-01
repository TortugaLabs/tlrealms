#!/bin/sh
#
# General settings
#
master="<SERVER>"
domain=the-kingdom

#
# Default shadow settings
#
sp_min=0
sp_max=99999
sp_warn=7
sp_inact=""

#
# Realm login.defs
#
GID_MIN=11000
UID_MIN=2000
XID_MAX=65500

GID_USERS=11000
GNAME_USERS=users

#~ if [ -f $TLR_HOME/site-settings.sh ] ; then
  #~ . $TLR_HOME/site-settings.sh
#~ fi

# Examples
#
# add_role host1 role-a role-b role-c
# add_role host2 host3 host4 : role-a role-b role-c
# add_host role-a host1 host2 host3
