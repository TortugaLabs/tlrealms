#!/bin/sh
#
# Utilities for manipulating logical volumes
#
#+
k_units() {
  # k_units cnt {m|g|t|M|G|T}
  # Convert units in M,G,T to K values
  #-
  local COUNT="$1"
  local UNITS="$2"

  case "$UNITS" in
    m)
     expr $COUNT '*' 1000
     ;;
    M)
     expr $COUNT '*' 1024
     ;;
    g)
     expr $COUNT '*' 1000 '*' 1000
     ;;
    G)
     expr $COUNT '*' 1024 '*' 1024
     ;;
    t)
     expr $COUNT '*' 1000 '*' 1000 '*' 1000
     ;;
    T)
     expr $COUNT '*' 1024 '*' 1024 '*' 1024
     ;;
  esac
}


[ $UID -ne 0 ] && return	# Only root can use these

#+
vgchk() {
  #  vgchk {vgname}
  #  Returns the full vg id
  #-
  set -x
  local vg=$(vgs --noheadings -o vg_name|tr -d ' '|grep '^'"$1"'\.'|head -1)
  [ -z "$vg" ] && vg="$1"
  vgs $vg >/dev/null 2>&1 || return 1
  echo "$vg"
  return 0
}


#+
rem_lvcfg() {
  # rem_lvcfg {mountpnt} [... additional args are ignored... ]
  # Unconfigure a mount point
  #-
  local MNTPNT="$1"

  is_mounted $MNTPNT || return 0 # Not mounted, nothing to do...

  local RAWDEV=$(awk '$2 == "'"$1"'" { print $1 }')
  # OK, try to umount things...
  umount $MNTPNT || return 0

  # Figure out LV/VG config...
  local LV=$(lvs --noheadings --o lv_name $RAWDEV 2>/dev/null)
  if [ -z "$LV" ] ; then
    warn "$RAWDEV is not a Logical Volume"
    return 1
  fi
  local VG=$(lvs --noheadings --o vg_name $RAWDEV)

  # We now remove from fstab...
  fixfile --script='grep -v -P "\\S+'"$MNTPNT"'\\s+"' /etc/fstab
  lvremove -f /dev/$VG/$LV
}


