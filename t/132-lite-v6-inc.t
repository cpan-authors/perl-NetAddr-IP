#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my @ip = (
    NetAddr::IP::Lite->new('2001:468:ff:fffe::2/64'),
    NetAddr::IP::Lite->new('2001:468:ff:fffe::2/64'),
    NetAddr::IP::Lite->new('2001:468:ff:fffe::2/64'),
);

$ip[1]++;
$ip[2]++;
$ip[2]++;

isa_ok($_, 'NetAddr::IP::Lite') for @ip;

diag "$ip[0] -- $ip[1]"
    unless ok($ip[0] != $ip[1], 'Auto incremented once differ');
diag "$ip[0] -- $ip[2]"
    unless ok($ip[0] != $ip[2], 'Auto incremented twice differ');
diag "$ip[1] -- $ip[2]"
    unless ok($ip[1] != $ip[2], 'Auto incremented two times differ');

is($ip[1], $ip[0] + 1, 'Test of first auto-increment');
is($ip[2], $ip[0] + 2, 'Test of second auto-increment');

$ip[1]--;
$ip[2]--;
$ip[2]--;

is($ip[0], $ip[1], 'Decrement of decrement once is ok');
is($ip[0], $ip[2], 'Decrement of decrement twice is ok');
is($ip[1], $ip[2], 'Third case');

done_testing;
