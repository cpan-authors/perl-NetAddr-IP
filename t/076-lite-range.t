#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Util ();
use NetAddr::IP::Lite ();

my $loip = NetAddr::IP::Lite->new('192.0.2.4/24');
my $hiip = NetAddr::IP::Lite->new('FF00::4/120');

my $exp = 'FF00:0:0:0:0:0:0:0 - FF00:0:0:0:0:0:0:FF';
my $txt = $hiip->range;
is($txt, $exp, 'FF00::4/120 range');

$exp = '192.0.2.0 - 192.0.2.255';
$txt = $loip->range;
is($txt, $exp, '192.0.2.4/24 range');

done_testing;
