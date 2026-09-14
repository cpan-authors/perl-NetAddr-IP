#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my @addrs = (
    '::foo',
    '::f00/129',
    '::f00/150',
);

for my $addr (@addrs) {
    ok(!NetAddr::IP::Lite->new($addr), "$addr returns undef");
}

done_testing;
