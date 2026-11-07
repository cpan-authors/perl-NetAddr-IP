#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

subtest 'regular subnets' => sub {
    my $ip4 = NetAddr::IP::Lite->new('1.2.3.11/29');
    my $ip6 = NetAddr::IP::Lite->new('FF::8B/125');

    is($ip4->first->addr, '1.2.3.9',           'IPv4 /29 first');
    is($ip4->last->addr,  '1.2.3.14',          'IPv4 /29 last');
    is($ip6->first->addr, 'FF:0:0:0:0:0:0:89', 'IPv6 /125 first');
    is($ip6->last->addr,  'FF:0:0:0:0:0:0:8E', 'IPv6 /125 last');
};

subtest 'point-to-point subnets' => sub {
    my $ip4 = NetAddr::IP::Lite->new('1.2.3.11/31');
    my $ip6 = NetAddr::IP::Lite->new('FF::8B/127');

    is($ip4->first->addr, '1.2.3.10',          'IPv4 /31 first');
    is($ip4->last->addr,  '1.2.3.11',          'IPv4 /31 last');
    is($ip6->first->addr, 'FF:0:0:0:0:0:0:8A', 'IPv6 /127 first');
    is($ip6->last->addr,  'FF:0:0:0:0:0:0:8B', 'IPv6 /127 last');
};

done_testing;
