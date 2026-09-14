#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my %subnets = (
    '127.1'                  => '127.0.0.1/32',
    '127.1/16'               => '127.1.0.0/16',
    '10.10.10'               => '10.10.0.10/32',
    '10.10.10/24'            => '10.10.10.0/24',
    # include test for cisco syntax using space instead of '/'
    '127.1 16'               => '127.1.0.0/16',
    '10.10.10 24'            => '10.10.10.0/24',
    '10.10.10 255.255.255.0' => '10.10.10.0/24',
);

for my $input (sort keys %subnets) {
    my $ip = NetAddr::IP::Lite->new($input);
    is("$ip", $subnets{$input}, "$input converts to $subnets{$input}");
}

done_testing;
