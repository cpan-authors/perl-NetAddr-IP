use NetAddr::IP;

# $Id: v4-base.t,v 1.2 2002/10/31 04:30:35 lem Exp $

my @addr = (qw( 127.0.0.1 10.0.0.1 ));
my @mask = (qw( 255.0.0.0 255.255.0.0 255.255.255.0 255.255.255.255 ));

$| = 1;
print "1..", (2 * scalar @addr * scalar @mask), "\n";

my $count = 1;

for my $a (@addr) {
    for my $m (@mask) {
	my $ip = new NetAddr::IP $a, $m;
	print (($ip->addr ne $a ? 'not ' : ''), "ok ", $count++, "\n");
	print (($ip->mask ne $m ? 'not ' : ''), "ok ", $count++, "\n");
    }
}


