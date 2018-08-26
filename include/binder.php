#!/usr/bin/php
<?php
define('CMD',array_shift($argv));
define('INCDIR',dirname(realpath(__FILE__)).'/');

define('MODE_UPDATE', 0);
define('MODE_TEST', 1);
define('MODE_STDOUT', 2);

$strip = FALSE;
$mode = MODE_UPDATE;

while (count($argv)) {
  if ($argv[0] == '-S') {
    $strip= TRUE;
  } elseif ($argv[0] == '-T') {
    $mode = MODE_TEST;
  } elseif ($argv[0] == '-t') {
    $mode =  MODE_STDOUT;
  } else {
    break;
  }
  array_shift($argv);
}

$cache = [];
function include_file($infile) {
  global $cache;
  
  if (isset($cache[$infile])) return $cache[$infile];

  $input = file_get_contents(INCDIR.$infile);
  if ($input === FALSE) {
    fwrite(STDERR,'Error reading "'.$infile.'"'.PHP_EOL);
    return '';
  }
  if (preg_match('/(^|\n)\s*###\s+START-INCLUDE-SECTION\s+###\s*(\n|$)/',$input,$mv,PREG_OFFSET_CAPTURE)) {
    // OK, let's strip stuff...
    $input = substr($input, $mv[0][1]+strlen($mv[0][0]));
    if (preg_match('/(^|\n)\s*###\s+END-INCLUDE-SECTION\s+###\s*(\n|$)/',$input,$mv,PREG_OFFSET_CAPTURE)) {
      // Also split until here...
      $input = substr($input,0, $mv[0][1]);
    }
  }
  $input = trim(process_text($input,FALSE)).PHP_EOL;
  $cache[$infile] = trim(process_text($input,FALSE)).PHP_EOL;
  return $cache[$infile];
}

function process_text($txt,$mark=TRUE) {
  global $strip;

  $ntxt = ''; $offset = 0;
  //~ if (preg_match_all('/(\s*)#include\s+(\S+)(.*)\n/',$txt,$mv,PREG_OFFSET_CAPTURE|PREG_SET_ORDER)) {
    //~ print_r($mv);
    //~ exit;
  //~ }


  while (preg_match('/([^\n]*)#include\s+(\S+)(.*)\n/',$txt,$mv,PREG_OFFSET_CAPTURE,$offset)) {
    if (trim($mv[1][0]) != '') {
      $offset = $mv[0][1]+strlen($mv[0][0]);
      continue;
    }
    
    $ntxt .= substr($txt,$offset,$mv[0][1]-$offset);
    $offset = $mv[0][1]+strlen($mv[0][0]);

    $incfile = $mv[2][0];
    $after = trim($mv[3][0]);

    if (!is_readable(INCDIR.$incfile)) {
      fwrite(STDERR,'Not found "'.$incfile.'"'.PHP_EOL);
      return FALSE;
    }
    if ($after != '') {
      // Find the end ...
      if (preg_match('/(^|\n)#end\s+include\s*.*(\n|$)/',$txt,$mv,PREG_OFFSET_CAPTURE,$offset)) {
	$offset = $mv[0][1]+strlen($mv[0][0]);
      } else {
	fwrite(STDERR,'Unterminated include file in "'.$f.'" while including "'.$infile.'"'.PHP_EOL);
	return FALSE;
      }
    }
    // There is nothing after... it is stripped...
    if ($strip) {
      $ntxt .= '#include '.$incfile.PHP_EOL;
      //~ echo "offset=$offset ".substr($txt,$offset,"10")."\n";
      //~ while ($txt{$offset} == "\n") {
	//~ $offset++;
      //~ }
    } else {
      if ($mark) {
	$ntxt .= '#include '.$incfile.' ###'.PHP_EOL.
		include_file($incfile,$mark).
		'#end include ###'.PHP_EOL;
      } else {
	$ntxt .= include_file($incfile,$mark);
      }
    }
  }
  $ntxt .= substr($txt,$offset);
  return $ntxt;
}

function process_file($f) {
  global $mode;
  
  $txt = file_get_contents($f);
  if ($txt === FALSE) {
    fwrite(STDERR,'Can not read "'.$f.'"'.PHP_EOL);
    return FALSE;
  }
  $ntxt = process_text($txt,TRUE);
  if ($mode == MODE_STDOUT) {
    echo($ntxt);
  } else {
    if ($ntxt !== $txt) {
      if ($mode == MODE_TEST) {
	$tmp = tempnam('/tmp','bind.');
	if ($tmp === FALSE) die("Error creating temp file\n");
	file_put_contents($tmp,$ntxt);
	echo('== '.$f.' =='.PHP_EOL);
	system('diff -u '.escapeshellarg($f).' '.escapeshellarg($tmp));
	unlink($tmp);
      } else {
	fwrite(STDERR,$f.': Updating'.PHP_EOL);
	file_put_contents($f.'~',$txt);
	file_put_contents($f,$ntxt);
      }
    }
  }
}

foreach ($argv as $f) {
  if (substr($f,-1,1) == '~') continue;
  process_file($f);
}

//~ print_r(array_keys($cache));
