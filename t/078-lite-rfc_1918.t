#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %ips = (
    '9.255.255.255'    => 0,
    '10.0.0.0'         => 1,
    '10.255.255.255'   => 1,
    '11.0.0.0'         => 0,
    '172.15.255.255'   => 0,
    '172.16.0.0'       => 1,
    '172.31.255.255'   => 1,
    '172.32.0.0'       => 0,
    '192.167.255.255'  => 0,
    '192.168.0.0'      => 1,
    '192.168.255.255'  => 1,
    '192.169.0.0'      => 0,
);

for my $addr (sort keys %ips) {
    my $ip = NetAddr::IP::Lite->new($addr);
    my $got = $ip->is_rfc1918();
    my $exp = $ips{$addr};
    is($got, $exp, "$ip is_rfc1918 = $exp");
}

done_testing;
