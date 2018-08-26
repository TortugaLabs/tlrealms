#!/bin/sh
mydir=$(dirname $(readlink -f "$0"))
export PATH=$PATH:$mydir/../scripts

set -euf -o pipefail

. $mydir/lib.sh
. $mydir/common.sh

### START-INCLUDE-SECTION ###

doit() {
  local \
	pw_uid="" \
	pw_gid="" \
	pw_gecos="" \
	pw_dir="" \
	pw_shell="/sbin/nologin" \
	sp_min=0 \
	sp_max=99999 \
	sp_warn=7 \
	sp_inact=""
  [ -f "$TLR_DATA/shadow.cfg" ] && . "$TLR_DATA/shadow.cfg"

  find $TLR_DATA/users.d -name '*.cfg' | ( while read f
  do
    local n=$(basename $f .cfg)
    local pp="$TLR_DATA/users.d/$n.pwd"
    [ ! -f "$pp" ] && continue
    local pwdchg=$(expr $(date -r "$pp" +%s) / 86400)
    (
      . "$f"
      echo "$n:x:$pw_uid:$pw_gid:$pw_gecos:$pw_dir:$pw_shell:$pwdchg:$sp_min:$sp_max:$sp_warn:$sp_inact:$pp"
    ) 
  done) | awk \
	-vpasswd="../etc/passwd" \
	-vgroup="../etc/group"  \
	-vshadow="../etc/shadow" \
	-vr_group="../sample/group" \
	'
	function read_file(dbfile, fname, minid) {
	  delete dbfile;
	  while ((getline < fname) > 0) {
	    if (length($0) == 0) continue;
	    if (substr($0,0,1) == "#") continue;
	    if (minid > 0) {
	      if ($3 >= minid) continue;
	    }
	    dbfile[$1] = $0;
	  }
	  close(fname);
	}
	function read_pwds(dbfile, fname) {
	  delete dbfile;
	  while ((getline < fname) > 0) {
	    if (length($0) == 0) continue;
	    if (substr($0,0,1) == "#") continue;
	    dbfile[$1] = $2;
	  }
	  close(fname);
	}
	function read_shadow(dbfile, fname, users) {
	  delete dbfile;
	  while ((getline < fname) > 0) {
	    if (length($0) == 0) continue;
	    if (substr($0,0,1) == "#") continue;
	    if (length(users[$1]) == 0) {
	      delete users[$1];
	      continue;
	    }
	    dbfile[$1] = $0;
	  }
	  close(fname);
	}
	function dump_file(dbfile) {
	  for (j in dbfile) {
	    print dbfile[j];
	  }
	}
	function cmp_ent(i1,v1,i2,v2,l,r) {
	  split(v1,l,":");
	  split(v2,r,":");
	  #~ print l[3] " <=> " r[3];
	  if ((l[3]+0) < (r[3]+0))
	    return -1
	  else if ((l[3]+0) == (r[3]+0))
	    return 0
	  else
	    return 1
	}
    BEGIN {
      FS=":";
      STDERR="/dev/stderr";
      NBLK="x";
  
      # Check arguments
      usage = 0;
      if (length(passwd) == 0) passwd = "/etc/passwd";
      if (length(group) == 0) group = "/etc/group";
      if (length(shadow) == 0) shadow = "/etc/shadow";
      if (length(min_id) == 0) min_id = 2000;
      if (length(users) == 0) users = "users";
      if (length(ugid) == 0) ugid = 2000;

      if (length(r_group) == 0) usage = 1;
      if (usage) {
	print "Must specify parameters: -vr_group=file" > STDERR
	exit 2;
      }
      read_file(dbpasswd, passwd, min_id);
      read_file(dbgroup, group, min_id);
      read_shadow(dbshadow, shadow, dbpasswd);
      read_file(dbgroup_r, r_group, 0);
      
      # SANITY CHECKS
      #   - remove invalid/duplicate local groups
      for (g in dbgroup) {
	if (g in dbgroup_r) delete dbgroup_r[g];
      }

      # Resolve references
      delete members;
      delete wip;

      for (g in dbgroup_r) {
	split(dbgroup_r[g],rec,":");
	members[g] = rec[4];
	if (index(rec[4],"@") > 0) {
	  wip[g] = 1;
	}
      }
      
      iloop = 0;
      do {
	redo = 0;
	delete undefs;
	iloop++;
	for (g in wip) {
	  split(members[g],rec,",");
	  ng = ""; q = ""; pending = 0;
	  for (u in rec) {
	    u = rec[u];
	    if (substr(u,1,1) == "@") {
	      u = substr(u,2,length(u)-1);
	      if (u in wip) {
		# This one  still needs to be resolved.
		redo = 1;
		pending++;
		ng = ng q "@" u;
		undefs[u] = u;
	      } else {
		if (u in members) {
		  if (length(members[u]) > 0) {
		    ng = ng q members[u];
		    q = ",";
		  }
		} else {
		  print "Missing reference: @" u > STDERR;
		}
	      }
	    } else {
	      ng = ng q u;
	      q = ",";
	    }
	  }
	  members[g] = ng;
	  if (pending == 0) {
	    delete wip[g];
	    iloop = 0;
	  }
	}
      } while (redo && iloop < 2);
      if (iloop > 1) {
	print "Circular references: " > STDERR;
	for (u in undefs) print "\t" u > STDERR;
	exit 3;
      }
      # Remove duplicates...
      for (g in members) {
	split(members[g],rec,",");
	delete urec;
	for (u in rec) {
	  u = rec[u];
	  urec[u] = u;
	}
	ng = ""; q = "";
	for (u in urec) {
	  ng = ng q u;
	  q = ",";
	}
	members[g] = ng;
      }

      for (g in members) {
	if (!(g in dbgroup_r)) continue;
	split(dbgroup_r[g],rec,":");
	dbgroup_r[g] = rec[1] ":" rec[2] ":" rec[3] ":" members[g];
      }
	
      ######

    }
    {
      #$n:x:$pw_uid:$pw_gid:$pw_gecos:$pw_dir:$pw_shell:$pwdchg:$sp_min:$sp_max:$sp_warn:$sp_inact:$pp"
      # 1:2:3      :4      :5        :6      :7        :8      :9      :10     :11      :12       :13
      dbgroup_r[$1] = $1 ":" NBLK ":" $4 ":";
      dbpasswd[$1] = $1 ":" NBLK ":" $3 ":" $4 ":" $5 ":" $6 ":" $7;
      
      cuser = $1;
      cpwd = $13;
      cshadow = $8 ":" $9 ":" $10 ":" $11 ":" $12 "::";
      
      read_pwds(pwds, cpwd);
      dbshadow[cuser] = cuser ":" pwds["unix"] ":" cshadow;
      
      if (length(dbgroup_r[users]) == 0) {
	dbgroup_r[users] = users ":" NBLK ":" ugid ":" cuser;
      } else {
	dbgroup_r[users] = dbgroup_r[users] "," cuser;
      }
    }
    END {
      asort(dbpasswd,dbpasswd,"cmp_ent");
      asort(dbgroup,dbgroup,"cmp_ent");
      asort(dbgroup_r,dbgroup_r,"cmp_ent");
      print "pass\nwd";
      print "======";
      j=length(dbpasswd);
      for (i=1;i<=j;i++) {
	print dbpasswd[i];
      }
      
      #~ dump_file(dbpasswd);
      #~ print "shadow";
      #~ print "======";
      #~ dump_file(dbshadow);
      #~ print "group";
      #~ print "=====";
      #~ dump_file(dbgroup);
      #~ dump_file(dbgroup_r);
    }
    '
  
  
}



### END-INCLUDE-SECTION ###

#~ u_passwd ../sample "$@"
#~ gen_pwds ../sample htpasswd
#~ gen_pwds ../sample htdigest
#~ gen_shadow ../sample shadow.txt
#~ gen_etcpasswd ../sample > passwd.txt
#~ gen_group ../sample passwd.txt
#~ gen_group ../sample passwd.txt | gen_htgrp
#~ gen_group ../sample passwd.txt | gen_admin_keys ../sample "alfheim"
#~ new_user ../sample
#~ def_passwd
#~ u_chpasswd ../sample hella


doit
