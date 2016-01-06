#!/usr/bin/perl -w
#
# Fix pw/grp database
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use TLR::pwdb;
use TLR::fsutil;

my $verbose = 0;
my $users = '#users';
my $users_gid = 11000;

while (scalar (@ARGV)) {
    if ($ARGV[0] eq '-q') {
	$verbose = 0;
	shift;
    } elsif ($ARGV[0] eq '-v') {
	$verbose = 1;
	shift;
    } elsif ($ARGV[0] =~ s/^--users=//) {
	$users = $ARGV[0];
	shift;
    } elsif ($ARGV[0] =~ s/^--gid=//) {
	$users_gid = $ARGV[0];
	shift;
    } else {
	last;
    }
}
sub resolve_grp {
    my ($grp,$grtab) = @_;
    unless ($grtab->{$grp}) {
	return ();
    }
    my @result = ();
    my $members = $grtab->{$grp}->[GR_MEMBERS];
    $grtab->{$grp}->[GR_MEMBERS] = ''; # Prevent recursive loops...
    my %res = ();
    foreach my $usr (split(/,/,$members)) {
	if (substr($usr,0,1) eq '@') {
	    foreach my $r (resolve_grp(substr($usr,1),$grtab)) {
		$res{$r} = $r;
	    }
	} else {
	    $res{$usr} = $usr;
	}
    }
    my @res = sort keys %res;
    $grtab->{$grp}->[GR_MEMBERS] = join(',',@res);
    return @res;
}

sub read_pacmandb {
    my ($dbdat) = (@_);
    %$dbdat = ();
    open(my $fh,'-|',qw(pacman -Q -l)) || die "popen: $!\n";
    while (<$fh>) {
	chomp($_);
	my (undef,$fpath) = split(/\s+/,$_,2);
	if (-f $fpath) {
	    my $fgid = (lstat($fpath))[5];
	    if (!exists $dbdat->{$fgid}) {
		$dbdat->{$fgid} = [];
	    }
	    push @{$dbdat->{$fgid}},$fpath
	}
    }
    close($fh);
    return 1;
}

my $op = shift;
$op || die "No op specified\n";

