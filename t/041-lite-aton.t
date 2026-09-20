#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( inet_n2dx );
use NetAddr::IP::Lite ();

my $loip = NetAddr::IP::Lite->new('::1.2.3.4/120');
my $hiip = NetAddr::IP::Lite->new('FF00::4/120');

is(
    inet_n2dx($hiip->aton),
    'FF00:0:0:0:0:0:0:4',
    'FF00::4 aton'
);

is(
    inet_n2dx($loip->aton),
    '1.2.3.4',
    '::1.2.3.4/120 aton'
);

done_testing;
