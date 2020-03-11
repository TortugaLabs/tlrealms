#!/usr/bin/haserl --accept-all
<%
#include prologue.sh
require api-hosts.sh
require api-enrollments.sh

  if [ x"${PATH_INFO:-}" = x"/me" ] ; then
    echo 'Content-type: text/plain'
    echo ''
    sed \
	-e "s/<TLR_SERVER>/$SERVER_NAME/" \
  -e "s!<TLR_SCRIPTS>!$TLR_SCRIPTS!" \
	-e "s/\"echo -- \"/''/" \
	< enrollme.sh.in
    exit
  else
    echo 'Content-type: text/html'
    echo ''
  fi
%>
<html>
<head>
 <title>TL|Realm Enrollment</title>
</head>
<body>
<p><a href="/">HOME</a></p>
<h1>TL|Realm Enrollment</h1>
<% if [ -n "${FORM_host:-}" ] ; then %>
 <%# Somebody is submitting things... %>
 <p>Click <a href="<%= $SCRIPT_NAME %>">HERE</a> to re-submit.</p>
 <% if ([ -d "$(enrolls_queue_dir)" ] && [ -w "$(enrolls_queue_dir)" ]) ; then %>
  <pre>
  <%
  echo ''
  if enrolls_add resdir $FORM_host ; then
    echo "PAYLOAD"
    echo "[___BEGIN___]"
    enrolls_payload $resdir
    echo "[___END___]"
  fi
  %>
  </pre>
 <% else %>
  <h2>Configuration Error!</h2>
 <% fi %>
<% else %>
 <%# Ask for it... %>
 <p>Enter host details:</p>
 <form method="post">
  <table>
   <tr><td>host</td><td><input type="text" name="host" /></td></tr>
   <tr><td colspan=2><input type="submit" value=" OK "/> <input type="reset" /></td></tr>
  </table>
 </form>
 <hr/>
 <p>Otherwise, run from the server being enrolled...</p>
 <pre>wget -O- "<%= $REQUEST_SCHEME %>://<%= $HTTP_HOST %><%= $SCRIPT_NAME %>/me" | sh</pre>
<% fi %>
</body>
</html>
