use NetAddr::IP;

my @r = (
	 [ '10.0.0.0', '255.255.255.0'],
	 [ '11.0.0.0', '255.255.255.0'],
	 [ '12.0.0.0', '255.255.255.0'],
	 [ '20.0.0.0', '255.255.0.0'],
	 [ '30.0.0.0', '255.255.0.0'],
	 [ '40.0.0.0', '255.255.0.0'],
	 );

$| = 1;

print "1..4\n";

my @ips;

for my $ip ('10.0.0.0', '11.0.0.0', '12.0.0.0') {
    push @ips, NetAddr::IP->new($ip, 24)->split(32);
}

for my $ip ('20.0.0.0', '30.0.0.0', '40.0.0.0') {
    push @ips, NetAddr::IP->new($ip, 16)->split(28);
}

my @c = NetAddr::IP::compact(@ips);
my @m;

for my $c (@c) {
    push @m, grep { $c->addr eq $_->[0] and $c->mask eq $_->[1] } @r;
}

if (@m == @c) {
    print "ok 1\n";
}
else {
    print "not ok 1\n";
}

@ips = ();

for my $ip (qw(1.1.1.1 1.1.1.1 1.1.1.1 1.1.1.1)) {
    push(@ips, NetAddr::IP->new($ip));
}

@c = NetAddr::IP::compact(@ips);

if (@c == 1 and $c[0]->cidr() eq '1.1.1.1/32') {
    print "ok 2\n";
}
else {
    print "not ok 2\n";
}

@c = NetAddr::IP::compact(
	NetAddr::IP->new('broadcast'), 
	NetAddr::IP->new('default')
	);

if (@c == 1) {
    print "ok 3\n";
}
else {
    print "not ok 3\n";
}

if ($c[0]->cidr eq '0.0.0.0/0') {
    print "ok 4\n";
}
else {
    print "not ok 4\n";
}


