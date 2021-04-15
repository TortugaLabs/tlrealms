#!/bin/sh
#
# starting point for tests
#
. ${TESTDIR:=$(cd $(dirname "$0") ; pwd)}/common.sh

include -1 api-plist

db="$TESTDIR/t.plist/sample.d"
exts=".dat .cfg"

mkdir -p "$db"

plst_set "box1" "$db" .dat one 1box1 two 2box1 three 3box1
plst_set "box1" "$db" .cfg uno 1box1sp dos 2box1sp tres 3box1sp

for i in $(seq 2 4)
do
  plst_set "box$i" "$db" .cfg rr1 $RANDOM rr2 $RANDOM rr3 3box$i
done

for i in $(seq 5 7)
do
  plst_set "box$i" "$db" .dat qq1 $RANDOM qq2 $RANDOM qq3 3box$i
done

[ "$(plst_get "box1" "$db" .dat one four)" != "1box1" ] \
	&& quit 5 "plst_get returned unexpected value"

[ "$(plst_get -v "box1" "$db" .cfg uno cuatro)" != "uno 1box1sp" ] \
	&& quit 5 "plst_get returned unexpected value"

cnt=7
#~ plst_list "$db" $exts
[ $(plst_list "$db" $exts | wc -w) -ne $cnt ] \
	&& quit 30 "plst_list did not return $cnt lines"

plst_exists nobox  "$db" $exts \
	&& quit 20 "nobox should NOT exist"

for box in box1 box2 box5
do
  plst_exists "$box" "$db" $exts || quit 20 "$box should exist"
done

plst_set "box1" "$db" .dat mega junk
plst_set "box1" "$db" .dat mega ''
[ -n "$(plst_get "box1" "$db" .dat mega)" ] && quit 20 "box1:mega should be empty"
for tron in abc cba dba
do
  plst_set "box1" "$db" .dat mega $tron
  [ "$(plst_get "box1" "$db" .dat mega)" != "$tron" ] && quit 21 "box1:mega should return $tron"
done

plst_set "box1" "$db" .dat mega
[ -n "$(plst_get "box1" "$db" .dat mega)" ] && quit 20 "box1:mega should be empty"

[ $(plst_get "box1" "$db" .dat | wc -l) -ne 3 ] \
	&& quit 22 "should have returned 3 attributes"
[ $(plst_get -v "box1" "$db" .dat | wc -l) -ne 3 ] \
	&& quit 22 "should have returned 3 attributes"
:
