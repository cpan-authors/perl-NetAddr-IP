use NetAddr::IP;

# $Id: relops.t,v 1.2 2002/10/31 04:30:35 lem Exp $

my @gt = (
	  [ '255.255.255.255/32', '0.0.0.0/0' ],
	  [ '10.0.1.0/16', '10.0.0.1/24' ],
	  [ '10.0.0.1/24', '10.0.0.0/24' ],
	  );

my @ngt = (
	   [ '0.0.0.0/0', '255.255.255.255/32' ],
	   [ '10.0.0.0/24', '10.0.0.0/24' ],
	   );

my @cmp = (
	   [ '0.0.0.0/0', '255.255.255.255/32', -1 ],
	   [ '10.0.0.0/16', '10.0.0.0/8', 0 ],
	   [ '10.0.0.0/24', '10.0.0.0/8', 0 ],
	   [ '255.255.255.255/32', '0.0.0.0/0', 1 ],
	   [ '142.52.5.87', '142.52.2.88', 1 ],
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
	print "ok $count # $a_ip > $b_ip\n";
    }
    else {
	print "not ok $count # $a_ip > $b_ip\n";
    }
    ++$count;
}

for my $a (@ngt) {
    my $a_ip = new NetAddr::IP $a->[0];
    my $b_ip = new NetAddr::IP $a->[1];

    if (not ($a_ip > $b_ip)) {
	print "ok $count # $a_ip !> $b_ip\n";
    }
    else {
	print "not ok $count # $a_ip !> $b_ip\n";
    }
    ++$count;
}

for my $a (@cmp) {
    my $a_ip = new NetAddr::IP $a->[0];
    my $b_ip = new NetAddr::IP $a->[1];

    if (($a_ip <=> $b_ip) == $a->[2]) {
	print "ok $count # $a_ip <=> $b_ip\n";
    }
    else {
	print "not ok $count # $a_ip <=> $b_ip\n";
    }
    ++$count;
}

for my $a (@cmp) {
    my $a_ip = new NetAddr::IP $a->[0];
    my $b_ip = new NetAddr::IP $a->[1];

    if (($a_ip cmp $b_ip) == $a->[2]) {
	print "ok $count # $a_ip cmp $b_ip\n";
    }
    else {
	print "not ok $count # $a_ip cmp $b_ip\n";
    }
    ++$count;
}
