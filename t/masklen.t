use NetAddr::IP;

# $Id: masklen.t,v 1.2 2002/10/31 04:30:35 lem Exp $

my @masks = 0 .. 32;

$| = 1;

print '1..', scalar @masks, "\n"; 

my $count = 1;

for my $m (@masks) {
    my $ip = new NetAddr::IP '10.0.0.1', $m;
    if ($ip->masklen == $m) {
	print "ok ", $count ++, "\n";
    }
    else {
	print "not ok ", $count ++, "\n";
    }
}
