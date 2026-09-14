#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $loip = NetAddr::IP::Lite->new('::1.2.3.4/120');
my $hiip = NetAddr::IP::Lite->new('FF00::1:4/120');

## test '""' just for the heck of it
my $exp = 'FF00:0:0:0:0:0:1:4/120';
is("$hiip", $exp, 'stringify hiip');

## test addr lo
$exp = '0:0:0:0:0:0:102:304';
my $addr = $loip->addr;
is($addr, $exp, 'addr lo');
ok(!ref $addr, 'addr lo is not a reference');

## test addr hi
$exp = 'FF00:0:0:0:0:0:1:4';
$addr = $hiip->addr;
is($addr, $exp, 'addr hi');
ok(!ref $addr, 'addr hi is not a reference');

done_testing;
