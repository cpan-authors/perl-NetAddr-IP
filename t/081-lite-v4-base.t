#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my @addr = (qw( 127.0.0.1 10.0.0.1 ));
my @mask = (qw( 255.0.0.0 255.255.0.0 255.255.255.0 255.255.255.255 ));

for my $addr (@addr) {
    for my $m (@mask) {
        my $ip = NetAddr::IP::Lite->new($addr, $m);
        is($ip->addr, $addr, "addr for $addr $m");
        is($ip->mask, $m, "mask for $addr $m");
    }
}

done_testing;
