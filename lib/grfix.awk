#!/bin/awk -f

#include readfile.awk

BEGIN {
  # Check arguments
  STDERR="/dev/stderr";
  
  usage = 0;
  if (length(gshadow) == 0) usage = 1;
  if (usage) {
     print "Must specify parameters: -vgshadow=file" > STDERR
     exit 2;
  }  
  FS=":";  
  read_file(gshadowdb, gshadow);
}

{
  if ((length(min) == 0 || $3 < min)&&(length(max)==0 || $3 > max)&&(length(dbshadow[$1]) > 0))  {
    print dbshadow[$1];
  } else {
    print $1 ":!::" $4;
  }
}
