use NetAddr::IP;

my @ranges = (
	      [ '10.0.0.0/8', '10.0.0.0', '10.255.255.255' ],
	      [ '192.168.0.0/16', '192.168.0.0', '192.168.255.255' ],
	      );

print "1..", (3 * scalar @ranges), "\n";

my $count = 1;

for my $r (@ranges) {
    my $r1 = new NetAddr::IP $r->[1] . '-' . $r->[2];

    if ($r1 and $r1 eq $r->[0]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++ $count;

    $r1 = new NetAddr::IP $r->[1] . ' - ' . $r->[2];
    if ($r1 and $r1 eq $r->[0]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++ $count;

    $r1 = new NetAddr::IP $r->[0];
    if ($r1 and $r1->range eq $r->[1] . ' - ' . $r->[2]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }
    ++ $count;
}