if ($op eq 'group') {
    if (scalar(@ARGV) != 4) {
	die "Usage: $0 group <group_out> <passwd> <group_in> <group_local>\n";
    }
    my ($group_out,$passwd_file,$group_in,$group_local) = @ARGV;
    # NOTE: group_local is not used... but it is left so that the
    #    Make line is simpler.
    #print "group_out=$group_out\n";
    #print "passwd_file=$passwd_file\n";
    #print "group_in=$group_in\n";
    #print "group_local=$group_local\n";

    print STDERR "$group_out.." if ($verbose);

    my (%dbgroup,%dbpasswd);
    #
    # group
    #   - expand @grps
    #   - merge User Private Grous (UPGs)
    #	- create the users group...
    read_file($passwd_file,\%dbpasswd) || die "$passwd_file: $!\n";
    read_file($group_in,\%dbgroup) || die "$group_in: $!\n";
    # Resolve references
    foreach my $grp (keys %dbgroup) {
	resolve_grp($grp,\%dbgroup);
    }

    # Add UPGs...
    while (my ($u,$d) = each %dbpasswd) {
	$dbgroup{$u} = [ $u, 'x', $d->[PW_UID], ''];
    }
    $dbgroup{$users}=[$users,'x',$users_gid ,join(',',sort keys %dbpasswd) ];
    write_file($group_out,\%dbgroup,undef) || die "$group_out: $!\n";

    print STDERR "..done\n" if ($verbose);
    exit 0;
} elsif ($op eq 'grpfix') {
    if (scalar(@ARGV) != 4) {
	die "Usage: $0 group <group_out> <passwd> <group_in> <group_local>\n";
    }
    my ($group_out,$passwd_file,$group_in,$group_local) = @ARGV;
    # NOTE: passwd_file, group_in are not used... but it is left so that the
    #    Make line is simpler.

    my (%dbgroup,%dblgroup);
    # SANITY CHECKS
    #   - remove invalid/duplicate local groups

    print STDERR "grpfix.." if ($verbose);
    read_file($group_out,\%dbgroup) || die "$group_out: $!\n";
    read_file($group_local,\%dblgroup) || die "$group_local: $!\n";

    my %dbpacman;
    my @deltab = ();

    while (my ($g,$d) = each %dblgroup) {
	if ($dbgroup{$g}) {
	    # Oops... we want to delete this one...
	    push @deltab,$g;

	    if ($d->[GR_GID] != $dbgroup{$g}->[GR_GID]
		&& $dbpacman{$d>[GR_GID]}) {
		unless (scalar(%dbpacman)) {
		    print STDERR "\rgo read_pacmandb.." if ($verbose);
		    read_pacmandb(\%dbpacman);
		    print STDERR "done read_pacmandb\ngrpfix.." if ($verbose);
		}
		chown -1,$dbgroup{$g}->[GR_GID],@{$dbpacman{$d->[GR_GID]}};
	    }
	}
    }

    if (scalar(@deltab)) {
	my $group_log = $group_local.'.del';
	if (open(my $fh,'>>',$group_log)) {
	    foreach my $g (@deltab) {
		print $fh join(':',@{$dblgroup{$g}}),"\n";
		delete $dblgroup{$g};
	    }
	    close($fh);
	    write_file($group_local,\%dblgroup,undef) || die "$group_local: $!\n";
	} else {
	    warn "$group_log: $!\n";
	}
    }
    print STDERR ".done\n" if ($verbose);

} elsif ($op eq 'shadow') {
    if (scalar(@ARGV) != 4) {
	die "Usage: $0 shadow <shadow_out> <passwd> <shadow_in> <pwds>\n";
    }
    my ($shadow_out,$passwd_file,$shadow_in,$pwds_in) = @ARGV;

    #print "shadow_out=$shadow_out\n";
    #print "passwd_file=$passwd_file\n";
    #print "shadow_in=$shadow_in\n";
    #print "pwds_in=$pwds_in\n";

    print STDERR "$shadow_out.." if ($verbose);

    my (%dbpwds,%dbshadow,%dbpasswd);

    # shadow
    #   - merge pwds and shadow.in
    #   - make sure only users in passwd are in shadow (and in the same order)

    read_file($pwds_in,\%dbpwds) || die "$pwds_in: $!\n";
    read_file($shadow_in,\%dbshadow) || die "$shadow_in: $!\n";
    read_file($passwd_file,\%dbpasswd) || die "$passwd_file: $!\n";

    my %newdb;
    foreach my $u (keys %dbpasswd) {
	next unless ($dbshadow{$u});
	$newdb{$u} = [ @{$dbshadow{$u}} ];
	if ($dbpwds{$u} && !$newdb{$u}->[SP_PWD]) {
	    $newdb{$u}->[SP_PWD] = $dbpwds{$u}->[SP_PWD];
	}
    }
    %dbshadow = %newdb;
    write_file($shadow_out,\%dbshadow,\%dbpasswd) || die "$shadow_out: $!\n";
    chmod(0600,$shadow_out) || die "chmod($shadow_out): $!\n";
    print STDERR "..done\n" if ($verbose);
    exit 0;
} else {
    die "$op: Invalid op";
}

__END__
sub pwfix {
    my ($dbdir,$etcdir) = @_;

    my $pwds = $dbdir.'pwds';
    my $shadow_in = $dbdir.'shadow';
    my $passwd = $dbdir.'passwd';
    my $shadow_out = $dbdir.'shadow.tmp';
    my $group_in = $dbdir.'group';
    my $group_local = $etcdir.'group';
    my $group_log = $etcdir.'group.del';
    my $group_out = $dbdir.'group.tmp';

    # SANITY CHECKS
    #   - remove invalid/duplicate local groups
    unless (scalar(%dbgroup)) {
	read_file($group_in,\%dbgroup) || die "$group_in: $!\n";
    }
    my %dblgroup;
    read_file($group_local,\%dblgroup) || die "$group_local: $!\n";
}
1;
