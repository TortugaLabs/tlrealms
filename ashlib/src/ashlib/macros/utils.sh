#!/bin/sh

#####################################################################
# Misc support stuff
#####################################################################
dehumanize() {
  local scale=''
  while [ $# -gt 0 ]
  do
    case "$1" in
    -k) scale='/1024' ;;
    *) break ;;
    esac
    shift
  done
  (
    if [ $# -eq 0 ] ; then
      cat
    else
      for i in "$@"
      do
	echo "$i"
      done
    fi
  )|   awk '
	/[0-9]$/ {print $1'"$scale"';next}
	/[tT]$/ {printf "%u\n", $1*(1024*1024*1024*1024)'"$scale"';next}
	/[gG]$/ {printf "%u\n", $1*(1024*1024*1024)'"$scale"';next}
	/[mM]$/ {printf "%u\n", $1*(1024*1024)'"$scale"';next}
	/[kK]$/{printf "%u\n", $1*1024'"$scale"';next}'
}

yesno()
{
        [ -z "${1:-}" ] && return 1

        # Check the value directly so people can do:
        # yesno ${VAR}
        case "$1" in
                [Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1) return 0;;
                [Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0) return 1;;
        esac

        # Check the value of the var so people can do:
        # yesno VAR
        # Note: this breaks when the var contains a double quote.
        local value=
        eval value=\"\$$1\"
        case "$value" in
                [Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]|1) return 0;;
                [Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|0) return 1;;
                *) vewarn "\$$1 is not set properly"; return 1;;
        esac                
}
