#!/bin/sh
#
# basic test...

. ${TESTDIR:=$(cd $(dirname "$0") ; pwd)}/common.sh
mkdir -p $TESTDIR/t.priv
export TLR_DATA=$TESTDIR/t.priv
include -1 api-groups

for n in $(seq 1 8)
do
  groups_del gr$n
done
[ $(groups_list | wc -w) -eq 0 ] || quit 21 "Number of groups is wrong"

groups_add gr1 one two three
groups_add gr2 four five six two
groups_add --gid=5050 gr3 one five six
groups_add gr4 @gr1 nine ten
groups_add gr5 @gr2 @gr3
groups_add gr6 seven eleven @gr7
groups_add gr7 @gr6 eight nien
groups_add gr8 @gr1 one two three

groups_exists gr1 || quit 25 "group gr1 should exist"
groups_exists xx1 && quit 26 "group xx1 does not exist" || :

[ $(groups_list | wc -w) -eq 8 ] || quit 21 "Number of groups is wrong"

[ $(groups_gid gr1) -eq 5000 ] || quit 22 "Group gid did not work"
groups_gid gr1 5090
[ $(groups_gid gr1) -eq 5090 ] || quit 22 "Group gid did not match"

groups_members gr1
groups_members gr2
groups_members gr4
groups_members gr5
groups_members --no-resolve gr4
groups_members --no-resolve gr5
groups_members gr6
groups_members gr7
groups_members gr8

echo =


groups_members gr1 fie foo six one
groups_members gr1
groups_members gr4

echo =

groups_usergroups one
groups_usergroups --no-resolve one

echo =

groups_adduser gr8 seven
groups_members gr8

groups_adduser gr8 @gr5
groups_members --no-resolve gr8

echo =

groups_deluser gr8 seven
groups_members --no-resolve gr8
groups_deluser gr8 @gr5
groups_members --no-resolve gr8

echo =

groups_cleanup one
groups_usergroups one

