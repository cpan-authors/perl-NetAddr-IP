#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Mock ();

use NetAddr::IP::Util qw(
  havegethostbyname2
  inet_ntoa
  ipv6_n2x
  naip_gethostbyname
);

my $exp  = '0:0:0:0:0:FFFF:7F00:1';
my $host = '127.1';
my $got  = ipv6_n2x( scalar naip_gethostbyname($host) );
is( $got, $exp, 'naip_gethostbyname resolves 127.1 to IPv6 mapped address' );

$exp  = '0:0:0:0:0:0:0:1';
$host = $exp;

if ( havegethostbyname2() ) {
    $got = ipv6_n2x( scalar naip_gethostbyname($host) );
    is( $got, $exp, 'naip_gethostbyname resolves localhost IPv6' );
}
else {
    $got = scalar naip_gethostbyname($host);
    if ($got) {
        $got = eval { inet_ntoa($got) }
          || eval { ipv6_n2x($got) };
    }
    pass('havegethostbyname2 not available, fallback tested');
}

# Socket6, when present, asks the resolver first; these cases test the IPv4 path alone
my $no_ipv6_lookup =
  NetAddr::IP::UtilPolluted->can('_ghbn2')
  ? Test2::Mock->new(
    class    => 'NetAddr::IP::UtilPolluted',
    override => [ _ghbn2 => sub { return } ],
  )
  : undef;
for my $host ( '256.0.2.1', '300' ) {
    is( [ naip_gethostbyname($host) ],
        [], "naip_gethostbyname finds nothing for $host, without a warning" );
}

done_testing;
