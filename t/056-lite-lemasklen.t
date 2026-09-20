#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my @masks = 0 .. 32;

for my $m (@masks) {
    my $ip = NetAddr::IP::Lite->new('192.0.2.1', $m);
    ok($ip->masklen == $m, "mask $m");
}

done_testing;
