#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP ();

my %addr = (
    '10.'         => '10.0.0.0/8',
    '11.11.'      => '11.11.0.0/16',
    '12.12.12.'   => '12.12.12.0/24',
    '13.13.13.13' => '13.13.13.13/32',
);

for my $prefix (sort keys %addr) {
    my $ip = NetAddr::IP->new($prefix);

    is($ip->cidr, $addr{$prefix}, 'cidr returns correct value');

    my $p = NetAddr::IP->new($ip->cidr);

    is($p->prefix, $prefix, 'prefix returns correct value');

    is($p->nprefix, $prefix, 'nprefix returns correct value');
}

done_testing;
