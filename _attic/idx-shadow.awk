#!/bin/awk -f
BEGIN { FS=":"; OFS=":" }
/^[ \t]*$/ { next }
/^[ \t]*#/ { next }
/^[^#]/ { printf ".%s ", $1; print }
