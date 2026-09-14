#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my @addr = (qw( 127.0.0.1 10.0.0.1 ));
my @mask = (qw( 255.0.0.0 255.255.0.0 255.255.255.0 255.255.255.255 ));

for my $a (@addr) {
    for my $m (@mask) {
        my $ip = NetAddr::IP::Lite->new($a, $m);
        is($ip->addr, $a, "addr for $a $m");
        is($ip->mask, $m, "mask for $a $m");
    }
}

done_testing;
