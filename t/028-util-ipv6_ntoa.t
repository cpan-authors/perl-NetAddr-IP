#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Util qw( AF_INET6 inet_pton ipv6_ntoa );

subtest 'ipv6_ntoa' => sub {
    my %num = (
        '::'                                    => '::',
        '43::'                                  => '43::',
        '::21'                                  => '::21',
        '::1:2:3:4:5:6:7'                       => '0:1:2:3:4:5:6:7',
        '1:2:3:4:5:6:7::'                       => '1:2:3:4:5:6:7:0',
        '1::8'                                  => '1::8',
        'FF00::FFFF'                            => 'ff00::ffff',
        'FFFF::FFFF:FFFF'                       => 'ffff::ffff:ffff',
        'A1B2:C3D4:E5D6:F7E8:08F9:190A:1.2.3.4' => 'a1b2:c3d4:e5d6:f7e8:8f9:190a:102:304',
    );

    for my $input (sort keys %num) {
        my $bits = inet_pton(AF_INET6, $input);
        my $len  = length($bits);
        is($len, 16, 'inet_pton returns 16 bytes for ' . $input);
        my $ipv6x = ipv6_ntoa($bits);
        is($ipv6x, $num{$input}, 'ipv6_ntoa round-trips ' . $input);
    }
};

like(dies { ipv6_ntoa('1234') }, qr/Bad arg/, 'ipv6_ntoa dies on bad argument length');

done_testing;
