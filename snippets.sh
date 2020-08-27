#!/bin/sh
include_once $ashlib/macros/snippetlib.sh

prepare_dist() {
  local w="$1"
  mkdir -p $w/ashlib
  tar --exclude-vcs -cf - -C $ashlib . | tar -xf - -C $w/ashlib
  tar --exclude-vcs -cf - -C $mydir/base . | tar -xf - -C $w
}



ii_try="Try stuff out"
jl_try() {
  :
  local w=$(mktemp -d) rc=0
  (
    prepare_dist "$w/tlr"
    #~ mkdir -p $w/ashlib/tlr $w/base
    #~ ln -s $ashlib $w/ashlib/tlr/ashlib
    #~ ln -s $mydir/base $w/base/tlr
    find $w -ls
    #~ tar --exclude-vcs -zvcf - -C $w/base tlr/. -C $w/ashlib tlr/ashlib/. \
	#~ | md5sum

  ) || rc=$?
  rm -rf "$w"
  return $rc
}

