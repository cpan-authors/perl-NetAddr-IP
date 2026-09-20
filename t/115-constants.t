#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP qw( Ones V4mask V4net Zero Zeros );

my %const = (
    '0::'                                     => Zeros,
    '::'                                      => Zero,
    'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF' => Ones,
    'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF::'         => V4mask,
    '::FFFF:FFFF'                             => V4net,
);

for my $key (sort keys %const) {
    my $ip = NetAddr::IP->new($key);
    ok($ip, "netaddr $key");
    cmp_ok($ip->{addr}, 'eq', $const{$key}, "match $key");
    my $rv = length($const{$key});
    cmp_ok($rv, '==', 16, "length $key is $rv");
}

done_testing;
