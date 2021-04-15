#!/bin/sh

#
# Create base tar file
#
tarball="demo.tar.gz"
tmp1=$(mktemp -d) ; trap "rm -rf $tmp1" EXIT

mkdir -p $tmp1/perms/ashlib
mkdir -p $tmp1/links
ln -s $(realpath -e .ashlib) $tmp1/links/ashlib

ls -l $tmp1/links

tar --exclude-vcs -zcvf "$tarball" \
	-C base $(cd base && ls -1) \
	-C $tmp1/perms ashlib \
	-C $tmp1/links $(cd $tmp1/links ; echo ashlib/*)

