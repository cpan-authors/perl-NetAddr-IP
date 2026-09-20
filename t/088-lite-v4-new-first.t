#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %nets = (
    '10.0.0.16'  => [ 24, '10.0.0.1',   '10.0.0.254',   '10.0.0.11' ],
    '10.0.0.5'   => [ 30, '10.0.0.5',   '10.0.0.6',     'undef' ],
    '10.128.0.1' => [ 24, '10.128.0.1', '10.128.0.254', '10.128.0.11' ],
);

for my $key (keys %nets) {
    my $ip = NetAddr::IP::Lite->new($key, $nets{$key}->[0]);
    is($ip->first->addr, $nets{$key}->[1], "$key first");
    is($ip->last->addr,  $nets{$key}->[2], "$key last");

    my $new = $ip->nth(10);
    is(defined $new ? $new->addr : 'undef', $nets{$key}->[3], "$key nth(10)");
}

done_testing;
