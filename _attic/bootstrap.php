<?php
header('Content-type: text/plain');

define('TLR_HOME', '/etc/realm/');
define('TLR_DATA', TLR_HOME.'data/');
define('ADMIN_KEYS','admin_keys');

if (isset($_SERVER['PATH_INFO']) && $_SERVER['PATH_INFO'] == '/'.ADMIN_KEYS) {
  readfile(TLR_DATA.ADMIN_KEYS);
  exit;
}
?>
<?php readfile(TLR_DATA.'settings.sh'); ?>

#
# Enroll host
#
TLR_HOME=/etc/realm
export PATH=$PATH:$TLR_HOME/scripts
myhost=$(hostname)

mkdir -p $TLR_HOME

echo "Enrolling host $myhost with $server"
cat /etc/ssh/ssh_host*.pub | ssh ${ruser}@${server} $TLR_HOME/scripts/hostadm enroll ${myhost}


<?php readfile(TLR_HOME.'scripts/updater'); ?>


