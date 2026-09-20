#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use NetAddr::IP::Lite qw( Ones V4mask V4net Zero Zeros );

my %const = (
    '0::'                                     => Zeros,
    '::'                                      => Zero,
    'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF' => Ones,
    'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF::'         => V4mask,
    '::FFFF:FFFF'                             => V4net,
);

for my $key (sort keys %const) {
    my $ip = NetAddr::IP::Lite->new($key);
    ok($ip, "netaddr $key");
    ok($ip->{addr} eq $const{$key}, "match $key");
    ok(length($const{$key}) == 16, "length $key is 16");
}

done_testing;
