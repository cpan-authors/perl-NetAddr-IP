#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my @addrs = (
    '::foo',
    '::f00/129',
    '::f00/150',
    '340282366920938463463374607431768211456',	# 2**128
    '9999999999999999999999999999999999999999',	# 40 nines
    '99999999999999999999999999999999999999999',	# 41 nines
);

for my $addr (@addrs) {
    ok(!NetAddr::IP::Lite->new($addr), "$addr returns undef");
}

done_testing;
