#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP qw(:lower);

my $exp = 'ff:0:0:0:0:0:0:eeaa/128';
my $ip  = NetAddr::IP->new('FF::eeAA');
my $got = sprintf $ip;
cmp_ok($got, 'eq', $exp, "lower case $got");

done_testing;
