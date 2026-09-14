#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $loip = NetAddr::IP::Lite->new('192.0.2.4/24');
my $hiip = NetAddr::IP::Lite->new('FF00::1:4/120');

my $exp     = 4;
my $version = $loip->version;
is($version, $exp, 'version lo');

$exp     = 6;
$version = $hiip->version;
is($version, $exp, 'version hi');

done_testing;
