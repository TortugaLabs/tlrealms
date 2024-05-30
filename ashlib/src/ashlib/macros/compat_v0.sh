#!/bin/sh

#
# Legacy functions
#
wrap_file() {
  local out='' encode=false marker="/_EOF_554855_EOF_/"
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
    --output=*)
      out="${1#--output=}"
      ;;
    -o)
      if [ $# -eq 1 ] ; then
	echo "Missing value for $1" 1>&2
	exit 1
      fi
      out="$2"
      shift
      ;;
    *)
      break
      ;;
    esac
    shift
  done
  if [ -z "$out" ] ; then
    echo "Must specified output function" 1>&2
    exit 1
  fi

  local txt="${out}() {
$(if $encode ; then
  echo '('
  fi)
cat <<'$marker'
$(
if $encode ; then
  cat "$@" | gzip -9 | base64
else
  cat "$@"
fi
)

$marker
$(
if $encode ; then
  echo ') |  base64 -d | gzip -d'
fi
)
}
"
  eval "$txt"
}
wrap_pp_file_bashonly_() {
  local f=$(mktemp) args=()

  while [ $# -gt 0 ]
  do
    case "$1" in
    --encode|-b|--no-encode|-t|--output=*)
      args+=( "$1" )
      ;;
    -o)
      args+=( "$1" "$2" )
      shift
      ;;
    *)
      break
      ;;
    esac
    shift
  done
  ../tpp.sh -o$f "$@"
  wrap_file "${args[@]}"  $f
  rm -f $f
}
wrap_pp_file() { wrap_pp_file_bashonly_ "$@" ; }

