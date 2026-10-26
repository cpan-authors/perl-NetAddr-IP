#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw(
  havegethostbyname2
  ipv6_n2x
  naip_gethostbyname
);

my $exp  = '0:0:0:0:0:FFFF:7F00:1';
my $host = '127.1';
my $got  = ipv6_n2x( scalar naip_gethostbyname($host) );
is( $got, $exp, 'naip_gethostbyname resolves 127.1 to IPv6 mapped address' );

ok( havegethostbyname2(), 'havegethostbyname2 is true' );

$exp  = '0:0:0:0:0:0:0:1';
$host = $exp;
$got  = ipv6_n2x( scalar naip_gethostbyname($host) );
is( $got, $exp, 'naip_gethostbyname resolves localhost IPv6' );

for my $host ( '256.0.2.1', '300' ) {
    is( [ naip_gethostbyname($host) ],
        [], "naip_gethostbyname finds nothing for $host, without a warning" );
}

done_testing;
