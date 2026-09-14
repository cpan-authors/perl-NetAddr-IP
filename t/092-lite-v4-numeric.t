#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my %nets = (
    '10.0.0.0/20'      => [167772160,  4294963200],
    '10.0.15.0/24'     => [167776000,  4294967040],
    '192.168.0.0/24'   => [3232235520, 4294967040],
    'broadcast'        => [4294967295, 4294967295],
    'default'          => [0,          0],
);

for my $cidr (keys %nets) {
    my $ip = NetAddr::IP::Lite->new($cidr);
    my ($addr, $mask) = $ip->numeric;

    my $nip = NetAddr::IP::Lite->new($addr, $mask);

    ok($nip, 'new from numeric returned truthy');

    ok($nip && $nip->cidr eq $ip->cidr, 'round-trip cidr matches');

    is($addr, $nets{$cidr}->[0], 'numeric address matches');

    is($mask, $nets{$cidr}->[1], 'numeric mask matches');
}

done_testing;
