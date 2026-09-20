#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP ();

my %addr = (
    '192.0.2.10' => [
        '255.255.252.0', 24,
        ['192.0.0.0', '192.0.1.0', '192.0.2.0', '192.0.3.0'],
    ],
    '192.0.2.1' => [
        '255.255.255.254', 32,
        ['192.0.2.0', '192.0.2.1'],
    ],
    '192.0.2.2' => [
        '255.255.255.255', 32,
        ['192.0.2.2'],
    ],
    '192.0.2.3' => [
        '255.255.255.252', 32,
        ['192.0.2.0', '192.0.2.1', '192.0.2.2', '192.0.2.3'],
    ],
);

for my $input (sort keys %addr) {
    my $ip = NetAddr::IP->new($input, $addr{$input}->[0]);
    my @r = $ip->split($addr{$input}->[1]);
    my @m;

    is(
        scalar @r,
        scalar @{$addr{$input}->[2]},
        "number of splits for $input",
    );

    for my $r (@r) {
        push @m, grep { $_ eq $r->addr } @{$addr{$input}->[2]};
    }

    is(
        scalar @m,
        scalar @r,
        "match splits for $input",
    );
}

done_testing;
