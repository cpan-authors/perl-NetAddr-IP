#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP ();

for my $bits (8 .. 32) {
    my $large = NetAddr::IP->new('10.0.0.0/8');
    my $small = NetAddr::IP->new('10.0.0.0', $bits);

    my @c = NetAddr::IP::compact($large, $small);

    is(scalar @c, 1, "compact returns 1 element for bits=$bits");
    is($c[0]->cidr, '10.0.0.0/8', "cidr is 10.0.0.0/8 for bits=$bits");
}

done_testing;
