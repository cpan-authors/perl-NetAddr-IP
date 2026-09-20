#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite qw(:old_nth);

my $ip4 = NetAddr::IP::Lite->new('192.0.2.11/29');

my %try = (
    '0' => undef,
    '1' => '192.0.2.9',
    '2' => '192.0.2.10',
    '3' => '192.0.2.11',
    '4' => '192.0.2.12',
    '5' => '192.0.2.13',
    '6' => '192.0.2.14',
    '7' => '192.0.2.15',
    '8' => undef,
);

for my $input (sort { $a <=> $b } keys %try) {
    my $rv  = $ip4->nth($input);
    my $got = defined $rv ? $rv->addr : 'undef';
    is($got, $try{$input} // 'undef', "nth($input) returns " . ($try{$input} // 'undef'));
}

done_testing;
