use NetAddr::IP;

my %w = ('broadcast'	=> [ '255.255.255.255', '255.255.255.255' ],
	 'default'	=> [ '0.0.0.0', '0.0.0.0' ],
	 'loopback'	=> [ '127.0.0.1', '255.0.0.0' ],
	 );

$| = 1;

print '1..', (2 * scalar keys %w), "\n";

my $count = 1;

for my $a (keys %w) {
    my $ip = new NetAddr::IP $a;

    if ($ip->addr eq $w{$a}->[0]) {
	print "ok ", $count++, "\n";
    }
    else {
	print "not ok ", $count++, "\n";
    }

    if ($ip->mask eq $w{$a}->[1]) {
	print "ok ", $count++, "\n";
    }
    else {
	print "not ok ", $count++, "\n";
    }
}
