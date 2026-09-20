#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use NetAddr::IP ();

my @masks = 0 .. 32;

for my $m (@masks) {
    my $ip = NetAddr::IP->new('10.0.0.1', $m);
    is($ip->masklen, $m, "masklen for mask $m");
}

done_testing;
