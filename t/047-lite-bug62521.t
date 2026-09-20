#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $exp = '0:0:0:0:0:0:7F00:0/104';

my $ip = NetAddr::IP::Lite->new6('127.0.0.0/8');
is("$ip", $exp, 'new6 127.0.0.0/8');

$ip = NetAddr::IP::Lite->new6('127/8');
is("$ip", $exp, 'new6 127/8');

done_testing;
