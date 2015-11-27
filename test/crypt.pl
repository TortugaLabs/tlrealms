#!/usr/bin/perl -w
#
my $salt = $ARGV[0];
my $txt = <STDIN>;
chomp $txt;

print crypt($txt,$salt);
