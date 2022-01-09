#!/bin/sh
#
# Run this from cron job
#
include -1 fixfile.sh

if ! is_master ; then
  $TLR_BIN/tlr rpc rsync
fi

[ -f $TLR_DATA/admin_keys ] \
	&& fixfile --mode=600 /etc/ssh/userkeys/root/admin_keys < $TLR_DATA/admin_keys || :

is_master && $TLR_BIN/tlr genfiles host-keys /etc/ssh/userkeys/root/host_keys

$TLR_BIN/tlr genfiles groups --group --gshadow
#$TLR_BIN/tlr genfiles htgroup $TLR_LOCAL/htgroup
#$TLR_BIN/tlr genfiles nginx-grps $TLR_LOCAL/nginx.d

$TLR_BIN/tlr genfiles users --passwd --shadow
#$TLR_BIN/tlr genfiles htpasswd $TLR_LOCAL/htpasswd
#$TLR_BIN/tlr genfiles htdigest $TLR_LOCAL/htdigest
#$TLR_BIN/tlr genfiles htgroup $TLR_LOCAL/htgroup

#$TLR_BIN/tlr genfiles nginx-grps $TLR_LOCAL/nginx.d

#$TLR_BIN/tlr genfiles ident-sso $TLR_LOCAL/ident_sso.map
#$TLR_BIN/tlr genfiles social-map $TLR_LOCAL/social-logins.map

