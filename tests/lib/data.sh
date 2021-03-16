#!/bin/sh
#
# Generate common test data
#
db=$(mktemp -d)
trap "rm -rf $db" EXIT
#~ db=$(pwd)/data
export TLR_DATA="$db" DOMAIN='the-kingdom'

groups_setup() {
  (
    exec 1>&2
    set -euf -o pipefail

    local output=""
    for g in admins royals knights nobles commoners soldiers
    do
      groups_add "$g"
    done

    groups_adduser royals arthur guinie
    groups_adduser knights lancelot gawain galahad kay percivale
    groups_adduser commoners sid sancho
    groups_adduser nobles @knights @royals morgana
    groups_adduser admins @royals sid
    groups_adduser soldiers sid
  )
  return $?
}

users_setup() {
  (
    exec 1>&2
    set -euf -o pipefail

    local un u n p
    for un in \
	  "arthur:Arthur Pendragon" "morgana:Morgan Le Fey" \
	  "guinie:Guinevere the Queen" "sancho:Sancho Panza" \
	  "sid:Sid Bedivere" "lancelot:Sir Lancelot" \
	  "gawain:Sir Gawain" "galahad:Sir Galahad" \
	  "kay:Sir Kay" "percivale:Sir Percivale"
    do
      u=$(echo "$un" | cut -d: -f1)
      n=$(echo "$un" | cut -d: -f2)
      users_add --gecos="$n" --home=/home/$u $u
    done
  )
  return $?
}

