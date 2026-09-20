#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %nets = (
    '10.0.0.16'     => [24, '10.0.0.255',      '10.0.0.0'],
    '127.0.0.1'     => [8,  '127.255.255.255', '127.0.0.0'],
    '192.168.0.10'  => [17, '192.168.127.255', '192.168.0.0'],
);

for my $addr (keys %nets) {
    my $ip = NetAddr::IP::Lite->new($addr, $nets{$addr}->[0]);
    is($ip->broadcast->addr, $nets{$addr}->[1], "$addr broadcast");
    is($ip->network->addr, $nets{$addr}->[2], "$addr network");
}

done_testing;
