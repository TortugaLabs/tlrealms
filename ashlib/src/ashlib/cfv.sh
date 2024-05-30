#!/bin/sh
#
## Configurable variables
##
## Define variables only if not specified.  It is used to
## configure things via environment variables and provide
## suitable defaults if there is none.
##
## The way it works is to simply call the command like this:
##
## VARIABLE=value command args
##
## Then in the script, you woudld do:
##
## cfv VARIABLE default
#
cfv() {
  ## Define a configurable variable
  ## # USAGE
  ##    cfv VARNAME value
  ## # ARGS
  ## * VARNAME -- variable to define
  ## * value -- default to use
  eval local n=\${$1:-}
  if [ -n "$n" ] ; then
    export $1
    return
  fi
  eval export ${1}='"$2"'
}

