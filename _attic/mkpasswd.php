#!/usr/bin/php
<?php
define('CMD',array_shift($argv));

function gen_salt($len = 8) {
  $itoa64 = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  $salt = '';
  for ($i=0;$i<$len;$i++) {
    $salt .= substr($itoa64,rand(1,strlen($itoa64))-1,1);
  }
  return $salt;
}

// APR1-MD5 encryption method (windows compatible)
// https://www.virendrachandak.com/techtalk/using-php-create-passwords-for-htpasswd-file/
function crypt_apr1_md5($plainpasswd)
{
    $tmp = '';
    $salt = substr(str_shuffle("abcdefghijklmnopqrstuvwxyz0123456789"), 0, 8);
    $len = strlen($plainpasswd);
    $text = $plainpasswd.'$apr1$'.$salt;
    $bin = pack("H32", md5($plainpasswd.$salt.$plainpasswd));
    for($i = $len; $i > 0; $i -= 16) { $text .= substr($bin, 0, min(16, $i)); }
    for($i = $len; $i > 0; $i >>= 1) { $text .= ($i & 1) ? chr(0) : $plainpasswd{0}; }
    $bin = pack("H32", md5($text));
    for($i = 0; $i < 1000; $i++)
    {
        $new = ($i & 1) ? $plainpasswd : $bin;
        if ($i % 3) $new .= $salt;
        if ($i % 7) $new .= $plainpasswd;
        $new .= ($i & 1) ? $bin : $plainpasswd;
        $bin = pack("H32", md5($new));
    }
    for ($i = 0; $i < 5; $i++)
    {
        $k = $i + 6;
        $j = $i + 12;
        if ($j == 16) $j = 5;
        $tmp = $bin[$i].$bin[$k].$bin[$j].$tmp;
    }
    $tmp = chr(0).chr(0).$bin[11].$tmp;
    $tmp = strtr(strrev(substr(base64_encode($tmp), 2)),
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz");
 
    return "$"."apr1"."$".$salt."$".$tmp;
}
function read_passwd() {
  fwrite(STDERR,"Password: ");
  $pwd_in = fgets(STDIN);
  if ($pwd_in === FALSE) die("Error reading STDIN\n");
  // Trim from the end...
  return preg_replace('/[\r|\n]*$/','',$pwd_in);
}

list($id,$slen) = ['$6$',16];

while (count($argv)) {
  switch ($argv[0]) {
    case '-0':
    case '--des':
      list($id,$slen) = ['',2];
      break;    
    case '-1':
    case '--md5':
      list($id,$slen) = ['$1$',8];
      break;
    case '-5':
    case '--sha256':
      list($id,$slen) = ['$5$',16];
      break;
    case '-6':
    case '--sha512':
      list($id,$slen) = ['$6$',16];
      break;
    case '--htpasswd':
    case '-A':
      list($id,$slen) = ['$apr1$',8];
      break;
    case '--htdigest':
    case '-D':
      array_shift($argv);
      if (count($argv)) {
	$user = array_shift($argv);
      } else {
	die(CMD.": htdigest requires \"UserName\" option\n");
      }
      if (count($argv)) {
	$realm = array_shift($argv);
      } else {
	die(CMD.": htdigest requires \"REALM\" option\n");
      }
      if (count($argv)) {
	$pwd_in = implode(' ',$argv);
      } else {
	$pwd_in = read_passwd();
      }
      echo $realm.':'.md5($user.':'.$realm.':'.$pwd_in).PHP_EOL;
      exit(0);
      break;
    default:
      break 2;
  }
  array_shift($argv);
}


if (count($argv)) {
  $pwd_in = implode(' ',$argv);
} else {
  $pwd_in = read_passwd();
}
//echo "CLEAR TEXT '$pwd_in'\n";
switch($id) {
case '$apr1$':
  echo crypt_apr1_md5($pwd_in).PHP_EOL;
  break;
default:
  $salt = gen_salt($slen);
  echo crypt($pwd_in,$id.$salt).PHP_EOL;
}
