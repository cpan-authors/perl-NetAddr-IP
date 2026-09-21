#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $ip  = NetAddr::IP::Lite->new6FFFF('127.0.0.1');
my $exp = '0:0:0:0:0:FFFF:7F00:1/128';

is("$ip", $exp, 'new6FFFF returns expected IPv4 mapped address');

ok(!defined NetAddr::IP::Lite->new6FFFF(undef), 'new6FFFF(undef) returns undef');
ok(!defined NetAddr::IP::Lite->new6FFFF(''),    "new6FFFF('') returns undef");
ok(!defined NetAddr::IP::Lite->new6FFFF('10.0.0.a'), "new6FFFF('10.0.0.a') returns undef");

done_testing;
