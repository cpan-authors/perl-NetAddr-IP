#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $loip = NetAddr::IP::Lite->new('::1.2.3.4/120');
my $hiip = NetAddr::IP::Lite->new('FF00::1:4/120');
my $dqip = NetAddr::IP::Lite->new('192.0.2.4/24');

is($loip->masklen, 120, 'masklen lo');
is($hiip->masklen, 120, 'masklen hi');
is($dqip->masklen, 24,  'masklen dq');

done_testing;
