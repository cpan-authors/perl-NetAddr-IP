#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $loip = NetAddr::IP::Lite->new('::1.2.3.4/120');   # same as 1.2.3.4/24
my $hiip = NetAddr::IP::Lite->new('FF00::1:4/120');
my $dqip = NetAddr::IP::Lite->new('192.0.2.4/24');

## test '""' just for the heck of it
my $exp = 'FF00:0:0:0:0:0:1:4/120';
my $txt = sprintf('%s', $hiip);
is($txt, $exp, 'stringify hiip');

## test network dq
$exp = '192.0.2.0/24';
my $net = $dqip->network;
is($net, $exp, 'network dq');

## test network hi
$exp = 'FF00:0:0:0:0:0:1:0/120';
$net = $hiip->network;
is($net, $exp, 'network hi');

## test network lo
$exp = '0:0:0:0:0:0:102:300/120';
$net = $loip->network;
is($net, $exp, 'network lo');

done_testing;
