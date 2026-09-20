#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP ();

my %cases = (
    '127.1'                                    => '127.0.0.1',
    'DEAD:BEEF::1'                             => 'dead:beef::1',
    '1234:5678:90AB:CDEF:0123:4567:890A:BCDE'  =>
        '1234:5678:90ab:cdef:123:4567:890a:bcde',
);

for my $c (sort keys %cases) {
    my $ip = NetAddr::IP->new($c);
    my $rv = $ip->canon;
    is($rv, $cases{$c}, "canon($c ) returns $rv");
}

done_testing;
