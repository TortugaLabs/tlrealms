#!/bin/sh
#
## This file contains utilities used to manipulate user passwd/group
## files
##

_edit_file() {
  ## Called by set_line
  local \
      file=$1 \
      key=$2 \
      id=$3 \
      val="$4"
  (
      awk -F: '$'$key' != "'$id'" { print }' $file
      [ -n "$val" ] && echo "$val"
  ) | sort
}


set_line() {
  ## Changes a line in the file
  ## # USAGE
  ##    set_line file key id val
  ## # ARGS
  ## * file -- file being edited
  ## * key -- column used as key field
  ## * id -- id to replace
  ## * val -- new line to insert
  ## # DESC
  ## The file `file` is updated.
  local \
      file=$1 \
      key=$2 \
      id=$3 \
      val="$4"

  local s="$(cat $file)"
  local d="$(_edit_file $file $key $id "$val")"
  [ x"$s" = x"$d" ] && return
  cp $file $file~
  echo "$d"  | grep -v '^$' >$file
}

get_litem() {
  ## Gets a field from a line
  ## # USAGE
  ##    get_litem line key
  ## # ARGS
  ## * line -- line to query
  ## * key -- field to retrieve
  local \
      line="$1" \
      key=$2
  echo "$line"  | cut -d: -f$key
}

set_litem() {
  ## Modifies a line item
  ## # USAGE
  ##     set_litem line key val
  ## # ARGS
  ## * line - line to modify
  ## * key - field to modify
  ## * val -- value to replace the field with
  local \
      line="$1" \
      key=$2 \
      val="$3"
  echo "$line" | sed 's/:/\n:/g' | (
      i=0
      q=''
      while read ln
      do
	i=$(expr $i + 1)
	if [ $i -eq $key ] ; then
	  echo $q$val
	else
	  echo $ln
	fi
	q=:
      done) | tr -d '\n'
  echo
}

get_item() {
  ## Get an item from file
  ## # USAGE
  ##     get_item file key id [sub]
  ## # ARGS
  ## * file -- file to query
  ## * key -- column used as the key field
  ## * id -- id to look-up
  ## * sub -- key field to return
  local \
      file=$1 \
      key=$2 \
      id=$3 \
      sub=$4
  [ -n "$sub" ] && sub="\$$sub"
  awk -F: '$'$key' == "'$id'" { print '$sub' }' $file
}

pick_id() {
  :
  ## Pick the next avialable id
  ## # USAGE
  ##     pick_id file key min max
  ## ARGS
  ## * file -- file to check
  ## * key -- column used as key field
  ## * min -- initial value
  ## * max -- max value
  local \
      file="$1" \
      key="$2" \
      min="$3" \
      max="$4"

  local cnt=$min

  while [ -n "$(get_item $file $key $cnt)" ]
  do
    cnt=$(expr $cnt + 1)
    [ $cnt -gt $max ] && return
  done
  echo $cnt
}

parse_date() {
    ## Parse a date in YYYY-MM-DD format
    ## # USAGE
    ##     parse_date YYYY-MM-DD
    local seconds=$(date -d "$1 00:00" +'%s')
    [ -z "$seconds" ] && return 1
    expr $seconds / 86400
    return
}

format_date() {
  ## Convert a date in days since epoch into a YYYY-MM-DD string
  echo 'print(os.date("%Y-%m-%d",'$1'* 86400))' | lua

}
