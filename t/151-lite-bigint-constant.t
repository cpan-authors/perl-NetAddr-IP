#!/usr/bin/env perl

# Subtraction decides what its right-hand argument is by asking whether it
# is an address. "ref" was too broad a test, because a Math::BigInt is a
# reference too, so minus() read its {addr}, found nothing and died in
# sub128 with an argument-length complaint naming the wrong thing.

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies lives );

plan skip_all => 'Math::BigInt not found'
  unless eval { require Math::BigInt };

use NetAddr::IP       ();
use NetAddr::IP::Lite ();

my $v4    = NetAddr::IP::Lite->new('192.0.2.1/24');
my $v6    = NetAddr::IP::Lite->new('2001:db8::/64');
my $two32 = Math::BigInt->new('4294967296');

subtest 'a Math::BigInt is a constant, not an address' => sub {
    is(
        "" . ( $v4 + Math::BigInt->new(5) ),
        '192.0.2.6/24',
        'addition of a small Math::BigInt, which always worked'
    );
    is(
        "" . ( $v4 - Math::BigInt->new(5) ),
        '192.0.2.252/24',
        'subtraction of a small Math::BigInt'
    );
    is(
        "" . ( $v6 + $two32 ),
        '2001:DB8:0:0:0:1:0:0/64',
        'addition of 2**32 as a Math::BigInt, the 128 bit path'
    );
    is(
        "" . ( $v6 - $two32 ),
        '2001:DB8:0:0:FFFF:FFFF:0:0/64',
        'subtraction of 2**32 as a Math::BigInt, the 128 bit path'
    );
    is( "" . ( $v6 + $two32 - $two32 ),
        "$v6", 'adding then subtracting 2**32 returns the address' );
};

subtest 'the difference of two addresses still works' => sub {
    is(
        NetAddr::IP::Lite->new('192.0.2.9') -
          NetAddr::IP::Lite->new('192.0.2.1'),
        8,
        'two NetAddr::IP::Lite addresses'
    );
    is( NetAddr::IP->new('192.0.2.9') - NetAddr::IP->new('192.0.2.1'),
        8, 'two NetAddr::IP addresses, which inherit from Lite' );
    is( NetAddr::IP::Lite->new('192.0.2.9') - NetAddr::IP->new('192.0.2.1'),
        8, 'a Lite address minus an IP address' );

    # minus() returns a number here, not an address, and undef when the
    # difference does not fit the sign guard. Both predate this change.
    is(
        NetAddr::IP::Lite->new('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE/128') -
          NetAddr::IP::Lite->new('::1/128'),
        undef,
        'a difference outside the sign range is undef, as before'
    );
};

subtest 'a reference that is not an address is rejected as a constant' => sub {
    like(
        dies { my $dif = $v4 - [] },
        qr/constant must be an exact integer/,
        'an unblessed array reference, which isa cannot be called on'
    );
    like(
        dies { my $dif = $v4 - {} },
        qr/constant must be an exact integer/,
        'an unblessed hash reference'
    );
    like(
        dies { my $dif = $v4 - \'x' },
        qr/constant must be an exact integer/,
        'an unblessed scalar reference'
    );
    like(
        dies { my $dif = $v4 - bless( {}, 'Some::Other::Class' ) },
        qr/constant must be an exact integer/,
        'some other blessed class'
    );
  SKIP: {
        skip 'Math::BigFloat not found', 1
          unless eval { require Math::BigFloat; 1 };

        # A BigFloat of 1 numifies to exactly 1 and is a valid constant,
        # so this wants a value that numifies to something fractional,
        # to show that plus()'s integer guard sees through the overload.
        like(
            dies { my $dif = $v4 - Math::BigFloat->new('1.5') },
            qr/constant must be an exact integer/,
            'a Math::BigFloat of 1.5, blessed, numifies, but is not an integer'
        );
    }
};

subtest 'plain scalars behave as before' => sub {
    is( "" . ( $v4 - 5 ), '192.0.2.252/24', 'a small integer' );
    is(
        "" . ( $v6 - $two32 ),
        "" . ( $v6 - Math::BigInt->new('4294967296') ),
        'a string of digits and a Math::BigInt agree'
    );
    is( "" . ( $v4 - '5' ), '192.0.2.252/24', 'a quoted small integer' );
    like(
        dies { my $dif = $v4 - '0x10' },
        qr/constant must be an exact integer/,
        'a non-numeric string is still rejected'
    );
};

done_testing;
