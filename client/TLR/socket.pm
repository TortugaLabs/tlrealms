#
# Socket utiltieis
#
use strict;
use warnings;
use Socket;
use Fcntl qw(O_NONBLOCK F_SETFL F_GETFL);

my %cb = ();

sub mux_register {
    my ($fh,$cb) = @_;
    $cb{fileno($fh)} = $cb;
}
sub mux_delete {
    my ($fh) = @_;
    delete $cb{fileno($fh)};
    close($fh);
}

sub mux_poll {
    my ($tout) = @_;

    if (defined $tout) {
	$tout = 0 if ($tout < 0);
    }
    my $rin = '';
    foreach my $fn (keys %cb) {
	vec($rin,$fn,1) = 1;
    }
    # print STDERR "ENTER SELECT POLL: (tout=$tout)\n";
    my $n = select(my $rout=$rin,undef,undef,$tout);
    if ($n) {
	while (my ($fn,$code) = each %cb) {
	    &$code if (vec($rout,$fn,1));
	}
    }
}


sub newsrv_sock {
    my ($port) = @_;

    my $proto = getprotobyname('tcp');
    socket(my $Server, PF_INET, SOCK_STREAM, $proto)    || die "socket: $!\n";
    setsockopt($Server, SOL_SOCKET, SO_REUSEADDR, pack("l", 1))
							|| die "sockopt: $!\n";
    bind($Server, sockaddr_in($port, INADDR_ANY))	|| die "bind: $!\n";
    listen($Server, SOMAXCONN)				|| die "listen: $!\n";

    return $Server;
}

sub accept_client {
    my ($s) = @_;

    my $paddr = accept(my $c, $s); 
    unless ($paddr) {
	warn("accept: $!\n");
	return (undef,undef,undef);
    }
    my($port, $iaddr) = sockaddr_in($paddr);
    my $name = gethostbyaddr($iaddr, AF_INET);

    my $o = select($c);$| = 1;select($o);
    my $f = fcntl($c,F_GETFL,0);
    fcntl($c,F_SETFL,$f|O_NONBLOCK);

    return ($c,$name,inet_ntoa($iaddr));
}

1;
