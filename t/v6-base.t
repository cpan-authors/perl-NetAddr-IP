# This -*- perl -*- code excercises the basic v6 functionality

# $Id: v6-base.t,v 1.7 2003/10/09 00:14:06 lem Exp $

our @addr = 
    (
     ['::',  3, '0000:0000:0000:0000:0000:0000:0000:0000/128'],
     ['::1', 3, '0000:0000:0000:0000:0000:0000:0000:0001/128'],
     ['f34::123/40', 3, '0f34:0000:0000:0000:0000:0000:0000:0003/40'],
     ['dead:beef::1/40', 3, 'dead:beef:0000:0000:0000:0000:0000:0003/40'],
     ['dead:beef::1/40', 4, 'dead:beef:0000:0000:0000:0000:0000:0004/40'],
     ['dead:beef::1/40', 5, 'dead:beef:0000:0000:0000:0000:0000:0005/40'],
     ['dead:beef::1/40', 6, 'dead:beef:0000:0000:0000:0000:0000:0006/40'],
     ['dead:beef::1/40', 7, 'dead:beef:0000:0000:0000:0000:0000:0007/40'],
     ['dead:beef::1/40', 8, 'dead:beef:0000:0000:0000:0000:0000:0008/40'],
     ['dead:beef::1/40', 9, 'dead:beef:0000:0000:0000:0000:0000:0009/40'],
     ['dead:beef::1/40', 255, 'dead:beef:0000:0000:0000:0000:0000:00ff/40'],
     ['dead:beef::1/40', 256, 'dead:beef:0000:0000:0000:0000:0000:0100/40'],
     ['dead:beef::1/40', 257, 'dead:beef:0000:0000:0000:0000:0000:0101/40'],
     ['dead:beef::1/40', 65536, 'dead:beef:0000:0000:0000:0000:0001:0000/40'],
     ['dead:beef::1/40', 65537, 'dead:beef:0000:0000:0000:0000:0001:0001/40'],
     );

use NetAddr::IP;
use Test::More;

my($a, $ip, $test);

plan tests => 5 * @addr + 4;

for $a (@addr) {
	$ip = new NetAddr::IP $a->[0];
	$a->[0] =~ s,/\d+,,;
	isa_ok($ip, 'NetAddr::IP');
	is($ip->compact_addr, $a->[0]);
	is($ip->bits, 128);
	is($ip->version, 6);
	is($ip->nth($a->[1]), $a->[2]);
}

$test = new NetAddr::IP f34::1;
isa_ok($test, 'NetAddr::IP');
ok($ip->network->contains($test), "->contains");

$test = new NetAddr::IP f35::1/40;
isa_ok($test, 'NetAddr::IP');
ok(!$ip->network->contains($test), "!->contains");




