#
# Transport protocol
#
use strict;
use warnings;

sub TXT() { 0;}
sub MODE() {1;}

sub chars_to_mode
{
    my ( $chars ) = @_;
    my ( @kind, $c , $mode );

    $mode = 0;
    # Split and remove first char
    @kind = split( //, $chars );
    shift( @kind );

    foreach $c ( @kind ){
	$mode <<= 1;
	if( $c ne '-' ){
	    $mode |= 1;
	}
    }
    return $mode;
}

sub tlr_recv {
    my ($fh) = @_;
    my %data = ();
    my $fn;

    while (<$fh>) {
	if (s/^://) {
	    # This is an output line..
	    $data{$fn}->[TXT] .= $_;
	} else {
	    s/^\s+//;
	    s/\s+$//;
	    if ($_ eq 'EOF') {
		# EOF marker
		$fn = undef;
	    } elsif ($fn) {
		# LS output
		my ($lsmode,$nlnks,$lsuid,$lsgid,undef) = split(/\s+/,$_,5);
		$data{$fn}->[MODE] = chars_to_mode($lsmode);
	    } else {
		last if ($_ eq 'DONE');
		# New file
		$fn = $_;
		$data{$fn} = [ '', 0 ];
	    }
	}
    }
    return \%data;
}

1;
