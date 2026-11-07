#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use NetAddr::IP ();

my @addr = (
    [ '10.0.0.0', 20, 32, 4096 ],
    [ '10.0.0.0', 22, 32, 1024 ],
    [ '10.0.0.0', 22, 24, 4 ],
    [ '10.0.0.0', 22, 23, 2 ],
    [ '10.0.0.0', 24, 32, 256 ],
    [ '10.0.0.0', 19, 32, 8192 ],
    [ '10.0.0.0', 24, 24, 1 ],
    [ '10.0.0.0', 31, 32, 2 ],
);

for my $row (@addr) {
    my $ip = NetAddr::IP->new($row->[0], $row->[1]);
    my $r  = $ip->splitref($row->[2]);

    is(scalar @$r, $row->[3]);
}

done_testing;
