use NetAddr::IP;

# $Id: v4-compact.t,v 1.2 2002/10/31 04:30:36 lem Exp $

my @r = (
	 [ '10.0.0.0', '255.255.255.0'],
	 [ '11.0.0.0', '255.255.255.0'],
	 [ '12.0.0.0', '255.255.255.0'],
	 [ '20.0.0.0', '255.255.0.0'],
	 [ '30.0.0.0', '255.255.0.0'],
	 [ '40.0.0.0', '255.255.0.0'],
	 );

$| = 1;

if (defined($ENV{LIGHTERIPTESTS}) and $ENV{LIGHTERIPTESTS} =~ /yes/i) {
    print "1..0\n";
    exit 0;
}

print "1..2\n";

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

