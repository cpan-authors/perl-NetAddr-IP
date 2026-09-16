#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my %w = (
    'default'      => ['255.255.255.254', '0.0.0.0'],
    'loopback'     => ['127.255.255.254', '255.0.0.0'],
    '127.0.0.1/8'  => ['127.255.255.254', '255.0.0.0'],
    '10.'          => ['10.255.255.254',  '255.0.0.0'],
    '10.10.10/24'  => ['10.10.10.254',    '255.255.255.0'],
);

for my $key (keys %w) {
    my $ip = NetAddr::IP::Lite->new($key)->last;

    is($ip->addr, $w{$key}->[0], "$key last address");
    is($ip->mask, $w{$key}->[1], "$key last mask");
}

done_testing;