lvcfg() {
  local MOUNTPOINT="$1"
  shift
  local LV= SIZE= VG= FSTYPE=ext3 MOUNTOPTS=defaults,noatime
    
  while [ $# -gt 0 ]
  do
    case "$1" in
      --type=*)
	FSTYPE=${1#--type=}
	;;
      --lv=*)
        LV=${1#--lv=}
	;;
      --size=*)
        SIZE=${1#--size=}
	;;
      --vg=*)
        VG=${1#--vg=}
	;;
      --mountopts=*)
        MOUNTOPTS=${1#--mountopts=}
	;;
      *)
        echo "Invalid option: $1" 1>&2
	return 1
	;;
    esac
    shift
  done

  if [ ! -x /sbin/mkfs.$FSTYPE ] ; then
    echo "FSType $FSTYPE is not supported" 1>&2
    return 1
  fi

  local i= j=
  for i in LV SIZE VG
  do
    eval j=\"\$$i\"
    if [ -z "$j" ] ; then
      echo "$i not specified" 1>&2
      return 1
    fi
  done

  if [ x"$SIZE" = x"delete" ] ; then
    rm_lvcfg $MOUNTPOINT
    return $?
  fi

  SZUNITS=$(tr -d 0-9 <<<"$SIZE")
  if [ -z "$SZUNITS" ] ; then
    SZUNITS="M"
  else
    SIZE=$(tr -dc 0-9 <<<"$SIZE")
  fi
  LSZUNITS=$(tr A-Z a-z <<<"$SZUNITS")

  ## First make sure the VG exists...
  if ! VG=$(vgchk $VG) ; then
    echo "volumegroup $VG does not exists" 1>&2
    return 2
  fi

  ## Now we check that the LVM exists...
  local clvsz=$(lvs --noheadings --o vg_name,lv_name,lv_size --units $LSZUNITS --nosuffix | grep " $VG $LV " | awk '{print $3}'| sed 's/\.[0-9]*$//')

  if [ -z "$clvsz" ] ; then
    # OK, the LV does not exist we create it...
    lvcreate -L $SIZE$LSZUNITS -n $LV $VG || return 1
    case "$FSTYPE" in
      ext3|ext4)
	/sbin/mkfs.$FSTYPE -j /dev/$VG/$LV || return 1
	tune2fs -c 0 -i 0 /dev/$VG/$LV || return 1
	;;
      *)
	/sbin/mkfs.$FSTYPE /dev/$VG/$LV || return 1
	;;
    esac
  else
    # OK, the VG exists... let's check the fstype for it
    eval $(blkid /dev/$VG/$LV | cut -d: -f2-)
    if [ x"$TYPE" != x"$FSTYPE" -a x"$SEC_TYPE" != x"$FSTYPE" ] ; then
      echo "Can not change fstype from $TYPE to $FSTYPE" 1>&2
      return 1
    fi

    if [ "$clvsz" != "$SIZE" ] ; then
      # Hmm... we may need to change size...
      local extsz=$(vgs --noheadings --units=k --nosuffix -o vg_name,vg_extent_size | awk '$1 == "'$VG'" { print $2 }' | sed 's/\.[0-9]*$//')
      local c_esz=$(lvs --noheadings -o lv_name,lv_size --nosuffix --units=k $VG | awk '$1 == "'$LV'" { print $2 }' | sed 's/\.[0-9]*$//')
      c_esz=$(expr $c_esz / $extsz)

      local r_esz=$(k_units $SIZE $SZUNITS)
      if [ $(expr $r_esz % $extsz) -gt 0 ] ; then
	r_esz=$(expr $r_esz / $extsz + 1)
      else
	r_esz=$(expr $r_esz / $extsz)
      fi

      # Check sizes again comparing as EXTENTS
      if [ $c_esz != $r_esz ] ; then
	local MODE=
	if [ $clvsz -lt $SIZE ] ; then
	  MODE=grow
	else
	  MODE=shrink
	fi
	echo "$MODE $clvsz => $SIZE"
	case "$FSTYPE" in
	  ext2|ext3|ext4)
	    D=
	    if [ $MODE = shrink ] ; then
	      if is_mounted $MOUNTPOINT ; then
		# We attempt to umount first..
		umount $MOUNTPOINT || return 1
	      fi
	      $D e2fsck -p -f /dev/$VG/$LV || return 1
	      $D resize2fs -p /dev/$VG/$LV $SIZE$SZUNITS || return 1
	    fi
	    $D lvresize -f -L $SIZE$LSZUNITS /dev/$VG/$LV || return 1
	    if [ $MODE = grow ] ; then
	      $D resize2fs -p /dev/$VG/$LV $SIZE$SZUNITS || return 1
	    else
	      # FSCK again for good measure...
	      $D e2fsck -p -f /dev/$VG/$LV || return 1
	      # We umounted for shrinking... must remount
	      [ $MOUNTPOINT = none ] || mount $MOUNTPOINT || return 1
	    fi
	    ;;
	  *)
	    echo "Resize not support for fstype: $FSTYPE" 1>&2
	    return 1
	    ;;
	esac
      fi
    fi
  fi

  [ $MOUNTPOINT = none ] && return

  # We now make sure that the fs is fstab...
  if ! grep -q -P "^/dev/$VG/$LV\\s+$MOUNTPOINT\\s+$FSTYPE\\s+$MOUNTOPTS\\s" /etc/fstab ; then
    # OK, it is not there...
    fixfile --filter /etc/fstab <<-EOF
	grep -v -P "^/dev/$VG/$LV\\s+" | grep -v -P "\\s+$MOUNTPOINT\\s+"
	echo "/dev/$VG/$LV	$MOUNTPOINT	$FSTYPE	$MOUNTOPTS	1 2"
	EOF
  fi
  
  [ ! -d $MOUNTPOINT ] && mkdir -vp $MOUNTPOINT

  if is_mounted $MOUNTPOINT ; then
    # It is already mounted... do a re-mount for good measure
    mount -o remount $MOUNTPOINT
  else
    echo "Mounting /dev/$VG/$LV on $MOUNTPOINT"
    mount  $MOUNTPOINT
  fi
}

