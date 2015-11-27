#
# Password database access procs
#
use strict;
use warnings;
use TLR::fsutil;

sub PW_NAME() {0;}
sub PW_X() {1;}
sub PW_UID() {2;}
sub PW_GID() {3;}
sub PW_GECOS() {4;}
sub PW_HOMEDIR() {5;}
sub PW_SHELL() {6;}

sub SP_NAME() {0;}
sub SP_PWD() {1;}
sub SP_LASTCHG() {2;}
sub SP_MIN() {3;}
sub SP_MAX() {4;}
sub SP_WARN() {5;}
sub SP_INACT() {6;}
sub SP_EXPIRE() {7;}

sub GR_NAME() {0;}
sub GR_PASSWD() {1;}
sub GR_GID() {2;}
sub GR_MEMBERS() {3;}

sub read_file {
    my ($fn,$hash) = @_;
    %$hash = ();	# Reset hash...
    open (my $fh,'<',$fn) || return 0;
    while (<$fh>) {
	s/^\s+//;
	s/\s+$//;
	next unless $_;
	my ($id,@items) = split(/:/,$_,-1);
	next if ($id =~ /^\#/);
	next unless ($id && scalar(@items));
	$hash->{$id} = [$id,@items];
    }
    close($fh);
    return 1;
}



sub write_file {
    my ($fn,$hash,$ohash) = @_;

    my $txt = '';
    my $ix = PW_UID;	# This is also the same as GR_GID...

    if ($ohash) {
	foreach my $id (sort {$ohash->{$a}->[$ix] <=>  $ohash->{$b}->[$ix]}
			keys %$hash) {
	    $txt .= join(':',@{$hash->{$id}})."\n";
	}
    } else {
	foreach my $id (sort {$hash->{$a}->[$ix] <=>  $hash->{$b}->[$ix]}
			keys %$hash) {
	    $txt .= join(':',@{$hash->{$id}})."\n";
	}
    }

    return file_update($fn,$txt);
}



1;
