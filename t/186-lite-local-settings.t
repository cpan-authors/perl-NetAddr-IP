#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $ip = NetAddr::IP::Lite->new('2001:db8::ab');

subtest 'local scopes the IPv6 case' => sub {
    is( $ip->addr, '2001:DB8:0:0:0:0:0:AB', 'uppercase by default' );
    {
        local $NetAddr::IP::InetBase::Upper = 0;
        is( $ip->addr, '2001:db8:0:0:0:0:0:ab', 'lowercase inside the block' );
    }
    is( $ip->addr, '2001:DB8:0:0:0:0:0:AB', 'uppercase again after the block' );
};

subtest 'local scopes name lookup' => sub {
    my $addr = NetAddr::IP::Lite->new('192.0.2.1');
    {
        local $NetAddr::IP::Lite::NoFQDN = 1;
        is( NetAddr::IP::Lite->new('192.0.2.1')->addr,
            $addr->addr, 'an address is still an address' );
        ok( !defined NetAddr::IP::Lite->new('not.a.real.host.example'),
            'a name is not resolved inside the block' );
    }
    ok( !$NetAddr::IP::Lite::NoFQDN,
        'name lookup is on again after the block' );
};

subtest 'local scopes the old nth behaviour' => sub {
    my $net = NetAddr::IP::Lite->new('192.0.2.0/30');
    is( $net->nth(0)->addr, '192.0.2.1', 'nth(0) is the first host' );
    {
        local $NetAddr::IP::Lite::Old_nth = 1;
        ok( !defined $net->nth(0), 'nth(0) is undef inside the block' );
    }
    is( $net->nth(0)->addr, '192.0.2.1', 'nth(0) is the first host again' );
};

done_testing;
