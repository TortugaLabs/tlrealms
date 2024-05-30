#!/bin/sh

#####################################################################
# Deploy files
#####################################################################
tags2awk_target() {
  cat <<-'_EOF_'
	BEGIN { path="" ; FS=":"}
	END { if (path != "") { print path } }
	$1 ~ "target" && $2 == "" { path = $3 }
	_EOF_
  local i
  for i in "$@"
  do
    echo "\$1 ~ \"target\" && \$2 == \"$i\" { print \$3; exit }"
  done
}
tags2re_find() {
  echo -n '[: \t]('
  echo -n default "$@" | tr ' ' '|'
  echo -n ')\b'
}
find_tagged() {
  local dir="$1" ; shift
  find "$dir" -path "$dir/.git" -prune -o -type f -print0 | xargs -0 grep '[# \t]tags[:]' \
  	| grep -E "$(tags2re_find "$@")" | cut -d: -f1
}
send_file() {
  local encode=false src=''
  while [ $# -gt 0 ]
  do
    case "$1" in
    --encode|-b)
      # Encode binary data
      encode=true
      ;;
    --no-encode|-t)
      # just text data
      encode=false
      ;;
    --src=*)
      src=${1#--src=}
      ;;
    -s*)
      if [ -z "${1#-s}" ] ; then
        src="$2" ; shift
      else
        src="${1#-src}"
      fi
      ;;
    *)
      break
      ;;
    esac
    shift
  done
  local eofmark="__EOF__${RANDOM}_${RANDOM}_${RANDOM}__EOF__"
  if $encode ; then
    rcmd "(fixfile --decode $* || :)  <<'$eofmark'"
    (
      if [ -n "$src" ] ; then
	gzip -9 < "$src"
      else
	gzip -9
      fi
    ) | sshout base64
  else
    rcmd "(fixfile $* || :)  <<'$eofmark'"
    if [ -n "$src" ] ; then
      sshout cat "$src"
    else
      sshout cat
    fi
  fi
  rcmd ''
  rcmd "$eofmark"
}
get_tagged_target() {
  local src="$1" ; shift
  local fpath=$(awk "$(tags2awk_target "$@")" $src)
  [ x"${fpath: -1}" = x"/" ] && fpath="$fpath$(basename "$src")"
  echo $fpath
}

send_assets() {
  local encode=""
  if [ x"$1" = x"-b" ] || [ x"$1" = x"--encode" ] ; then
    encode="-b"
  fi
  local dir="$1" ; shift
  local mode='' fpath=''
  find_tagged "$dir" "$@" | while read ff
  do
    mode=$(grep 'mode:[ \t]*' "$ff" | cut -d: -f2) || :
    fpath=$(get_tagged_target "$ff" $tags)
    [ -n "$mode" ] && mode="--mode=$mode"
    send_file $encode --src="$ff" --nobackup $mode $fpath
  done
}
f_filter() {
  local in="$1" ff ; shift
  for ff in "$@"
  do
    (echo "$b" | grep -q "$ff") && return 0
  done
  return 1
}
