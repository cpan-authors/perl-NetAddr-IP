#!/usr/bin/env perl

use strict;
use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my @badnets = (
    '10.10.10.10/255.255.0.255',
    '10.10.10.10/255.0.255.255',
    '10.10.10.10/0.255.255.255',
    '10.10.10.10/128.255.0.255',
    '10.10.10.10/255.128.0.255',
    '10.10.10.10/255.255.255.129',
    '10.10.10.10/255.255.129.0',
    '10.10.10.10/255.255.255.130',
    '10.10.10.10/255.255.130.0',
    '10.10.10.10/255.0.0.1',
    '10.10.10.10/255.129.0.1',
    '10.10.10.10/0.255.0.255',
    '58.26.0.0-58.27.127.255',    # Taken from APNIC's WHOIS case
);

my @goodnets = ();
push @goodnets, "10.0.0.1/$_" for ( 0 .. 32 );
push @goodnets, '10.0.0.1/255.255.255.255';

subtest 'bad nets' => sub {
    ok( !defined NetAddr::IP::Lite->new($_), "new $_ should fail" )
      for @badnets;
};

subtest 'good nets' => sub {
    ok( defined NetAddr::IP::Lite->new($_), "new $_ should work" )
      for @goodnets;
};

subtest 'an IPv6-form mask shorter than /96 is no IPv4 mask' => sub {
    for my $mask ( 'ffff::', '8000::', 'ffff:ffff:ffff:ffff:ffff:fffe::' ) {
        is( NetAddr::IP::Lite->new( '192.0.2.4', $mask ),
            undef, "new('192.0.2.4', '$mask')" );
        is( NetAddr::IP::Lite->new("192.0.2.4/$mask"),
            undef, "new('192.0.2.4/$mask')" );
        is( NetAddr::IP::Lite->new_no( '192.0.2.4', $mask ),
            undef, "new_no('192.0.2.4', '$mask')" );

        # new_cis is deprecated and warns on every call
        my $cis = do {
            no warnings 'deprecated';
            NetAddr::IP::Lite->new_cis("192.0.2.4 $mask");
        };
        is( $cis, undef, "new_cis('192.0.2.4 $mask')" );
    }
    is(
        NetAddr::IP::Lite->new( '192.0.2.4',
            'ffff:ffff:ffff:ffff:ffff:ffff::' )
          . '',
        '192.0.2.4/0',
        'ninety-six ones are an IPv4 /0'
    );
    is(
        NetAddr::IP::Lite->new( '192.0.2.4',
            'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00' )
          . '',
        '192.0.2.4/24',
        'an IPv6-form /120 is an IPv4 /24'
    );
    is( NetAddr::IP::Lite->new6( '192.0.2.4', 'ffff::' )->masklen,
        16, 'new6 keeps an IPv6 mask of any length' );
    is(
        NetAddr::IP::Lite->new( '2001:db8::1', 'ffff::' ) . '',
        '2001:DB8:0:0:0:0:0:1/16',
        'an IPv6 address keeps an IPv6 mask of any length'
    );
};

done_testing;
