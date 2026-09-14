#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Util qw( inet_aton inet_ntoa );

my @num = qw(
    0.0.0.0
    255.255.255.255
    1.2.3.4
    10.253.230.9
);

for my $input (@num) {
    my @digs  = split(/\./, $input);
    my $pkd   = pack('C4', @digs);
    my $naddr = inet_aton($input);
    my $addr  = join('.', unpack('C4', $naddr));
    my $num   = inet_ntoa($pkd);

    ok($naddr eq $pkd, 'bits match');
    is($addr, $input, 'inet_aton returns correct address');
    is($num, $input, 'inet_ntoa returns correct address');
}

done_testing;
