#
# Handle remote commands
#
use IPC::Open2;

sub sshcmd {
    my $srv = shift;
    my $keyfile = shift;

    my $pid = open2(my $rh,my $wh,qw(ssh -l root),
		    '-o','BatchMode yes',
		    '-i',$keyfile,$srv,
		    @_);
#    my $pid = open2(my $rh,my $wh,"env",
#		    "SSH_ORIGINAL_COMMAND=".join(' ',@_),
#		    "$FindBin::Bin/../server/hostkey","rhost");
    return ($pid,$rh,$wh);
}

sub spawn {
    my ($code) = @_;

    pipe(my $rh,my $wh) || die "pipe: $!\n";
    my $pid = fork;
    die "fork: $!\n" unless defined $pid;

    if ($pid) {
	close($wh);
	return ($pid,$rh);
    } else {
	close($rh);
	&$code($wh);
	exit(0);
    }
}
1;
