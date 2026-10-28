#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Lite ();

my $ip = NetAddr::IP::Lite->new('0.0.0.4/24');
my $nip;

## test '+' and '-' reject a constant that is not a number
for my $bad ( 'x', '-x', '--7', '5abc', '0x10', '0b11' ) {
    like(
        dies { my $sum = $ip + $bad },
        qr/constant must be an exact integer/,
        "addition croaks on '$bad'",
    );
    like(
        dies { my $dif = $ip - $bad },
        qr/constant must be an exact integer/,
        "subtraction croaks on '$bad'",
    );
}

## test '+' and '-' accept a string that is a number
is( $ip + ' 7',  '0.0.0.11/24',  'addition accepts a padded numeric string' );
is( $ip - '1e1', '0.0.0.250/24', 'subtraction accepts an exponent string' );

## a missing or zero constant returns a copy, as the POD promises, for
## both operators and for undef as well as the empty string
for my $missing ( undef, '', 0, '0' ) {
    my $label = defined $missing ? "'$missing'" : 'undef';
    is( $ip + $missing, '0.0.0.4/24', "addition returns a copy for $label" );
    is( $ip - $missing, '0.0.0.4/24', "subtraction returns a copy for $label" );
}

## test '+'
$nip = $ip + 128;
is( "$nip", '0.0.0.132/24', 'addition' );

## test '+' wrap around
$nip = $ip + 257;
is( "$nip", '0.0.0.5/24', 'addition wrap around' );

## test '-' and wrap
$nip = $ip - 10;
is( "$nip", '0.0.0.250/24', 'subtraction and wrap' );

## test '++' post
$nip++;
is( "$nip", '0.0.0.251/24', 'post increment' );

## test '++' pre
++$nip;
is( "$nip", '0.0.0.252/24', 'pre increment' );

## test '--' post
$ip--;
is( "$ip", '0.0.0.3/24', 'post decrement' );

## test '--' pre
--$ip;
is( "$ip", '0.0.0.2/24', 'pre decrement' );

subtest 'subtraction takes every constant that addition takes' => sub {
    my $v4 = NetAddr::IP::Lite->new('198.51.100.7/24');
    my $v6 = NetAddr::IP::Lite->new('2001:db8::/32');

    # from 2**63 + 1 up, an unsigned integer has no negative of the same size
    for my $case (
        [ 9223372036854775808,  '2001:DB8:FFFF:FFFF:8000:0:0:0/32', '198.51.100.7/24' ],
        [ 9223372036854775809,  '2001:DB8:FFFF:FFFF:7FFF:FFFF:FFFF:FFFF/32', '198.51.100.6/24' ],
        [ 18446744073709551615, '2001:DB8:FFFF:FFFF:0:0:0:1/32', '198.51.100.8/24' ],
      )
    {
        my ( $const, $want_v6, $want_v4 ) = @{$case};

        # eval, so a croak fails its own assertion and the rest still run
        is( eval { "" . ( $v6 - $const ) }, $want_v6, "2001:db8::/32 - $const" );
        is( eval { "" . ( $v6 - "$const" ) },
            $want_v6, "2001:db8::/32 - '$const' as a string" );
        is( eval { "" . ( $v4 - $const ) }, $want_v4, "198.51.100.7/24 - $const" );
        is( eval { "" . ( $v6 - $const + $const ) },
            "$v6", "2001:db8::/32 - $const + $const" );
        is( eval { "" . ( $v6 + $const - $const ) },
            "$v6", "2001:db8::/32 + $const - $const" );
        is( eval { "" . ( $v4 + $const - $const ) },
            "$v4", "198.51.100.7/24 + $const - $const" );
    }

    is( $v6 - -9223372036854775808, '2001:DB8:0:0:8000:0:0:0/32',
        '2001:db8::/32 - -2**63' );
    is( $v6 - 2147483648, '2001:DB8:FFFF:FFFF:FFFF:FFFF:8000:0/32',
        '2001:db8::/32 - 2**31' );
    is( $v6 + -2147483648, '2001:DB8:FFFF:FFFF:FFFF:FFFF:8000:0/32',
        '2001:db8::/32 + -2**31' );
    is( $v6 - -2147483648, '2001:DB8:0:0:0:0:8000:0/32',
        '2001:db8::/32 - -2**31' );

    for my $case (
        [ 18446744073709551616,  '2**64, a float' ],
        [ -18446744073709551616, '-2**64, a float' ],
        [ 1e16,                  '1e16, a float above 2**53' ],
      )
    {
        my ( $const, $name ) = @{$case};
        like(
            dies { my $sum = $v6 + $const },
            qr/constant must be an exact integer/,
            "addition croaks on $name"
        );
        like(
            dies { my $dif = $v6 - $const },
            qr/constant must be an exact integer/,
            "subtraction croaks on $name"
        );
    }
};

done_testing;
