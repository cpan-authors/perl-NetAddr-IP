#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP ();

my %addr = (
    'localhost'      => '0.0.0.0',
    '10.0.0.0/24'    => '0.0.0.255',
    '192.168.0.0/16' => '0.0.255.255',
    '10.128.0.1/17'  => '0.0.127.255',
);

for my $input (sort keys %addr) {
    my $ip = NetAddr::IP->new($input);

    is($ip->wildcard, $addr{$input}, "wildcard for $input");
    is(($ip->wildcard)[1], $addr{$input}, "wildcard list for $input");
}

done_testing;
