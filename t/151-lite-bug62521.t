#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $exp = '0:0:0:0:0:0:7F00:0/104';

my $ip = NetAddr::IP::Lite->new6('127.0.0.0/8');
is("$ip", $exp, 'new6 127.0.0.0/8');

$ip = NetAddr::IP::Lite->new6('127.0/8');
is("$ip", $exp, 'a call new6 of 127.0/8 keeps the dotted short form');

$ip = NetAddr::IP::Lite->new6('127/8');
is("$ip", '0:0:0:0:0:0:0:7F/8', 'a call new6 reads 127/8 as the number 127');

done_testing;
