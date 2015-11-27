#
# Misc file related utils
#
use strict;
use warnings;

sub read_txt {
    my ($fn) = @_;

    if (open(my $fh,'<',$fn)) {
	my $txt = '';
	while (<$fh>) {
	    $txt .= $_;
	}
	close($fh);
	return $txt;
    }
    return undef;
}

sub file_update {
    my ($fn,$ntxt,$tmode,$tuid,$tgid) = @_;

    if (-f $fn) {
	my $otxt = read_txt($fn);

	if ($ntxt eq $otxt) {
	    my $r = -1;
	    if (defined($tmode) || defined($tuid) || defined($tgid)) {

		my (undef,undef,$cmode,undef,$cuid,$cgid) = stat($fn);

		if (defined($tmode) && ($cmode & 0777) != ($tmode & 0777)) {
		    if (chmod($tmode,$fn)) {
			$r = 1;
		    } else {
			warn("chmod($fn): $!\n");
		    }
		}
		if ((defined($tuid) && $tuid != $cuid) ||
		    (defined($tgid) && $tgid != $cgid)) {
		    print STDERR "x2\n";

		    $tuid = -1 unless defined $tuid;
		    $tgid = -1 unless defined $tgid;
		    if (chown($tuid,$tgid,$fn)) {
			$r = 1;
		    } else {
			warn("chown($fn): $!\n");
		    }
		}
	    }
	    return $r;
	}
	
	# Save contents of the old file
	my (undef,undef,$mode,undef,$uid,$gid) = stat($fn);
	open (my $fh,'>',$fn.'~') || return 0;

	# Make sure the right ownership and permissions apply...
	chown($uid,$gid,$fn.'~') || return 0;
	chmod($mode,$fn.'~') || return 0;

	print $fh $otxt;
	close($fh);
    }
    # Save the new file

    open (my $fh,'>',$fn) || return 0;

    if (defined $tmode) {
	chmod($tmode,$fn) || warn("chmod($fn): $!\n");
    }
    if (defined($tuid) || defined($tgid)) {
	$tuid = -1 unless defined $tuid;
	$tgid = -1 unless defined $tgid;
	chown($tuid,$tgid,$fn) || warn("chown($fn): $!\n");
    }

    print $fh $ntxt;
    close $fh;

    return 1;
}

sub deps {
    my $target = shift;
    return 1 unless (-f $target);
    
    my $tstamp = (stat($target))[9];

    foreach my $src (@_) {
	next unless (-f $src);
	my $srctime = (stat($src))[9];
	return 1 if ($tstamp < $srctime);
    }
    return 0;
}

sub read_cfg {
    my ($f,$sect) = @_;
    
    my $out = 1;
    if (open(my $fh,'<',$f)) {
	my $txt = '';
	while (<$fh>) {
	    if (/^\s*\[(.+)\]\s*/) {
		$out = $1 eq $sect;
		next;
	    }
	    $txt .= $_ if $out;
	}
	close($fh);

	return $txt;
    }
    return undef;
}

1;
