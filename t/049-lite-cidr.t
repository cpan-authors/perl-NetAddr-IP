#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $loip = NetAddr::IP::Lite->new('::1.2.3.4/120');
my $hiip = NetAddr::IP::Lite->new('FF00::4/120');
my $dqip = NetAddr::IP::Lite->new('192.0.2.4/24');

## test cidr

is($hiip->cidr, 'FF00:0:0:0:0:0:0:4/120', 'hiip cidr');
is($loip->cidr, '0:0:0:0:0:0:102:304/120', 'loip cidr');
is($dqip->cidr, '192.0.2.4/24', 'dqip cidr');

done_testing;
