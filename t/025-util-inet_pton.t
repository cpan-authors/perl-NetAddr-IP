#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Util qw( AF_INET AF_INET6 inet_ntop inet_pton );

subtest 'inet_pton and inet_ntop IPv4' => sub {
    my @num = qw(
        0.0.0.0
        255.255.255.255
        1.2.3.4
        10.253.230.9
    );

    for my $addr (@num) {
        my @digs   = split(/\./, $addr);
        my $pkd    = pack('C4', @digs);
        my $naddr  = inet_pton(AF_INET, $addr);
        my $packed = join('.', unpack('C4', $naddr));
        my $num    = inet_ntop(AF_INET, $pkd);

        is($naddr, $pkd, "inet_pton packs $addr correctly");
        is($packed, $addr, "inet_pton roundtrip for $addr");
        is($num, $addr, "inet_ntop roundtrip for $addr");
    }
};

subtest 'inet_pton and inet_ntop IPv6' => sub {
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
        is($len, 16, "inet_pton returns 16 bytes for $input");
        my $ipv6x = inet_ntop(AF_INET6, $bits);
        is($ipv6x, $num{$input}, "inet_ntop roundtrip for $input");
    }
};

like(dies { inet_ntop(AF_INET6, '1234') }, qr/Bad arg/, 'inet_ntop dies on bad argument length');

done_testing;
