#!/bin/awk -f
BEGIN { FS=":"; OFS=":" }
/^[ \t]*$/ { next }
/^[ \t]*#/ { next }
/^[^#]/ { printf ".%s ", $1; print;
	     printf "=%s ", $3; print;
	     if ($4 != "") {
	       split($4, grmems, ",");
	       for (memidx in grmems) {
		 mem=grmems[memidx];
		 if (members[mem] == "")
		   members[mem]=$3;
		 else
		   members[mem]=members[mem] "," $3;
	       }
	       delete grmems; } }
END { for (mem in members) printf ":%s %s %s\n", mem, mem, members[mem]; }
