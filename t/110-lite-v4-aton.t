#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Warnings qw(warning);

use NetAddr::IP::Lite ();

my %addr = (
    'localhost'   => '127.0.0.1',
    'broadcast'   => '255.255.255.255',
    '254.254.0.1' => '254.254.0.1',
    'default'     => '0.0.0.0',
    '10.0.0.1'    => '10.0.0.1',
);

my %packed = (
    'localhost'       => pack( 'N', 0x7f000001 ),
    'broadcast'       => pack( 'N', 0xffffffff ),
    '254.254.0.1'     => pack( 'N', 0xfefe0001 ),
    'default'         => pack( 'N', 0 ),
    '10.0.0.1'        => pack( 'N', 0x0a000001 ),
    '127.0.0.1'       => pack( 'N', 0x7f000001 ),
    '255.255.255.255' => pack( 'N', 0xffffffff ),
    '0.0.0.0'         => pack( 'N', 0 ),
);

sub l_inet_aton {
    my $rv = ( exists $packed{ $_[0] } ) ? $packed{ $_[0] } : undef;
}

my $x;

ok( !defined NetAddr::IP::Lite->new("\1\1\1\1"),
    "binary unrecognized by default " . ( $x ? $x->addr : '' ) );

like(
    warning { NetAddr::IP::Lite::import(':aton') },
    qr/:aton is deprecated/,
    ':aton is deprecated and warns on import'
);

ok( defined( $x = NetAddr::IP::Lite->new("\1\1\1\1") ),
    "...but can be recognized " . $x->addr );

ok( !defined( $x = NetAddr::IP::Lite->new('bad rfc-952 characters') ),
    "bad rfc-952 characters " . ( $x ? $x->addr : '' ) );

subtest "aton returns packed address" => sub {
    for my $name ( sort keys %addr ) {
        my $expected = $addr{$name};
        is( NetAddr::IP::Lite->new($name)->aton,
            l_inet_aton($expected), "->aton($name)" );
    }
};

subtest "new accepts aton packed address" => sub {
    for my $name ( sort keys %addr ) {
        my $expected = $addr{$name};
        ok( defined NetAddr::IP::Lite->new( l_inet_aton($expected) ),
            "->new aton($expected)" );
    }
};

subtest "new aton round-trips to expected address" => sub {
    for my $name ( sort keys %addr ) {
        my $expected = $addr{$name};
        is( NetAddr::IP::Lite->new( l_inet_aton($expected) )->addr,
            $expected, "->new aton($expected)" );
    }
};

subtest 'new aton keeps packed bytes 0x41 to 0x5A' => sub {

    # Each has a byte in 0x41 to 0x5A, ASCII A to Z, which lc would change
    my %in_range = (
        '192.0.2.65'              => pack( 'C4', 192, 0,  2,   65 ),
        '198.51.100.77'           => pack( 'C4', 198, 51, 100, 77 ),
        '203.0.113.90'            => pack( 'C4', 203, 0,  113, 90 ),
        '2001:DB8:0:0:0:0:0:4142' =>
          pack( 'n8', 0x2001, 0x0db8, 0, 0, 0, 0, 0, 0x4142 ),
        '2001:DB8:4142:4344:4546:4748:494A:4B5A' => pack( 'n8',
            0x2001, 0x0db8, 0x4142, 0x4344, 0x4546, 0x4748, 0x494a, 0x4b5a ),
    );
    for my $expected ( sort keys %in_range ) {
        my $packed = $in_range{$expected};
        my $ip     = NetAddr::IP::Lite->new($packed);
        is( defined $ip ? $ip->addr : undef,
            $expected, "->new packed $expected round-trips through ->addr" );
        is(
            defined $ip ? unpack( 'H*', $ip->aton ) : undef,
            unpack( 'H*', $packed ),
            "->new packed $expected round-trips through ->aton"
        );
    }
};

subtest 'new aton keeps a packed address made of bytes 0x41 to 0x5A' => sub {

    # Letters-only input is tried as a hostname first, so skip the lookup
    local $NetAddr::IP::Lite::NoFQDN = 1;

    # No documentation address has every byte in range, so this is 65.66.67.68
    my $ip = NetAddr::IP::Lite->new('ABCD');
    is( defined $ip ? $ip->addr : undef,
        '65.66.67.68', '->new packed ABCD round-trips through ->addr' );
    is( defined $ip ? $ip->aton : undef,
        'ABCD', '->new packed ABCD round-trips through ->aton' );
};

subtest 'new aton still parses text addresses in either case' => sub {
    my %text = (
        '192.0.2.65'     => '192.0.2.65',
        '2001:DB8::4142' => '2001:DB8:0:0:0:0:0:4142',
        '2001:db8::4142' => '2001:DB8:0:0:0:0:0:4142',
        '2001:db8::abcd' => '2001:DB8:0:0:0:0:0:ABCD',
    );
    for my $input ( sort keys %text ) {
        my $ip = NetAddr::IP::Lite->new($input);
        is( defined $ip ? $ip->addr : undef,
            $text{$input}, "->new text $input parses as $text{$input}" );
    }
};

done_testing;
