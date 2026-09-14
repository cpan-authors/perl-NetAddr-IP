#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $net4 = NetAddr::IP::Lite->new('1.2.3.5/30');
my $net6 = NetAddr::IP::Lite->new('FF::85/126');
my %try  = (
    '1.2.3.3' => 0,
    '1.2.3.4' => 1,
    '1.2.3.5' => 1,
    '1.2.3.6' => 1,
    '1.2.3.7' => 1,
    '1.2.3.8' => 0,
    'FF::83'  => 0,
    'FF::84'  => 1,
    'FF::85'  => 1,
    'FF::86'  => 1,
    'FF::87'  => 1,
    'FF::88'  => 0,
);

for my $input (sort keys %try) {
    my $ip = NetAddr::IP::Lite->new($input);
    my $rv = ($input =~ /:/)
        ? $ip->within($net6)
        : $ip->within($net4);
    cmp_ok($rv, '==', $try{$input}, "$input within result is $try{$input}");
}

done_testing;
