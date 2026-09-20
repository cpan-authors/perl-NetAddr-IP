#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $net4 = NetAddr::IP::Lite->new('192.0.2.5/30');
my $net6 = NetAddr::IP::Lite->new('FF::85/126');
my %try  = (
    '192.0.2.3' => 0,
    '192.0.2.4' => 1,
    '192.0.2.5' => 1,
    '192.0.2.6' => 1,
    '192.0.2.7' => 1,
    '192.0.2.8' => 0,
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

# cross family: never contained, non object: undef

my $rv;
$rv = NetAddr::IP::Lite->new6('2001:db8::192.0.2.5')->within($net4);
is("$rv", '0', 'v6 within v4 is 0');
$rv = NetAddr::IP::Lite->new('::ffff:192.0.2.5')->within($net4);
is("$rv", '0', 'mapped v6 within v4 is 0');
$rv = NetAddr::IP::Lite->new('192.0.2.5')->within(NetAddr::IP::Lite->new6('2001:db8::192.0.2.5/126'));
is("$rv", '0', 'v4 within v6 is 0');
$rv = eval { $net4->within('192.0.2.5') };
ok(!defined $rv && $@ eq '', 'non object returns undef');

done_testing;
