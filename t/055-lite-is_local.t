#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my %ips = (
    '126.255.255.255' => 0,
    '127.0.0.0'       => 1,
    '127.0.0.1'       => 1,
    '127.255.255.254' => 1,
    '127.255.255.255' => 1,
    '128.0.0.0'       => 0,
    '::0'             => 0,
    '::1'             => 1,
    '::2'             => 0,
);

for my $addr (sort keys %ips) {
    my $ip  = NetAddr::IP::Lite->new($addr);
    my $got = $ip->is_local();
    my $exp = $ips{$addr};
    cmp_ok($got, '==', $exp, "is_local($addr) returns $exp");
}

done_testing;
