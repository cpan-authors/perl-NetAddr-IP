#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );
use Test2::Tools::Warnings  qw( warning );

use NetAddr::IP qw(netlimit);

subtest 'netlimit rejects invalid and out-of-range values' => sub {
    local $NetAddr::IP::netlimit = 16;

    is( netlimit(undef),        undef, 'undef is rejected' );
    is( netlimit(''),           undef, 'empty string is rejected' );
    is( netlimit('20x'),        undef, 'non-digit value is rejected' );
    is( netlimit(10),           undef, 'value below default is rejected' );
    is( netlimit(25),           undef, 'value above maximum is rejected' );
    is( netlimit(16),           65536, 'default value is accepted' );
    is( $NetAddr::IP::netlimit, 16,    'stored exponent remains valid' );
};

subtest 'full6m formats mask in upper and lower case' => sub {
    my $ip = NetAddr::IP->new('2001:db8::/48');
    is(
        $ip->full6m,
        'FFFF:FFFF:FFFF:0000:0000:0000:0000:0000',
        'full6m upper-case mask'
    );
    {
        local $NetAddr::IP::InetBase::Upper = 0;
        is(
            $ip->full6m,
            'ffff:ffff:ffff:0000:0000:0000:0000:0000',
            'full6m lower-case mask'
        );
    }

    my $v4 = NetAddr::IP->new('192.0.2.1/24');
    is(
        $v4->full6m,
        'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FF00',
        'full6m IPv4 mask in IPv6 form'
    );
};

subtest 'mod_version returns version and DESTROY is callable' => sub {
    is( NetAddr::IP->mod_version(),
        $NetAddr::IP::VERSION, 'mod_version matches package version' );
    is( NetAddr::IP::mod_version(),
        $NetAddr::IP::VERSION, 'mod_version is callable as a function' );
    ok( lives { NetAddr::IP->DESTROY; 1 }, 'DESTROY is callable' );
};

subtest ':aton import warns and sets Lite binary IP acceptance' => sub {
    local $NetAddr::IP::Lite::Accept_Binary_IP = 0;
    my $w = warning { NetAddr::IP->import(':aton') };
    like( $w, qr/:aton is deprecated/, ':aton warns as deprecated' );
    is( $NetAddr::IP::Lite::Accept_Binary_IP, 1,
        ':aton sets Accept_Binary_IP' );
    $NetAddr::IP::Lite::Accept_Binary_IP = 0;
};

subtest 'split and rsplit return lists' => sub {
    my $ip = NetAddr::IP->new('192.0.2.0/30');
    is(
        [ map { $_->cidr } $ip->split(31) ],
        [ '192.0.2.0/31', '192.0.2.2/31' ],
        'split returns subnet list'
    );
    is(
        [ map { $_->cidr } $ip->rsplit(31) ],
        [ '192.0.2.0/31', '192.0.2.2/31' ],
        'rsplit returns subnet list'
    );
};

done_testing;
