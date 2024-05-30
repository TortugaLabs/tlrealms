#!/bin/bash
#
# Sub-command library
#

#+
sh_usage() {
  #    Display a short text on how to use the tool
  #-
  cat 1>&2 <<EOF 
Usage:
        `basename $0` {subcommand} [... args]

- Use the help subcommand for a list of available subcommands.
EOF
  exit 1
}

#+
sh_cmdlookup() {
  #    Check if the subcommand is valid
  # USAGE
  #    sh_cmdlookup SUBCMD [list of prefixes]
  # DESCR
  #    Check if the subcommand is valid.   If valid it will
  #    return the name of the entry function
  #    otherwise an empty string
  #-
  local SUBCMD="$1"
  shift

  declare -F | (while read X Y ENTRYNAME
  do
    if [ x"$ENTRYNAME" = x"op_$SUBCMD" ] ; then
        echo $ENTRYNAME
    fi
  done)
}

#+
hlp_findinfo() {
  #    Locate the source of a function
  # USAGE
  #    hlp_findsrc ENTRY
  # DESCR
  #    Looks for a function and returns any possible help file description
  #-
  ENTRY="$1"
  sed -n "/^$ENTRY()/,/^[ \t]*#-\$/p" "$0" | sed 's/^[ \t]*#//'
}

#+
op_help() {
  #    Display command help
  # USAGE
  #    op_help [sub-command]
  # DESCR
  #    By itself it will display the list of available sub-commands
  # 
  #    If a sub-command is specified, it will show the usage for that
  #    command.
  #-
  if [ $# -eq 0 ] ; then
    echo "List of available sub-commands for `basename $0`"
    echo ''
    declare -F | grep 'declare -f op_' | sed 's/declare -f op_//' | (
    while read OP
    do
      SUMMARY=`hlp_findinfo op_$OP | (read A; read B ; echo $B)`
      printf "%-10s\t%s\n" $OP "$SUMMARY"
    done)
    echo ''
    exit
  fi

  local OP=
  local ENTRY=

  for OP in "$@"
  do
    ENTRY=`sh_cmdlookup $OP`
    if [ -z $ENTRY ] ; then
      echo "Unknown subcommand $OP" 1>&2
      continue
    fi

    # Let' look for it ...
    echo " NAME"
    echo -n "    $OP - "
    hlp_findinfo $ENTRY | (read A ; read B ; echo $B ; cat )
  done
}

#+
sh_dispatch() {
  #    Command dispatcher
  # USAGE
  #    sh_dispatch [arglist]
  # DESCR
  #    Dispatch commands.  Figures out the subcommand,
  #    making sure it is valid.
  #-
  [ $# -eq 0 ] && sh_usage
  local SUBCMD=`sh_cmdlookup "$1"`
  if [ -z $SUBCMD ] ; then
    echo "Invalid sub-command $1" 1>&2
    op_help
  fi

  shift
  $SUBCMD "$@"
  return $?
}

