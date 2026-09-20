#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( ipv6_aton ipv6_n2x );

my %addr = (
    '::'                 => '0:0:0:0:0:0:0:0',
    ':::'                => undef,
    'foo'                => undef,
    '::foo'              => undef,
    'foo::'              => undef,
    'abc::def::9'        => undef,
    'abcd1::'            => undef,
    'abcd::'             => 'abcd:0:0:0:0:0:0:0',
    '::abcde'            => undef,
    ':a:b:c:d:1:2:3:4'   => undef,
    ':a:b:c:d'           => undef,
    'a:b:c:d:1:2:3:4:'   => undef,
    'a:b:c:d:1:2:3::'    => undef,
    '::a:b:c:d:1:2:3:4'  => undef,
    '::a:b:c:d:1:2:3'    => '0:a:b:c:d:1:2:3',
    '::a:b:c:d:1:2:3:'   => undef,
    ':a:b:c:d:1:2:3::'   => undef,
    'a:b:c:d:1:2:3::'    => 'a:b:c:d:1:2:3:0',
);

subtest 'ipv6_aton and ipv6_n2x' => sub {
    for my $input (sort keys %addr) {
        my $expected = $addr{$input};

        if (defined $expected) {
            my $rv = ipv6_aton($input);
            ok($rv, "ipv6_aton($input) returns a value");
            my $hex = ipv6_n2x($rv) || 'not defined';
            is($hex, uc($expected), "ipv6_n2x(ipv6_aton($input)) returns $expected");
        }
        else {
            pass("ipv6_aton($input) - skipped, expected undef");
        }
    }
};

done_testing;
