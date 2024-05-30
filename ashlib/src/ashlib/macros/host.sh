#!/bin/sh

#
# Configure Logical Volumes
#
lvol() {
  local group='' vol='' virsh='' sizek=''
  while [ $# -gt 0 ]
  do
    case "$1" in
    --group=*)
      group=${1#--group=}
      ;;
    --virsh=*)
      virsh=${1#--virsh=}
      ;;
    --size=*)
      sizek=$(dehumanize -k "${1#--size=}")
      ;;
    *)
      vol=$1
      ;;
    esac
    shift
  done

  # Check VG configuration
  local vgs=$(vgs --no-heading --units k --no-suffix -o vg_name,vg_extent_size,vg_free \
		| awk '$1 == "'"$group"'" { print int($2),int($3) }'
		)
  if [ -z "$vgs" ] ; then
    echo "$group: vg group does not exist" 1>&2
    return 1
  fi
  local extsz=$(set - $vgs ; echo $1) freek=$(set - $vgs ; echo $2)
  if [ $freek -lt $sizek ] ; then
    echo "$group: free $freek < requested $sizek" 1>&2
    return 1
  fi

  # Re-calculate sizek based on extents
  local sizex=$(expr $sizek / $extsz) off=$(expr $sizek % $extsz)
  [ $off -gt 0 ] && size_ext=$(expr $sizex + 1)
  sizek=$(expr $sizex '*' $extsz)
  local csizek=$(lvs --no-heading --units k --no-suffix -o lv_name,vg_name,lv_size | awk \
	'$1 == "'"$vol"'" && $2 == "'"$group"'" { print int($3) }'
	)

  #~ echo "group=$group vol=$vol size=$sizek(k)/$sizex(x) csize=$csizek"
  if [ -z "$csizek" ] ; then
    lvcreate -Wy -n "$vol" -L "$sizek"k "$group"
  elif [ $csizek -lt $sizek ] ; then
    lvextend -L +$(expr $sizek - $csizek)k /dev/$group/$vol
    #echo "Extend $group/$vol $(expr $sizek - $csizek)"
  elif [ $csizek -gt $sizek ] ; then
    echo "Reduce $group/$vol $(expr $csizek - $sizek) NOT SUPPORTED" 1>&2
  else
    : echo "No change"
  fi
}

novm() {
  local do="echo x"
  local vm="$1" ; shift
  [ $# -gt 0 ] && [ x"$1" = x"do" ] && do=""
  
  [ $(xl list | grep '\b'"$vm"'\b' | wc -l) -gt 0 ] && $do xl destroy "$vm"
  [ -e /etc/xen/auto/"$vm".cfg ] && $do rm -f /etc/xen/auto/"$vm".cfg
  [ -e /etc/xen/"$vm".cfg ] && $do rm -f /etc/xen/"$vm".cfg
  lvs --noheadings | grep '\b'"$vm"'-' | (while read lvn vgn jj
  do
    $do lvremove -f -y /dev/$vgn/$lvn
  done)
  
}

