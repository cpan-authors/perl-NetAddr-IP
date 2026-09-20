#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::InetBase qw( AF_INET AF_INET6 inet_ntop inet_pton );

subtest 'inet_pton and inet_ntop IPv4' => sub {
    my @num = qw(
        0.0.0.0
        255.255.255.255
        1.2.3.4
        10.253.230.9
    );

    for my $input (@num) {
        my @digs  = split(/\./, $input);
        my $pkd   = pack('C4', @digs);
        my $naddr = inet_pton(AF_INET, $input);
        my $addr  = join('.', unpack('C4', $naddr));
        my $num   = inet_ntop(AF_INET, $pkd);

        ok($naddr eq $pkd, 'bits match for ' . $input);
        ok($addr eq $input, 'inet_pton: ' . $addr . ' eq ' . $input);
        ok($num eq $input, 'inet_ntop: ' . $num . ' eq ' . $input);
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
        is($len, 16, "length($input) == 16");
        my $ipv6x = inet_ntop(AF_INET6, $bits);
        is($ipv6x, $num{$input}, "inet_ntop(inet_pton($input))");
    }
};

like(dies { inet_ntop(AF_INET6, '1234') }, qr/Bad arg/, 'bad argument length test for inet_ntop');

done_testing;
