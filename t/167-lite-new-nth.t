#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use Config;
use Math::BigInt;
use NetAddr::IP::Lite ();

my $ip4 = NetAddr::IP::Lite->new('192.0.2.11/29');

subtest 'nth tests' => sub {
    my %try = (
        0 => '192.0.2.9',
        1 => '192.0.2.10',
        2 => '192.0.2.11',
        3 => '192.0.2.12',
        4 => '192.0.2.13',
        5 => '192.0.2.14',
        6 => 'undef',
    );

    for my $input ( sort { $a <=> $b } keys %try ) {
        my $rv = $ip4->nth($input);
        $rv =
          defined $rv
          ? $rv->addr
          : 'undef';
        is( $rv, $try{$input}, "nth($input) returns $try{$input}" );
    }
};

{
    my $ip  = NetAddr::IP::Lite->new('192.0.2.4/32');
    my $num = $ip->num();
    is( $num, 1, 'num() returns 1 for /32' );
}

{
    my $ip  = NetAddr::IP::Lite->new('192.0.2.4/31');
    my $num = $ip->num();
    is( $num, 2, 'num() returns 2 for /31' );
}

## issue #10 – non-integer indices must be rejected

my $net = NetAddr::IP::Lite->new('10.0.0.0/24');

is( $net->nth(1.5),         undef, 'nth(1.5) returns undef' );
is( $net->nth(1.9),         undef, 'nth(1.9) returns undef' );
is( $net->nth(0.1),         undef, 'nth(0.1) returns undef' );
is( $net->nth("2.5"),       undef, 'nth("2.5") returns undef' );
is( $net->nth("abc"),       undef, 'nth("abc") returns undef' );
is( $net->nth(undef),       undef, 'nth(undef) returns undef' );
is( defined $net->nth(0),   1,     'nth(0) is defined' );
is( defined $net->nth(1),   1,     'nth(1) is defined' );
is( defined $net->nth(-1),  '',    'nth(-1) is undef' );
is( defined $net->nth(254), '',    'nth(254) is undef' );

subtest 'an index of 2**64 - 1 or more is exact' => sub {
    my $v6_32 = NetAddr::IP::Lite->new('2001:db8::/32');
    my $v6_64 = NetAddr::IP::Lite->new('2001:db8::/64');
    my $big   = Math::BigInt->new('18446744073709551615');

    # eval, so a croak fails its own assertion and the rest still run
    my $nth = sub {
        my $rv = eval { $_[0]->nth( $_[1] ) };
        return $@ ? 'croaks' : defined $rv ? $rv->addr : 'undef';
    };

    # a /32 holds 2**96 - 2 hosts, so 2**64 - 1 is an index inside it
    is( $nth->( $v6_32, '18446744073709551615' ),
        '2001:DB8:0:1:0:0:0:0', 'nth(2**64 - 1) of a /32, as a string' );
    is( $nth->( $v6_32, '18446744073709551616' ),
        '2001:DB8:0:1:0:0:0:1', 'nth(2**64) of a /32' );
  SKIP: {
        skip 'a 32 bit perl reads 18446744073709551615 as a float', 1
          if $Config{ivsize} < 8;
        is( $nth->( $v6_32, 18_446_744_073_709_551_615 ),
            '2001:DB8:0:1:0:0:0:0', 'nth(2**64 - 1) of a /32, as a number' );
    }
    is( $nth->( $v6_32, $big ),
        '2001:DB8:0:1:0:0:0:0', 'nth(2**64 - 1) of a /32, as a Math::BigInt' );
    is(
        $nth->( $v6_32, '79228162514264337593543950333' ),
        '2001:DB8:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE',
        'nth(2**96 - 3), the last index of a /32'
    );
    is( $nth->( $v6_32, '79228162514264337593543950334' ),
        'undef', 'nth(2**96 - 2), one past the last index of a /32' );
    is( $nth->( $v6_32, '340282366920938463463374607431768211455' ),
        'undef', 'nth(2**128 - 1) of a /32' );
    is( $nth->( $v6_32, '340282366920938463463374607431768211456' ),
        'undef', 'nth(2**128) of a /32' );

    # a /64 holds 2**64 - 2 hosts
    is(
        $nth->( $v6_64, '18446744073709551613' ),
        '2001:DB8:0:0:FFFF:FFFF:FFFF:FFFE',
        'nth(2**64 - 3), the last index of a /64'
    );
    is( $nth->( $v6_64, '18446744073709551614' ),
        'undef', 'nth(2**64 - 2), one past the last index of a /64' );
    is( $nth->( $v6_64, '18446744073709551615' ),
        'undef', 'nth(2**64 - 1) of a /64, as a string' );
    is( $nth->( $v6_64, $big ),
        'undef', 'nth(2**64 - 1) of a /64, as a Math::BigInt' );

    # :old_nth caps num() at 2**32 - 2
    local $NetAddr::IP::Lite::Old_nth = 1;
    is( $nth->( $v6_32, '18446744073709551615' ),
        'undef', 'nth(2**64 - 1) of a /32 under :old_nth' );
};

subtest '-0, leading zeros, and the one host of a /32 or /128' => sub {
    my $v6_64 = NetAddr::IP::Lite->new('2001:db8::/64');
    my $addr  = sub {
        my $rv = $_[0]->nth( $_[1] );
        return defined $rv ? $rv->addr : 'undef';
    };

    is( $addr->( $v6_64, '-0' ),
        '2001:DB8:0:0:0:0:0:1', 'nth("-0") of a /64 is index 0' );
    is( $addr->( $v6_64, ( '0' x 50 ) . '5' ),
        '2001:DB8:0:0:0:0:0:6',
        'nth(5) of a /64, written with 50 leading zeros' );
    is( $addr->( NetAddr::IP::Lite->new('192.0.2.4/32'), 0 ),
        '192.0.2.4', 'nth(0) of 192.0.2.4/32 is its own address' );
    is( $addr->( NetAddr::IP::Lite->new('2001:db8::4/128'), 0 ),
        '2001:DB8:0:0:0:0:0:4',
        'nth(0) of 2001:db8::4/128 is its own address' );
};

done_testing;
