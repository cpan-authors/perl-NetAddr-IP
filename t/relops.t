use NetAddr::IP;

my @gt = (
	  [ '255.255.255.255/32', '0.0.0.0/0' ],
	  [ '10.0.0.0/16', '10.0.0.0/8' ],
	  [ '10.0.0.0/24', '10.0.0.0/8' ],
	  );

my @ngt = (
	   [ '0.0.0.0/0', '255.255.255.255/32' ],
	   [ '10.0.0.0/24', '10.0.0.0/24' ],
	   );

my @cmp = (
	   [ '0.0.0.0/0', '255.255.255.255/32', -1 ],
	   [ '10.0.0.0/16', '10.0.0.0/8', 1 ],
	   [ '10.0.0.0/24', '10.0.0.0/8', 1 ],
	   [ '255.255.255.255/32', '0.0.0.0/0', 1 ],
	   [ '10.0.0.0/24', '10.0.0.0/24', 0 ],
	   [ 'default', 'default', 0 ],
	   [ 'broadcast', 'broadcast', 0],
	   [ 'loopback', 'loopback', 0],
	   );

$| = 1;

print "1..", @gt + @ngt + (2 * @cmp), "\n";

my $count = 1;

for my $a (@gt) {
    my $a_ip = new NetAddr::IP $a->[0];
    my $b_ip = new NetAddr::IP $a->[1];

    if ($a_ip > $b_ip) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++$count;
}

for my $a (@ngt) {
    my $a_ip = new NetAddr::IP $a->[0];
    my $b_ip = new NetAddr::IP $a->[1];

    if (not ($a_ip > $b_ip)) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++$count;
}

for my $a (@cmp) {
    my $a_ip = new NetAddr::IP $a->[0];
    my $b_ip = new NetAddr::IP $a->[1];

    if (($a_ip <=> $b_ip) == $a->[2]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++$count;
}

for my $a (@cmp) {
    my $a_ip = new NetAddr::IP $a->[0];
    my $b_ip = new NetAddr::IP $a->[1];

    if (($a_ip cmp $b_ip) == $a->[2]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++$count;
}
