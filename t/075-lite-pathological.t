#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

subtest 'bad addresses' => sub {
    my @addrs = (
        '::foo',
        '::f00/129',
        '::f00/150',
        '340282366920938463463374607431768211456',	 # 2**128
        '9999999999999999999999999999999999999999',	 # 40 nines
        '99999999999999999999999999999999999999999', # 41 nines
    );
    for my $addr (@addrs) {
	    ok(!NetAddr::IP::Lite->new($addr), "new('$addr') returns undef");
    }
};

subtest 'bad masks' => sub {
    my %bad = (
	# empty / whitespace, non-numeric, out-of-range CIDR for IPv4
	    '1.2.3.4'     => ['', ' ', 'abc', '-1', '-8', '24.5', '0xff', '33', '129', '256', '999'],
	# out-of-range CIDR, non-numeric for IPv6
	    '::1'         => ['129', '256'],
	    '2001:db8::1' => ['abc', '0xff'],
    );
    for my $addr (sort keys %bad) {
	for my $mask (@{$bad{$addr}}) {
	    ok(!NetAddr::IP::Lite->new($addr, $mask),
	       "new('$addr', '$mask') returns undef");
	}
    }
};

done_testing;
