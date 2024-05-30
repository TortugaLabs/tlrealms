#!/bin/sh
#
# Copyright (c) 2018-2020 Alejandro Liu
# Licensed under the MIT license:
#
# Permission is  hereby granted,  free of charge,  to any  person obtaining
# a  copy  of  this  software   and  associated  documentation  files  (the
# "Software"),  to  deal in  the  Software  without restriction,  including
# without  limitation the  rights  to use,  copy,  modify, merge,  publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons  to whom  the Software  is  furnished to  do so,  subject to  the
# following conditions:
#
# The above copyright  notice and this permission notice  shall be included
# in all copies or substantial portions of the Software.
#
# THE  SOFTWARE  IS  PROVIDED  "AS  IS",  WITHOUT  WARRANTY  OF  ANY  KIND,
# EXPRESS  OR IMPLIED,  INCLUDING  BUT  NOT LIMITED  TO  THE WARRANTIES  OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR  OTHER LIABILITY, WHETHER  IN AN  ACTION OF CONTRACT,  TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
pp() {
  ## Pre-processor
  ## USAGE
  ##	pp < input > output
  ## DESC
  ## Read some textual data and output post-processed data.
  ##
  ## Uses HERE_DOC syntax for the pre-processing language.
  ## So for example, variables are expanded directly as `$varname`
  ## whereas commands can be embedded as `$(command call)`.
  ##
  ## As additional extension, lines of the form:
  ##
  ## ```
  ## ##! command
  ## ```
  ##
  ## Are used to include arbitrary shell commands.  These however
  ## are executed in line (instead of a subshell as in `$(command)`.
  ## This means that commands in `##!` lines can be used to define
  ## variables, macros or include other files.
  ##
  local eof="$$"
  eof="EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF"

  eval "$(sed -e 's/^/:/' | (
    mode='shell'
    while read -r line
    do
      if (echo "$line" | grep -q '^:[ \t]*##!') ; then
	: "found ##! cmode $mode"
	case "$mode" in
	shell)
	  echo "$line" | sed -e 's/\(^:[ \t]*\)##!/\1/'
	  ;;
	heredoc)
	  echo ":$eof"
	  echo "$line" | sed -e 's/\(^:[ \t]*\)##!/\1/'
	  mode="shell"
	  ;;
	esac
      else
	case "$mode" in
	shell)
	  echo ":cat <<$eof"
	  echo "$line"
	  mode="heredoc"
	  ;;
	heredoc)
	  echo "$line"
	  ;;
	esac
      fi
    done
    [ "$mode" = "heredoc" ] && echo ":$eof"
    ) | sed -e 's/^://'
  )"
}

ppSimple() {
  ## Pre-processor
  ## USAGE
  ##	ppSimple < input > output
  ## DESC
  ## Read some textual data and output post-processed data.
  ##
  ## Uses HERE_DOC syntax for the pre-processing language.
  ## So for example, variables are expanded directly as `$varname`
  ## whereas commands can be embedded as `$(command call)`.
  local eof="$$"
  eof="EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF_${eof}_EOF"
  local txt="$(echo "cat <<$eof" ; cat ; echo '' ;echo "$eof")"
  eval "$txt"
}

sppinc() {
  local oPATH="$PATH" f inc

  for inc in "$@"
  do
    f="$(find_in_path "$inc")"
    if [ -z "$f" ] ; then
      echo "$inc: not included" 1>&2
      continue
    fi
    local __FILE__="$f" __DIR__="$(dirname "$f")"
    export PATH="$oPATH:.:$(dirname "$f")"
    . "$f"
  done
  export PATH="$oPATH"
}

ppCmd() {
  ## Command line `pp` driver
  ##
  ## USAGE
  ##	ppCmd [--output=output] -Iinclude-path -Dcmd file.m.ext ...
  ## DESC
  ## Implements a command line interface for the `pp` function
  ##
  ## Input files of the form `file.m.ext` are then pre-processed and
  ## the result is named `file.ext`.
  ##
  if [ $# -eq 0 ] ; then
    echo "Usage: $0 {input.m.ext} ..."
    exit 1
  fi

  output=''
  query=''
  while [ $# -gt 0 ]
  do
    case "$1" in
    -o*)
      if [ -z "${1#-o}" ] ; then
	output="$2" ; shift
      else
	output="${1#-o}"
      fi
      ;;
    --output=*)
      output="${1#--output=}"
      ;;
    --query=*)
      query="${1#--query=}"
      [ -z "$output" ] && output="-"
      ;;
    -L)
      if [ $# -lt 2 ] ; then
        echo "No argument specified for -L"
        exit 2
      fi
      . "$2"
      shift
      ;;
    -L*)
      . "${1#-L}"
      ;;
    -I*)
      export PATH="$PATH:${1#-I}"
      ;;
    -D*)
      eval "${1#-D}"
      ;;
    *)
      break
      ;;
    esac
    shift
  done

  rc=0
  done='[OK]'
  if [ -n "$output" ]  ; then
    name=$(basename "$output" | tr A-Z a-z | sed -e 's/^\([_a-z0-9]*\).*$/\1/')
    [ x"$output" != x"-" ] && exec > "$output"

    if [ -n "$query" ] ; then
      set -
      if ! (export PATH="$(pwd):$PATH" ; echo "$query" | pp ) ; then
	rc=1
	done='[ERROR]'
      fi
    fi
    for input in "$@"
    do
      if [ x"$input" = x"-" ] ; then
	set -
	if ! (export PATH="$(pwd):$PATH" ; pp ) ; then
	  rc=1
	  done='[ERROR]'
	fi
      else
	[ $# -gt 1 ] && echo -n "$input " 1>&2
	if ! (
		name=$(basename "$input" | tr A-Z a-z | sed -e 's/^\([_a-z0-9]*\).*$/\1/')
		exec <"$input" ; export PATH="$(dirname "$input"):$PATH" ; pp
	     ) ; then
	  rc=1
	  done='[ERROR]'
	fi
      fi
    done
  else
    for input in "$@"
    do
      if [ ! -f "$input" ] ; then
	echo '' 1>&2
	echo "$input: not found" 1>&2
	rc=1
	done='[ERROR]'
	continue
      fi

      name=$(basename "$input" | tr A-Z a-z | sed -e 's/^\([_a-z0-9]*\).*$/\1/')
      output=$(echo "$input" | sed -e 's/\.m\.\([^.]*\)$/.\1/')
      [ x"$output" = x"$input" ] && output="$input.out"

      [ $# -gt 1 ] && echo -n "$input " 1>&2
      if ! ( exec <"$input" >"$output" ; export PATH="$(dirname "$input"):$PATH" ; pp ) ; then
	rc=1
	done='[ERROR]'
      fi
    done
  fi

  [ $# -gt 1 ] && echo "$done" 1>&2
  exit $rc
}
