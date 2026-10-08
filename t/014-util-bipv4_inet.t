#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::InetBase qw( fillIPv4 inet_aton inet_ntoa );

my @addrs = qw(
  0.0.0.0
  255.255.255.255
  192.0.2.4
  192.0.2.5
);

for my $addr (@addrs) {
    my @digs   = split( /\./, $addr );
    my $pkd    = pack( 'C4', @digs );
    my $naddr  = inet_aton($addr);
    my $packed = join( '.', unpack( 'C4', $naddr ) );
    my $num    = inet_ntoa($pkd);

    ok( $naddr eq $pkd, 'pack/unpack bits match for ' . $addr );
    is( $packed, $addr, 'inet_aton roundtrip for ' . $addr );
    is( $num,    $addr, 'inet_ntoa roundtrip for ' . $addr );
}

subtest 'fillIPv4 pads short forms and rejects any part above 255' => sub {
    my @cases = (
        [ '0',           '0.0.0.0' ],
        [ '10',          '0.0.0.10' ],
        [ '255',         '0.0.0.255' ],
        [ '256',         undef ],
        [ '300',         undef ],
        [ '4294967295',  undef ],
        [ '192.0',       '192.0.0.0' ],
        [ '192.256',     undef ],
        [ '192.0.2',     '192.0.0.2' ],
        [ '192.0.256',   undef ],
        [ '192.0.2.1',   '192.0.2.1' ],
        [ '256.0.2.1',   undef ],
        [ 'example.com', 'example.com' ],
    );
    for my $case (@cases) {
        my ( $input, $want ) = @{$case};
        is( fillIPv4($input), $want, "fillIPv4 of $input" );
    }
};

done_testing;
