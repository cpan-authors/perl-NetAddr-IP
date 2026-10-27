#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw(add128 ipv6_aton ipv6_n2x sub128);

my @pair = ( ipv6_aton('2001:db8::5'), ipv6_aton('::1') );

subtest 'add128 and sub128 take their two addresses from an array' => sub {

    # compiled here, where a $$ prototype would refuse the array
    my ( undef, $sum ) = eval q{ add128(@pair) };
    is( $@, '', 'add128(@pair) compiles and runs' );
    is(
        defined $sum ? ipv6_n2x($sum) : undef,
        '2001:DB8:0:0:0:0:0:6',
        'add128(@pair) adds the two addresses'
    );

    my ( undef, $difference ) = eval q{ sub128(@pair) };
    is( $@, '', 'sub128(@pair) compiles and runs' );
    is( defined $difference ? ipv6_n2x($difference) : undef,
        '2001:DB8:0:0:0:0:0:4', 'sub128(@pair) subtracts the second address' );
};

subtest 'two scalars still work, with or without brackets' => sub {
    my ( $first, $second ) = @pair;
    my ( undef,  $sum )    = add128( $first, $second );
    is( ipv6_n2x($sum), '2001:DB8:0:0:0:0:0:6', 'add128($first, $second)' );
    my @result = sub128 $first, $second;
    is(
        ipv6_n2x( $result[1] ),
        '2001:DB8:0:0:0:0:0:4',
        'sub128 $first, $second'
    );
};

done_testing;
