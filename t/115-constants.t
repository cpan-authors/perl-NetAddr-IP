#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Constants qw(:all);

subtest 'Constants module exports :all tag' => sub {
    # Test that all documented constants are exported
    my @expected = qw(
        DEFAULT_NETLIMIT_EXP
        IPV4_BITS
        IPV4_OFFSET
        IPV6_BITS
        MAX_BCD_DIGITS
        MAX_NETLIMIT_EXP
        MAX_OCTET
        MAX_SHIFTLEFT
        OCTET_BITS
        OCTET_COUNT
        PACKED_BCD_BYTES
        RFC3021_THRESHOLD
        V4_PACKED_BYTES
        V6_PACKED_BYTES
    );

    for my $const (@expected) {
        my $full = "NetAddr::IP::Constants::$const";
        no strict 'refs';
        ok(defined ${$full},
            "constant $const is exported");
    }
};

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
