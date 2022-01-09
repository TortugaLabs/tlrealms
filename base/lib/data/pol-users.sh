#!/bin/sh
#
# Apply this policy when user data changes...
#
polrun_update_serial

# $TLR_BIN/tlr genfiles users --passwd --shadow
# $TLR_BIN/tlr genfiles groups --group --gshadow

# $TLR_BIN/tlr genfiles htpasswd $TLR_LOCAL/htpasswd
# $TLR_BIN/tlr genfiles htdigest $TLR_LOCAL/htdigest
# $TLR_BIN/tlr genfiles htgroup $TLR_LOCAL/htgroup

# $TLR_BIN/tlr genfiles nginx-grps $TLR_LOCAL/nginx.d

# $TLR_BIN/tlr genfiles ident-sso $TLR_LOCAL/ident_sso.map
# $TLR_BIN/tlr genfiles social-map $TLR_LOCAL/social-logins.map



