#!/bin/sh
[ $# -eq 0 ] && set - tlrealms.tar.gz
#
# Create base tar file
#
tarball="$1"

tar --exclude-vcs -zcvf "$tarball" \
	-C $(pwd)/base $(cd base && ls -1) \
	-C $(pwd)/.ashlib/src ashlib bin

