#!/usr/bin/haserl --accept-all
Content-type: text/html

<%
#include prologue.sh
require api-hosts.sh
%>
<html>
<head>
 <title>TL|Realm Sync Requester</title>
</head>
<body>
<p><a href="/">HOME</a></p>
<hr/>
<h1>TL|Realm Sync Requester</h1>
<%
queue_dir="$TLR_LOCAL/qdir"
srvpipe=$TLR_LOCAL/run/priv

if [ ! -p "$srvpipe" ] ; then
  echo "<strong>Server daemon not running!</strong>"
elif [ -n "${PATH_INFO:-}" ] ; then
  name=$(hosts_namechk "$PATH_INFO") || :
  if hosts_exists "$name" ; then
    echo "OK: Requested..."
    echo "sync $name,${FORM_s:-0.0},$REMOTE_ADDR" >$srvpipe
  else
    echo "Invalid PATH_INFO: $PATH_INFO"
  fi
else
%>
Usage:

<pre>
wget -O- "<%= $REQUEST_SCHEME %>://<%= $HTTP_HOST %><%= $SCRIPT_NAME %>/$(hostname)?s=$(cat /etc/tlr/data/serial.txt)"
</pre>
<% fi %>
</body>
</html>
