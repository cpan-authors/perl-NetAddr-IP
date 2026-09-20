#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite qw(:lower);

my $exp = 'ff:0:0:0:0:0:0:eeaa/128';
my $ip  = NetAddr::IP::Lite->new('FF::eeAA');
my $got = sprintf $ip;

ok($got eq $exp, "lower case $got");

done_testing;
