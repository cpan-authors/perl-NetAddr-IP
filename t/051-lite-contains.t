#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $net4 = NetAddr::IP::Lite->new('192.0.2.5/30');
my $net6 = NetAddr::IP::Lite->new('FF::85/126');

my %try = (
    '192.0.2.3' => 0,
    '192.0.2.4' => 1,
    '192.0.2.5' => 1,
    '192.0.2.6' => 1,
    '192.0.2.7' => 1,
    '192.0.2.8' => 0,
    'FF::83'     => 0,
    'FF::84'     => 1,
    'FF::85'     => 1,
    'FF::86'     => 1,
    'FF::87'     => 1,
    'FF::88'     => 0,
);

for my $input (sort keys %try) {
    my $ip = NetAddr::IP::Lite->new($input);
    my $rv = ($input =~ /:/)
        ? $net6->contains($ip)
        : $net4->contains($ip);
    cmp_ok($rv, '==', $try{$input}, "contains $input");
}

# cross family: never contained, non object: undef

my $rv;
$rv = $net4->contains(NetAddr::IP::Lite->new6('2001:db8::192.0.2.5'));
is("$rv", '0', 'v4 contains v6 is 0');
$rv = $net4->contains(NetAddr::IP::Lite->new('::ffff:192.0.2.5'));
is("$rv", '0', 'v4 contains mapped v6 is 0');
$rv = NetAddr::IP::Lite->new6('2001:db8::192.0.2.5/126')->contains(NetAddr::IP::Lite->new('192.0.2.5'));
is("$rv", '0', 'v6 contains v4 is 0');
$rv = eval { $net4->contains('192.0.2.5') };
ok(!defined $rv && $@ eq '', 'non object returns undef');

done_testing;
