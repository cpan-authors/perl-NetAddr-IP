#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP ();

my %addr = (
    '192.0.2.0' => [
        '255.255.255.252',
        ['192.0.2.1', '192.0.2.2'],
    ],
    '192.0.2.4' => [
        '255.255.255.255',
        ['192.0.2.4'],
    ],
    '192.0.2.8' => [
        '255.255.255.248',
        ['192.0.2.9', '192.0.2.10', '192.0.2.11',
         '192.0.2.12', '192.0.2.13', '192.0.2.14'],
    ],
);

for my $input (sort keys %addr) {
    my $ip = NetAddr::IP->new($input, $addr{$input}->[0]);
    my @r   = $ip->hostenum;
    my @m;

    is(
        scalar @r,
        scalar @{ $addr{$input}->[1] },
        "hostenum count for $input",
    );

    for my $r (@r) {
        push @m, grep { $_ eq $r->addr } @{ $addr{$input}->[1] };
    }

    is(
        scalar @m,
        scalar @r,
        "hostenum match for $input",
    );
}

done_testing;
