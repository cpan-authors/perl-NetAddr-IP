#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %try = (
    '10/32'       => 1,
    '10/31'       => 2,
    '10/30'       => 2,
    '::1/128'     => 1,
    '::1/127'     => 2,
    '::1/126'     => 2,
    '1.2.3.11/29' => 6,
    'FF::8B/125'  => 6,
);

for my $input (sort keys %try) {
    my $ip = NetAddr::IP::Lite->new($input);
    my $exp = $try{$input};

    is($ip->num, $exp, "$input has num $exp");
}

done_testing;
