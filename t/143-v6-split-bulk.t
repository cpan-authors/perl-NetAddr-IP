#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP ();

my @addr = (
    [ 'dead:beef::1', 126, 127,  2 ],
    [ 'dead:beef::1', 127, 127,  1 ],
    [ 'dead:beef::1', 127, 128,  2 ],
    [ 'dead:beef::1', 128, 128,  1 ],
    [ 'dead:beef::1', 124, 128, 16 ],
    [ 'dead:beef::1', 124, 127,  8 ],
);

for my $row (@addr) {
    my $ip = NetAddr::IP->new($row->[0], $row->[1]);
    my $r  = $ip->splitref($row->[2]);
    is(@$r, $row->[3]);
}

done_testing;
