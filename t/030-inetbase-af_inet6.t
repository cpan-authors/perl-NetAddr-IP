#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Config;
use Socket ();    # no import: AF_INET6 would collide with the one under test

use NetAddr::IP::InetBase qw( AF_INET AF_INET6 fake_AF_INET6 );

is( AF_INET(), 2, 'AF_INET is 2' );

my $fake     = fake_AF_INET6();
my $af_inet6 = AF_INET6();
my $af_info =
  $fake
  ? "Socket has no AF_INET6; guessed it for $Config{osname} = $fake"
  : "AF_INET6 = $af_inet6 from Socket"
  . ( $INC{'Socket6.pm'} ? ' or Socket6' : '' );
note($af_info);

ok( defined $af_inet6, 'AF_INET6 is defined' );

# where Socket has AF_INET6, it is the one bound, with or without Socket6;
# the per-OS guess is tested in t/154
SKIP: {
    skip( 'Socket has no AF_INET6 on this perl', 3 )
      unless defined &Socket::AF_INET6;

    is( \&AF_INET6, \&Socket::AF_INET6,
        'AF_INET6 is Socket::AF_INET6, not a guess from the per-OS table' );
    is( fake_AF_INET6(), 0,
        'fake_AF_INET6 is 0 when Socket provides AF_INET6' );
    is( AF_INET6(), Socket::AF_INET6(),
        'AF_INET6 agrees with Socket::AF_INET6' );
}

done_testing;
