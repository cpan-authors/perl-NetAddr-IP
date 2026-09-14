#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my @addr = qw(
    0.0.0.0/0
    1.0.0.0/1
    2.0.0.0/2
    10.0.0.0/8
    10.0.120.0/24
    161.196.66.0/25
    255.255.255.255/32
);

subtest 'CIDR round-trip' => sub {
    for my $a (@addr) {
        my $ip = NetAddr::IP::Lite->new($a);
        is($ip->cidr, $a, "CIDR for $a");
    }
};

done_testing;
