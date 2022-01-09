#!/sbin/openrc-run
# Copyright (c) 2007-2015 The OpenRC Authors.
# See the Authors file at the top-level directory of this distribution and
# https://github.com/OpenRC/openrc/blob/master/AUTHORS
#
# This file is part of OpenRC. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/OpenRC/openrc/blob/master/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.

description="TLR priviledged daemon"
: ${PIDFILE:=/run/srvpriv.pid}
: ${TIMEOUT:=60}

depend()
{
  need net
  use dns
}

start()
{
  ebegin "Starting ${SVCNAME}"
  start-stop-daemon --start \
	--exec /etc/tlr/lib/logrun \
	--pidfile ${PIDFILE} \
	-- -b --log=/var/log/tlr/srvpriv.log --pid=${PIDFILE} /etc/tlr/scripts/srvpriv
  eend $?
}

stop()
{
  ebegin "Stopping ${SVCNAME}"
  start-stop-daemon --stop \
	--name srvpriv \
	--pidfile ${PIDFILE} \
	--retry ${TIMEOUT}
  eend $?

  local pipe=/etc/tlr-local/run/priv
  if [ -p "$pipe" ] ;then
    echo exit > "$pipe"
    rm -f "$pipe"
  fi
}
