#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies lives );
use NetAddr::IP             ();

my $big = NetAddr::IP->new('10.0.0.0/8');

subtest 'netlimit exceeded' => sub {
    like(
        dies { $big->hostenum },
        qr/^netlimit exceeded/,
        'hostenum over netlimit'
    );
    like(
        dies { $big->hostenumref },
        qr/^netlimit exceeded/,
        'hostenumref over netlimit'
    );
    like(
        dies { $big->splitref(32) },
        qr/^netlimit exceeded/,
        'splitref over netlimit'
    );
    like(
        dies { $big->split(32) },
        qr/^netlimit exceeded/,
        'split over netlimit'
    );
    like(
        dies { $big->rsplit( 24, 32 ) },
        qr/^netlimit exceeded/,
        'rsplit with mask list over netlimit'
    );
    like(
        dies { NetAddr::IP->new('2001:db8::/48')->split(128) },
        qr/^netlimit exceeded/,
        'ipv6 split over netlimit'
    );
};

subtest 'netmask error' => sub {
    like(
        dies { NetAddr::IP->new('10.0.0.0/24')->split(16) },
        qr/^netmask error/,
        'shorter mask still dies with netmask error'
    );
};

subtest 'exact netlimit' => sub {
    ok( lives { NetAddr::IP->new('10.0.0.0/16')->splitref(32) },
        'split of exactly netlimit nets succeeds' );
};

subtest 'short plans' => sub {
    my $r;
    ok(
        lives { $r = $big->splitref( 9 .. 25, 25 ) },
        'split of a /8 into 9..25 with a /25 tail lives'
    );
    is( scalar @{ $r || [] }, 18, 'that split is 18 nets' );
    ok(
        lives {
            $r = NetAddr::IP->new('2001:db8::/32')->splitref( 33 .. 64, 64 )
        },
        'split of a /32 into 33..64 with a /64 tail lives'
    );
    is( scalar @{ $r || [] }, 33, 'that split is 33 nets' );
};

subtest 'local scopes the exponent' => sub {
    is( $NetAddr::IP::netlimit, 16, 'the default exponent is 16' );
    {
        local $NetAddr::IP::netlimit;
        is( NetAddr::IP::netlimit(20), 1_048_576, 'netlimit(20) returns 2**20' );
        is( $NetAddr::IP::netlimit, 20, 'netlimit(20) stores the exponent' );
    }
    is( $NetAddr::IP::netlimit, 16, 'the exponent is 16 again after netlimit(20)' );

    my $ip = NetAddr::IP->new('192.0.2.0/24');
    {
        local $NetAddr::IP::netlimit = 2;
        like(
            dies { $ip->split(27) },
            qr/^netlimit exceeded/,
            'exponent 2 rejects a plan of 8 nets'
        );
    }
    is( $NetAddr::IP::netlimit, 16, 'the exponent is 16 again after the block' );
};

done_testing;
