use NetAddr::IP;

# $Id: over-arr.t,v 1.2 2002/10/31 04:30:35 lem Exp $

my @addr = ( [ '10.0.0.0/24', '10.0.0.1/32' ], 
	     [ '192.168.0.0/24', '192.168.0.1/32' ],
	     [ '127.0.0.1/32', '127.0.0.1/32' ] );

$| = 1;

print "1..", 1 * scalar @addr, "\n";

my $count = 1;

for my $a (@addr) {
    my $ip = new NetAddr::IP $a->[0];
    
    if (@$ip[0]->cidr eq $a->[1]) {
	print "ok $count\n";
    }
    else {
	print "not ok $count\n";
    }

    ++$count;
}
