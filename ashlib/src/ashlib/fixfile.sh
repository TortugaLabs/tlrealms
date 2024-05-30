#!/bin/sh
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
fixfile() {
  ## Function to modify files in-place.
  ## # USAGE
  ##   fixfile [options] file
  ## # OPTIONS
  ## * -D -- if specified, containing directory is created.
  ## * --mode=mode -- mode to set permissions to.
  ## * --user=user -- set ownership to user
  ## * --group=group -- set group to group
  ## * --nobackup -- disable creation of backups
  ## * --backupdir=dir -- if specified, backups are saved to the central dir.
  ## * --backupext=ext -- Backups are created by adding ext.  Defaults to "~".
  ## * --filter -- Use filter mode.  The stdin is used as an script that will
  ##     modify stdin (current file) and the stdout is used as the new contents
  ##     of the file.
  ## * --decode -- input is considered to be gzippped|base64 encoded data
  ## * file -- file to modify
  ## # DESC
  ## Files are modified in-place only if the contents change.  This means
  ## time stamps are kept accordingly.
  ##
  ## <stdin> will be used as the contents of the new file unless --filter
  ## is specified.  When in filter mode, the <stdin> is a shell script
  ## that will be executed with <stdin> is the current contents of the
  ## file and <stdout> as the new contents of the file.
  ## Again, file is only written to if its conents change.
  local MODE= USER= GROUP= BACKUPDIR= BACKUPEXT="~" FILTER=false MKDIR=false ENCODED=false

  while [ $# -gt 0 ]
  do
    case "$1" in
	--nobackup)
	    BACKUPDIR=
	    BACKUPEXT=
	    ;;
	--backupext=*)
	    BACKUPDIR=
	    BACKUPEXT=${1#--backupext=}
	    ;;
        --backupdir=*)
	    BACKUPDIR=${1#--backupdir=}
	    BACKUPEXT=
	    ;;
	--filter)
	    FILTER=true
	    ;;
	--decode)
	    ENCODED=true
	    ;;
	--mode=*)
	    MODE=${1#--mode=}
	    ;;
	--user=*)
	    USER=${1#--user=}
	    ;;
	--group=*)
	    GROUP=${1#--group=}
	    ;;
	-D)
	    MKDIR=true
	    ;;
	-*)
	    echo "Invalid option: $1" 1>&2
	    return 1
	    ;;
	*)
	    break
	    ;;
    esac
    shift
  done

  if $ENCODED && $FILTER ; then
    echo "Can not specify --filter and --decode!" 1>&2
    return 2
  fi

  if [ $# -eq 0 ] ; then
    echo "No file specified" 1>&2
    return 1
  elif [ $# -gt 1 ] ; then
    echo "Ignoring additional options: $*" 1>&2
  fi

  local FILE="$1"

  if [ -z "$GROUP" ] ; then
    # Check if USER == {user}:{group}
    eval $(
	echo $USER | (
	    IFS=:
	    a="" ; b=""
	    read a b
	    [ -z "$b" ] && return
	    echo "USER='$a' ; GROUP='$b'"
	)
    )
  fi

  local MSG= OTXT=""

  if [ -f $FILE ] ; then
    if $ENCODED ; then
      # Handled binary files...
      OTXT="$(md5sum "$FILE" | awk '{print $1}')"
    else
      OTXT=$(sed 's/^/:/' $FILE)
    fi
  elif $MKDIR ; then
    if [ ! -d "$(dirname "$FILE")" ] ; then
      mkdir -p "$(dirname "$FILE")"
      [ -n "$USER" ] && chown "$USER" "$(dirname "$FILE")"
      [ -n "$GROUP" ] && chgrp "$GROUP" "$(dirname "$FILE")"
    fi
  fi

  if $FILTER ; then
    # Stdin is not contents but actually is a filter script
    local INCODE="$(cat)"
    if [ -f $FILE ] ; then
      local NTXT="$(cat $FILE)"
    else
      local NTXT=""
    fi
    local NTXT=$(echo "$NTXT" | (eval "$INCODE" )| sed 's/^/:/' )
  elif $ENCODED ; then
    local tmpfile=$(mktemp -p "$(dirname "$FILE")")
    base64 -d | gunzip > $tmpfile
    local NTXT=$(md5sum $tmpfile | awk '{print $1}')
  else
    local NTXT=$(sed 's/^/:/')
  fi

  if [ x"$OTXT" != x"$NTXT" ] ; then
    if [ -f $FILE ] ; then
      if [ -z "$BACKUPDIR" ] ; then
	[ -n "$BACKUPEXT" ] && cp -dp $FILE $FILE$BACKUPEXT
      else
	cp -dp $FILE $BACKUPDIR/$(basename $FILE)
      fi
    fi
    if $ENCODED ; then
      cat < "$tmpfile" >"$FILE"
    else
      echo "$NTXT" | sed 's/^://' > $FILE
    fi
    MSG=$(echo $MSG updated)
  fi
  $ENCODED && rm -f "$tmpfile"

  if [ -n "$USER" ] ; then
    if [ $(find $FILE -maxdepth 0 -user $USER | wc -l) -eq 0 ] ; then
      chown $USER $FILE
      MSG=$(echo $MSG chown)
    fi
  fi
  if [ -n "$GROUP" ] ; then
    if [ $(find $FILE -maxdepth 0 -group $GROUP | wc -l) -eq 0 ] ; then
      chgrp $GROUP $FILE
      MSG=$(echo $MSG chgrp)
    fi
  fi
  if [ -n "$MODE" ] ; then
    if [ $(find $FILE -maxdepth 0 -perm $MODE | wc -l) -eq 0 ] ; then
      chmod $MODE $FILE
      MSG=$(echo $MSG chmod)
    fi
  fi
  [ -n "$MSG" ] && echo "$FILE $MSG" 1>&2
  # RETURNS TRUE if file changes, FALSE if not
}
