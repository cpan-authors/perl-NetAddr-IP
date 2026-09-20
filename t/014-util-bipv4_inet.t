#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::InetBase qw( inet_aton inet_ntoa );

my @addrs = qw(
    0.0.0.0
    255.255.255.255
    192.0.2.4
    192.0.2.5
);

for my $addr (@addrs) {
    my @digs   = split(/\./, $addr);
    my $pkd    = pack('C4', @digs);
    my $naddr  = inet_aton($addr);
    my $packed = join('.', unpack('C4', $naddr));
    my $num    = inet_ntoa($pkd);

    ok($naddr eq $pkd, 'pack/unpack bits match for ' . $addr);
    is($packed, $addr, 'inet_aton roundtrip for ' . $addr);
    is($num,    $addr, 'inet_ntoa roundtrip for ' . $addr);
}

done_testing;
