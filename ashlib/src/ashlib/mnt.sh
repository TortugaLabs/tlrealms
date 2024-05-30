#!/bin/sh

is_mounted() (
  ## Determine if the given directory is a mount point
  ## # USAGE
  ## is_mounted directory
  ## # ARGS
  ## * directory -- directory mount point
  ## # DESC
  ## Determine if the given directory is a mount point
  
  [ "$1" = none ] && return 1
  [ -d "$1" ] || return 1
  [  $(awk '$2 == "'"$1"'" { print }' /proc/mounts | wc -l) -eq 1 ] && return 0
  return 1
)
