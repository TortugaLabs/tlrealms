#!/bin/sh
#
# TLRealms Server Commands
#
set -euf -o pipefail

#include lib.sh
#include users.sh
#include common.sh
#include user_ops.sh


if [ $# -eq 0 ] ; then
  echo "Usage: $0 verb [options]"
  if type declare >/dev/null 2>&1 ; then
    echo "Verbs:"
    declare -F | grep ' verb_' | sed -e 's/^.* verb_/  /'
  fi
  exit 1
fi

op="verb_$1" ; shift
$op "$@"
