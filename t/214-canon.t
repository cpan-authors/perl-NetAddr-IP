#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP ();

my %cases = (
    '127.1'                                   => '127.0.0.1',
    'DEAD:BEEF::1'                            => 'dead:beef::1',
    '1234:5678:90AB:CDEF:0123:4567:890A:BCDE' =>
      '1234:5678:90ab:cdef:123:4567:890a:bcde',

    # RFC 5952 4.2.3: equal length zero runs, the first one is compressed
    '0:0:0:1:0:0:0:2'     => '::1:0:0:0:2',
    '1:0:0:2:0:0:3:4'     => '1::2:0:0:3:4',
    '0:0:1:0:0:0:2:3'     => '0:0:1::2:3',
    '0:0:33:44:0:0:CC:DD' => '::33:44:0:0:cc:dd',
    '1:0:0:2:3:4:0:0'     => '1::2:3:4:0:0',

    # RFC 5952 5: the IPv4-mapped prefix uses mixed notation
    '::ffff:192.0.2.1' => '::ffff:192.0.2.1',
    '::ffff:c000:201'  => '::ffff:192.0.2.1',
    '::ffff:0:0'       => '::ffff:0.0.0.0',
    '::192.0.2.1'      => '::c000:201',
    '::1'              => '::1',
    '::'               => '::',
);

for my $c ( sort keys %cases ) {
    my $ip = NetAddr::IP->new($c);
    my $rv = $ip->canon;
    is( $rv, $cases{$c}, "canon($c ) returns $rv" );
}

is( NetAddr::IP->new6FFFF('192.0.2.1')->canon,
    '::ffff:192.0.2.1', 'new6FFFF uses mixed notation' );
is( lc NetAddr::IP->new6FFFF('192.0.2.1')->short,
    '::ffff:c000:201', 'short keeps hex for an IPv4-mapped address' );

done_testing;
