#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $loip = NetAddr::IP::Lite->new('::1.2.3.4/120');
my $hiip = NetAddr::IP::Lite->new('FF00::1:4/120');
my $dqip = NetAddr::IP::Lite->new('192.0.2.4/24');

is($loip->bits, 128, 'bits lo');
is($hiip->bits, 128, 'bits hi');
is($dqip->bits, 32,  'dotquad bits');

done_testing;
