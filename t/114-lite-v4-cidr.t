#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

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
    for my $addr (@addr) {
        my $ip = NetAddr::IP::Lite->new($addr);
        is($ip->cidr, $addr, "CIDR for $addr");
    }
};

done_testing;
