#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Warnings qw(warning);
use Socket ();    # no import: AF_INET6 would collide with the one under test

use NetAddr::IP::InetBase qw( AF_INET AF_INET6 fake_AF_INET6 );

is( AF_INET(), 2, 'AF_INET is 2' );

is( AF_INET6(), Socket::AF_INET6(), 'AF_INET6 is the value from Socket' );

# fake_AF_INET6 is deprecated: it still imports, returns 0 and warns
my $fake;
like(
    warning { $fake = fake_AF_INET6() },
    qr/\Afake_AF_INET6 is deprecated and will be removed in version 5;/,
    'fake_AF_INET6 warns that it is deprecated'
);
is( $fake, 0, 'fake_AF_INET6 returns 0' );
{
    no warnings 'deprecated';
    is( fake_AF_INET6(), 0,
        'fake_AF_INET6 is quiet where deprecated warnings are off' );
}

done_testing;
