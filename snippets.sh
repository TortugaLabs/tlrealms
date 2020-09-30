#!/bin/sh
include_once $ashlib/macros/snippetlib.sh

prepare_dist() {
  local w="$1"
  mkdir -p $w/ashlib
  tar --exclude-vcs -cf - -C $ashlib . | tar -xf - -C $w/ashlib
  tar --exclude-vcs -cf - -C $mydir/base . | tar -xf - -C $w
}

ii_update="Update/install software"
ll_update() {
  local w=$(mktemp -d) rc=0
  (
    rcmd '[ -f /etc/tlr.cfg ] && . /etc/tlr.cfg'
    rcmd '[ -z "${TLR_BASE:-}" ] && export TLR_BASE="/usr/local/lib/tlr"'

    # OK, unpack to an adjacent directory....
    rcmd 'tm=$(mktemp -p $(dirname $TLR_BASE) -d)'
    prepare_dist "$w/tlr"
    rcmd '(base64 -d | tar -C $tm -zxvf - ) <<_EOF_'
    tar --exclude-vcs -zcf - -C "$w" tlr | sshout base64
    rcmd ''
    rcmd '_EOF_'

    # Replace old with new...
    rcmd '[ -d $TLR_BASE ] && mv $TLR_BASE $tm/old'
    rcmd 'mv $tm/tlr $TLR_BASE'

    rcmd 'rm -rf $tm'
  )  || rc=$?
  rm -rf "$w"

 return $rc
}
pl_update() {
  echo BASEDIR=${TLR_BASE:=/usr/local/lib/tlr}
  echo BINDIR= ${TLR_BIN:=$(dirname $(dirname "$TLR_BASE"))/bin}
  local tag="ooGhof7pCai4giedAenie1ooih1CheexahM8nah3"

  find $TLR_BASE/bin -maxdepth 1 -type f | (
    m="" q=""
    while read f
    do
      local cmd=$(basename "$f") args='"$@"'
      [ -L "$TLR_BIN/$cmd" ] && rm "$TLR_BIN/$cmd"

      ( fixfile --mode=755 "$TLR_BIN/$cmd" || : ) <<-_EOF_
	#!/bin/sh
	# $tag
	exec $f $args
	_EOF_
      m="$m$q$cmd" ; q=" "
    done
    echo "$m"
    find $TLR_BIN -maxdepth 1 -type f | (
      while read f
      do
        cmd=$(basename "$f")
	for z in $m ""
	do
	  [ -z "$z" ] && break
	  [ $z = $cmd ] && break
	done
	[ -n "$z" ] && continue
	if grep -q "$tag" "$f" ; then
	  # matched
	  rm -v "$f"
	fi
      done
    )
  )

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

