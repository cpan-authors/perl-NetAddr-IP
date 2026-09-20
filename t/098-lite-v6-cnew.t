#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %subnets = (
    'dead:beef:1234::/16'           => 'DEAD:BEEF:1234:0:0:0:0:0/16',
    '::1234:BEEF:DEAD/24'           => '0:0:0:0:0:1234:BEEF:DEAD/24',
    'dead:beef:1234:: 16'           => 'DEAD:BEEF:1234:0:0:0:0:0/16',
    '::1234:BEEF:DEAD 24'           => '0:0:0:0:0:1234:BEEF:DEAD/24',
    '::1234:BEEF:DEAD FFFF:FF00::'  => '0:0:0:0:0:1234:BEEF:DEAD/24',
);

for my $input (sort keys %subnets) {
    my $ip = NetAddr::IP::Lite->new($input);
    is("$ip", $subnets{$input}, "$input parses correctly");
}

done_testing;
