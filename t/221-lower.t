#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP qw(:lower);

my $ip = NetAddr::IP->new('2001:DB8::AbCd');

subtest ':lower from NetAddr::IP' => sub {
    is( "$ip", '2001:db8:0:0:0:0:0:abcd/128',
        ':lower stringifies in lowercase' );
    is(
        $ip->full,
        '2001:0db8:0000:0000:0000:0000:0000:abcd',
        ':lower gives full() in lowercase'
    );
};

subtest 'one case setting across the modules' => sub {
    NetAddr::IP::Util::upper();
    is(
        $ip->full,
        '2001:0DB8:0000:0000:0000:0000:0000:ABCD',
        'upper() from NetAddr::IP::Util reaches full()'
    );
    NetAddr::IP::Lite->import(':lower');
    is(
        $ip->full6,
        '2001:0db8:0000:0000:0000:0000:0000:abcd',
        ':lower from NetAddr::IP::Lite reaches full6()'
    );
    ok( lives { NetAddr::IP::InetBase->import( ':upper', ':lower' ) },
        'NetAddr::IP::InetBase accepts :lower' )
      or note $@;
    is( "$ip", '2001:DB8:0:0:0:0:0:ABCD/128',
        ':upper wins over :lower in NetAddr::IP::InetBase' );
};

done_testing;
