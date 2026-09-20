#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite qw(:old_nth);

my %try = (
    '10/32'       => 0,
    '10/31'       => 1,
    '10/30'       => 3,
    '::1/128'     => 0,
    '::1/127'     => 1,
    '::1/126'     => 3,
    '1.2.3.11/29' => 7,
    'FF::8B/125'  => 7,
);

for my $input (sort keys %try) {
    my $ip  = NetAddr::IP::Lite->new($input);
    my $exp = $try{$input};

    is($ip->num, $exp, "$input num is $exp");
}

done_testing;
