#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my @addr = (
    [ '::',                  3,     '0:0:0:0:0:0:0:0/128',        0 ],
    [ '::1',                 3,     '0:0:0:0:0:0:0:1/128',        0 ],
    [ 'F34::123/40',         2,     'F34:0:0:0:0:0:0:3/40',       1 ],
    [ 'DEAD:BEEF::1/40',     2,     'DEAD:BEEF:0:0:0:0:0:3/40',   1 ],
    [ '1000::2/40',          0,     '1000:0:0:0:0:0:0:1/40',      1 ],
    [ '1000::2000/40',       0,     '1000:0:0:0:0:0:0:1/40',      1 ],
    [ 'DEAD::CAFE/40',       0,     'DEAD:0:0:0:0:0:0:1/40',      1 ],
    [ 'DEAD:BEEF::1/40',     3,     'DEAD:BEEF:0:0:0:0:0:4/40',   1 ],
    [ 'DEAD:BEEF::1/40',     4,     'DEAD:BEEF:0:0:0:0:0:5/40',   1 ],
    [ 'DEAD:BEEF::1/40',     5,     'DEAD:BEEF:0:0:0:0:0:6/40',   1 ],
    [ 'DEAD:BEEF::1/40',     6,     'DEAD:BEEF:0:0:0:0:0:7/40',   1 ],
    [ 'DEAD:BEEF::1/40',     7,     'DEAD:BEEF:0:0:0:0:0:8/40',   1 ],
    [ 'DEAD:BEEF::1/40',     8,     'DEAD:BEEF:0:0:0:0:0:9/40',   1 ],
    [ 'DEAD:BEEF::1/40',     254,   'DEAD:BEEF:0:0:0:0:0:FF/40',  1 ],
    [ 'DEAD:BEEF::1/40',     255,   'DEAD:BEEF:0:0:0:0:0:100/40', 1 ],
    [ 'DEAD:BEEF::1/40',     256,   'DEAD:BEEF:0:0:0:0:0:101/40', 1 ],
    [ 'DEAD:BEEF::1/40',     65535, 'DEAD:BEEF:0:0:0:0:1:0/40',   1 ],
    [ 'DEAD:BEEF::1/40',     65536, 'DEAD:BEEF:0:0:0:0:1:1/40',   1 ],
    [ '2001:620:0:4::/64',   0,     '2001:620:0:4:0:0:0:1/64',    1 ],
    [ '3FFE:2000:0:4::/64',  0,     '3FFE:2000:0:4:0:0:0:1/64',   1 ],
    [ '2001:620:600::1',     0,     '2001:620:600:0:0:0:0:1/128', 1 ],
    [ '2001:620:600:0:1::1', 0,     '2001:620:600:0:1:0:0:1/128', 1 ],
);

subtest 'basic v6 functionality' => sub {
    for my $entry (@addr) {
        my $ip = NetAddr::IP::Lite->new( $entry->[0] );
        ( my $short = $entry->[0] ) =~ s,/\d+,,;
        isa_ok( $ip, ['NetAddr::IP::Lite'], "$short " );
        is( $ip->bits,    128, 'bits == 128' );
        is( $ip->version, 6,   'version == 6' );
        my $index = $entry->[1];
        if ( $entry->[3] ) {
            is( uc $ip->nth($index), $entry->[2], "nth $short, $index" );
        }
        else {
            ok( !$ip->nth($index), "nth $short, undef" );
        }
    }
};

my $test = NetAddr::IP::Lite->new('f34::1');
isa_ok( $test, 'NetAddr::IP::Lite' );
ok( $test->network->contains($test), '->contains' );

$test = NetAddr::IP::Lite->new('f35::1/40');
isa_ok( $test, 'NetAddr::IP::Lite' );
ok( $test->network->contains($test), '->contains' );

subtest 'a keyword with the ipv6 mask gives the IPv6 address' => sub {
    my %ipv6 = (
        any         => '0:0:0:0:0:0:0:0/0',
        default     => '0:0:0:0:0:0:0:0/0',
        loopback    => '0:0:0:0:0:0:0:1/128',
        unspecified => '0:0:0:0:0:0:0:0/128',
    );
    for my $keyword ( sort keys %ipv6 ) {
        my $ip = NetAddr::IP::Lite->new( $keyword, 'ipv6' );
        is( $ip->version, 6, "$keyword with the ipv6 mask is an IPv6 object" );
        is( "$ip", $ipv6{$keyword},
            "$keyword with the ipv6 mask is $ipv6{$keyword}" );
        is(
            "$ip",
            '' . NetAddr::IP::Lite->new6($keyword),
            "$keyword with the ipv6 mask matches new6"
        );
    }

    my $upper = NetAddr::IP::Lite->new( 'loopback', 'IPv6' );
    is( "$upper",        '0:0:0:0:0:0:0:1/128', 'the ipv6 mask is case blind' );
    is( $upper->version, 6, 'loopback with an IPv6 mask is an IPv6 object' );

    my $no_octal = NetAddr::IP::Lite->new_no( 'loopback', 'ipv6' );
    is( "$no_octal", '0:0:0:0:0:0:0:1/128',
        'new_no takes the ipv6 mask the same way' );

    is( NetAddr::IP::Lite->new('loopback')->cidr,
        '127.0.0.1/8', 'loopback with no mask is still IPv4' );
    is( NetAddr::IP::Lite->new( 'broadcast', 'ipv6' ),
        undef, 'broadcast has no IPv6 form' );
};

done_testing;
