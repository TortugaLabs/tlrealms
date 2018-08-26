#!/bin/awk -f

#include readfile.awk

BEGIN {
  STDERR="/dev/stderr";
  NBLK="x";
  
  # Check arguments
  usage = 0;
  if (length(passwd) == 0) usage = 1;
  if (length(group_in) == 0) usage = 1;
  if (length(group_local) == 0) usage = 1;
  if (length(users) == 0) usage = 1;
  if (length(ugid) == 0) usage = 1;
  if (usage) {
     print "Must specify paramters: -vpasswd=file -vgroup_in=file -vgroup_local=file -vusers=gname -vugid=gid" > STDERR
     exit 2;
  }
  
  FS=":";

  read_file(dbpasswd, passwd);
  read_file(dbgroup, group_in);
  read_file(dblocals, group_local);

  # SANITY CHECKS
  #   - remove invalid/duplicate local groups
  for (g in dblocals) {
    if (g in dbgroup) delete dbgroup[g];
  }


  # Resolve references
  delete members;
  delete wip;

  for (g in dbgroup) {
    split(dbgroup[g],rec,":");
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
    if (!(g in dbgroup)) continue;
    split(dbgroup[g],rec,":");
    dbgroup[g] = rec[1] ":" rec[2] ":" rec[3] ":" members[g];
  }
    
  ######

  # Create users group
  dbgroup[users] = users ":" NBLK ":" ugid ":";
  q = "";

  # Add UPGs...
  for (u in dbpasswd) {
    split(dbpasswd[u],rec,":");

    dbgroup[u] = u ":" NBLK ":" rec[4] ":" u;
    dbgroup[users] = dbgroup[users] q u;
    q = ",";
  }
  for (g in dbgroup) {
    print dbgroup[g];
  }
  

  exit;
}
