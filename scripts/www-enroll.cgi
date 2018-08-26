#!/usr/bin/haserl --accept-all
<%
#include prologue.sh
require api-hosts.sh

  if [ x"${PATH_INFO:-}" = x"/me" ] ; then
    echo 'Content-type: text/plain'
    echo ''
    sed \
	-e "s/<TLR_SERVER>/$SERVER_NAME/" \
	-e "s/\"echo -- \"/''/" \
	< enrollme.sh.in
    exit
  else
    echo 'Content-type: text/html'
    echo ''
  fi
%>
<html>
<%
queue_dir="$TLR_LOCAL/qdir"
key_types="dsa ecdsa ed25519 rsa"
%>
<head>
 <title>TL|Realm Enrollment</title>
</head>
<body>
<p><a href="/">HOME</a></p>
<h1>TL|Realm Enrollment</h1>
<% if [ -n "${FORM_host:-}" ] ; then %>
 <%# Somebody is submitting things... %>
 <p>Click <a href="<%= $SCRIPT_NAME %>">HERE</a> to re-submit.</p>
 <% if ([ -d "$queue_dir" ] && [ -w "$queue_dir" ]) ; then %>
  <pre>
  <%
  tstamp=$(date +"%Y%m%d-%H%M%S")
  serial=0
  remote="$REMOTE_ADDR"
  
  if ! host=$(hosts_namechk "$FORM_host") ; then
    echo "Invalid characters in hostname: $FORM_host"
    exit 1
  fi
  echo ''
  if hosts_exists "$host" ; then
    echo "MSG: ******************************"
    echo "MSG: WARNING, $host already exists!"
    echo "MSG: ******************************"
  fi

  while [ -d "$queue_dir/$tstamp,$serial,$remote,$host.d" ] ; do
    serial=$(expr $serial + 1)
  done
  dir="$queue_dir/$tstamp,$serial,$remote,$host.d"
  mkdir -p "$dir"
  cat > "$dir/metadata.cfg" <<-EOF
	tstamp=$tstamp
	remote=$REMOTE_ADDR
	name=$host
	serial=$serial
	EOF
  ssh-keygen -q -N '' -C 'provisional admin' -f "$dir/admin_key"
  for type in $key_types
  do
    ssh-keygen -q -N '' -t $type -C "host:${type}@$host" -f "$dir/ssh_host_${type}_key"
  done
  echo "PAYLOAD"
  echo "[___BEGIN___]"
  ( cd "$dir" && find . -mindepth 1 -maxdepth 1 | cut -d/ -f2-| tr '\n' '\0') | xargs -0 tar -C "$dir" -zcf - | base64
  echo "[___END___]"
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
