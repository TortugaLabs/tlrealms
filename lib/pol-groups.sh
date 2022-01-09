#!/bin/sh
require api-groups.sh

groupspol_inputs() {
  find "$TLR_DATA/groups.d" -mindepth 1 -maxdepth 1 -type f -name '*.cfg'
}

gen_groups() {
  local g
  for g in $(groups_list)
  do
    groups_members $g >/dev/null # Preload it...
    local \
	gid=$(groups_gid $g) \
	mem=$(groups_members $g)
    echo "$g:x:$gid:$(echo $mem | tr ' ' ,)"
  done
}

#~ gen_htgroups() {
  #~ local g
  #~ for g in $(groups_list)
  #~ do
    #~ groups_members $g >/dev/null # Preload it...
    #~ echo "$g:"$(groups_members $g)
  #~ done
#~ }

#~ gen_group ../sample passwd.txt
#~ gen_group ../sample passwd.txt | gen_htgrp
#~ gen_group ../sample passwd.txt | gen_admin_keys ../sample "alfheim"
