#!/usr/bin/haserl --accept-all
Content-type: text/html

<%
#include prologue.sh
require urlencode.sh
require refs.sh
require api-hosts.sh
require api-enrollments.sh
%>
<html>
<head>
 <title>TL|Realm Enrollment Approval</title>
</head>
<body>
<p><a href="/">HOME</a> <a href="<%= $SCRIPT_NAME %>">Q</a></p>
<hr/>
<h1>TL|Realm Enrollment Approval</h1>
<%
srvpipe=$TLR_LOCAL/run/priv

if [ ! -p "$srvpipe" ] ; then
  echo "<strong>Server daemon not running!</strong>"
  srvpipe=''
fi
if [ -n "${PATH_INFO:-}" ] ; then
  case "$PATH_INFO" in
  */../*)
    echo "Invalid PATH_INFO: $PATH_INFO"
    ;;
  /enroll/*)
    vv=$(basename "$PATH_INFO")
    logfile="$TLR_LOGS/enroll-$vv"    
    if [ -f "$logfile" ] ; then
      echo "<a href=\"$SCRIPT_NAME/purge/enroll-$vv\">PURGE</a>"
      echo "<pre>"
      cat "$logfile"
      echo "</pre>"
      echo "<a href=\"$SCRIPT_NAME/purge/enroll-$vv\">PURGE</a>"
    else
      echo "Log $logfile not found"
    fi
    ;;
  /purge/enroll*)
    if [ -n "$srvpipe" ] ; then
      vv=$(echo "$PATH_INFO" | sed -e 's!^/purge/enroll-!!')
      echo "Purging... $PATH_INFO"
      echo "<pre>enroll purge $vv</pre>"
      echo "enroll purge $vv" > $srvpipe
    fi
    ;;
  *)
    echo "PATH_INFO Error: $PATH_INFO"
    ;;
  esac
elif [ -n "${FORM_cmd_app:-}" ] ; then
  if [ -n "$srvpipe" ] ; then
    (for i in $(seq 1 $FORM_max)
    do
      if [ -n "$(get FORM_c$i 2>&-)" ] ; then
	v=$(urldecode "$(get "FORM_c$i")")
	echo "<p>ENROLL: $v</p>"
	echo enroll "$v" 1>&3
      fi
    done) 3> $srvpipe
  fi
elif [ -n "${FORM_cmd_del:-}" ] ; then
  if [ -n "$srvpipe" ] ; then
    for i in $(seq 1 $FORM_max)
    do
      if [ -n "$(get FORM_c$i 2>&-)" ] ; then
	v=$(urldecode "$(get "FORM_c$i")")
	echo "<p>Delete: $v</p>"
	echo "enroll purge $v" > $srvpipe
      fi
    done
  fi
else
%>
<form method="post">
  <table border=1>
  <tr><th>&nbsp;</th><th>Timestamp</th><th>IP addr</th><th>Host</th><th>Status</th><th>Logs</th></tr>
  <%
    cnt=0
    for row in $(enrolls_list)
    do
      cnt=$(expr $cnt + 1)
      echo "<tr>"
      echo "<td><input type=\"checkbox\" name=\"c$cnt\" value=\"$(urlencode "$(enrolls_get id "$row")")\" /></td>"
      echo "<td>$(enrolls_get tstamp "$row") $(enrolls_get serial "$row")</td>"
      echo "<td>$(enrolls_get remote "$row")</td>"
      echo "<td>$(enrolls_get host "$row")</td>"
      if $(enrolls_get dup "$row") ; then
	echo "<td bgcolor='red'>DUP!</td>"
      else
	echo "<td bgcolor='green'>OK</td>"
      fi
      if $(enrolls_get log "$row") ; then
	echo "<td><a href=\"$SCRIPT_NAME/enroll/$(enrolls_get id "$row")\">View</a></td>"
      else
	echo "<td>&nbsp;</td>"
      fi
      echo "</tr>"
    done
    echo "<input type='hidden' name='max' value='$cnt' />"
  %>
  </table>
  <input type="submit" name="cmd_app" value=" Approve "/>
  <input type="submit" name="cmd_del" value=" Delete "/>
  <input type="reset" /></td></tr>
</form>
<% fi %>
</body>
</html>
