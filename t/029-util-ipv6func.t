#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Util qw( ipv6_aton ipv6_n2d ipv6_n2x );

subtest 'ipv6_n2x and ipv6_n2d' => sub {
    my @num = (
        '::',              '0:0:0:0:0:0:0:0',      '0:0:0:0:0:0:0.0.0.0',
        '43::',            '43:0:0:0:0:0:0:0',     '43:0:0:0:0:0:0.0.0.0',
        '::21',            '0:0:0:0:0:0:0:21',     '0:0:0:0:0:0:0.0.0.33',
        '::1:2:3:4:5:6:7', '0:1:2:3:4:5:6:7',      '0:1:2:3:4:5:0.6.0.7',
        '1:2:3:4:5:6:7::', '1:2:3:4:5:6:7:0',      '1:2:3:4:5:6:0.7.0.0',
        '1::8',            '1:0:0:0:0:0:0:8',      '1:0:0:0:0:0:0.0.0.8',
        'FF00::FFFF',      'FF00:0:0:0:0:0:0:FFFF','FF00:0:0:0:0:0:0.0.255.255',
        'FFFF::FFFF:FFFF', 'FFFF:0:0:0:0:0:FFFF:FFFF', 'FFFF:0:0:0:0:0:255.255.255.255',
    );

    for (my $i = 0; $i < @num; $i += 3) {
        my $bits = ipv6_aton($num[$i]);
        is(length($bits), 16, 'length is 16 bytes');
        my $ipv6x = ipv6_n2x($bits);
        is($ipv6x, $num[$i + 1], "ipv6_n2x of $num[$i]");
        my $ipv6d = ipv6_n2d($bits);
        is($ipv6d, $num[$i + 2], "ipv6_n2d of $num[$i]");
    }
};

like(dies { ipv6_n2x('1234') }, qr/Bad arg/, 'ipv6_n2x dies on bad length');
like(dies { ipv6_n2d('1234') }, qr/Bad arg/, 'ipv6_n2d dies on bad length');

done_testing;
