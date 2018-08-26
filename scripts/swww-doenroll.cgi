#!/usr/bin/haserl --accept-all
Content-type: text/html

<%
#include prologue.sh
require urlencode.sh
require refs.sh
require api-hosts.sh

%>
<html>
<head>
 <title>TL|Realm Enrollment Approval</title>
</head>
<body>
<p><a href="/">HOME</a> <a href="<%= $SCRIPT_NAME %>">Q</a> <a href="<%= $SCRIPT_NAME %>/logs">Logs</a></p>
<hr/>
<h1>TL|Realm Enrollment Approval</h1>
<%
queue_dir="$TLR_LOCAL/qdir"
srvpipe=$TLR_LOCAL/run/priv

if [ ! -p "$srvpipe" ] ; then
  echo "<strong>Server daemon not running!</strong>"
elif [ -n "${PATH_INFO:-}" ] ; then
  case "$PATH_INFO" in
  */../*)
    echo "Invalid PATH_INFO: $PATH_INFO"
    ;;
  /purge/enrollment)
    echo "Purging... $PATH_INFO"
    echo "enroll purge enrollment" > $srvpipe
    ;;
  /purge/enroll*)
    vv=$(echo "$PATH_INFO" | sed -e 's!^/purge/enroll-!!')
    echo "Purging... $PATH_INFO"
    echo "<pre>enroll purge $vv</pre>"
    echo "enroll purge $vv" > $srvpipe
    ;;
  /enroll*)
    if [ -f "$TLR_LOGS$PATH_INFO" ] ; then
      echo "<a href=\"$SCRIPT_NAME/purge$PATH_INFO\">PURGE</a>"
      echo "<pre>"
      cat "$TLR_LOGS$PATH_INFO"
      echo "</pre>"
      echo "<a href=\"$SCRIPT_NAME/purge$PATH_INFO\">PURGE</a>"
    else
      echo "Log $PATH_INFO not found"
    fi
    ;;
  /logs)
    echo '<ul>'
    ls -1t "$TLR_LOGS" | grep '^enroll' | while read log
    do
      echo "<li><a href=\"$SCRIPT_NAME/$log\">$log</a></li>"
    done
    echo '</ul>'
    ;;
  *)
    echo "PATH_INFO Error: $PATH_INFO"
    ;;
  esac
elif [ -n "${FORM_cmd_app:-}" ] ; then
  (for i in $(seq 1 $FORM_max)
  do
    if [ -n "$(get FORM_c$i)" ] ; then
      v=$(urldecode "$(get "FORM_c$i")")
      echo "<p>ENROLL: $v</p>"
      echo enroll "$v" 1>&3
    fi
  done) 3> $srvpipe
elif [ -n "${FORM_cmd_del:-}" ] ; then
  for i in $(seq 1 $FORM_max)
  do
    if [ -n "$(get FORM_c$i)" ] ; then
      v=$(urldecode "$(get "FORM_c$i")")
      echo "<p>Delete: $v</p>"
      echo "<pre>"
      rm -rf "$queue_dir/$v.d" 2>&1
      echo "</pre>"
    fi
  done
else
%>
<form method="post">
  <table border=1>
  <tr><th>Timestamp</th><th>IP addr</th><th>Host</th><th>Status</th></td>
  <%
  find $queue_dir -type d -maxdepth 1 -mindepth 1 | (
    cnt=0
    while read d
    do
      cnt=$(expr $cnt + 1)
      echo "<tr>"
      d=$(basename "$d" .d)
      echo "<td>"
        echo "<input type='checkbox' name='c$cnt' value='$(urlencode "$d")'/>"
        echo "$d" | cut -d, -f1-2 
      echo "</td>"
      echo "<td>" ; echo "$d" | cut -d, -f3 ; echo "</td>"
      rhost=$(echo "$d" | cut -d, -f4)
      echo "<td>($rhost)</td>"
      if hosts_exists "$rhost" ; then
	echo "<td bgcolor='red'>DUP!</td>"
      else
	echo "<td bgcolor='green'>OK</td>"
      fi

      echo "</tr>"
    done
    echo "<input type='hidden' name='max' value='$cnt' />"
  )
  %>
  </table>
  <input type="submit" name="cmd_app" value=" Approve "/>
  <input type="submit" name="cmd_del" value=" Delete "/>
  <input type="reset" /></td></tr>
</form>
<% fi %>
</body>
</html>
