#!/bin/awk -f

#include readfile.awk

BEGIN {
  # Check arguments
  STDERR="/dev/stderr";
  
  usage = 0;
  if (length(shadow) == 0) usage = 1;
  if (usage) {
     print "Must specify parameters: -vshadow=file -vmin=num -vmax=num" > STDERR
     exit 2;
  }  
  FS=":";  
  read_file(dbshadow, shadow);
}

{
  if ((length(min) == 0 && length(max) == 0) || (length(min) > 0 && $3 < min) || (length(max) > 0 && $3 > max)) {
    if (length(dbshadow[$1]) > 0) print dbshadow[$1];
  }  
}
