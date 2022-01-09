#!/bin/sh
#
# Generate common test data
#
db=$(mktemp -d)
trap "rm -rf $db" EXIT
#~ db=$(pwd)/data

export TLR_DATA="$db/data" DOMAIN='the-kingdom' TLR_LOCAL="$db/local.d" TLR_ETC="$db/etc"
mkdir -p "$TLR_LOCAL" "$TLR_DATA" "$TLR_ETC"


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

      users_map "$u" ident_sso "$(users_pwgen)"
      users_map "$u" social_logins "$u@yahoo.com $u@gmail.com"
    done
  )
  return $?
}

etcdat_setup() {
  local f
  for f in passwd shadow group gshadow
  do
    cp -a $(atf_get_srcdir)/lib/$f.txt $TLR_ETC/$f
  done
  chmod 600 $TLR_ETC/{shadow,gshadow}
  mkdir -p $TLR_ETC/ssh
}

hosts_setup() {
  (
    exec 1>&2
    set -euf -o pipefail

    mkdir -p $TLR_DATA/systems
    for n in $(seq 1 6)
    do
      hosts_new sys$n > $TLR_DATA/systems/sys$n.tar.gz
      mkdir -p $TLR_DATA/systems/sys$n
      tar zxf $TLR_DATA/systems/sys$n.tar.gz -C $TLR_DATA/systems/sys$n
      rm -f $TLR_DATA/systems/sys$n.tar.gz
    done
  )
  return $?
}

policy_setup() {
  (
    exec 1>&2
    set -euf -o pipefail
    mkdir -p $TLR_DATA/policy.d
    for p in users groups hosts
    do
      (
        echo "echo 'Running $p policy'"
        echo 'date +%s > $TLR_DATA/policy.d/run-'"$p"
      ) > $TLR_DATA/policy.d/$p.sh
    done
  )
}
