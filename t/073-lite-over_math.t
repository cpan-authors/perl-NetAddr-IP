#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $ip  = NetAddr::IP::Lite->new('0.0.0.4/24');
my $nip;

## test '+'
$nip = $ip + 128;
is("$nip", '0.0.0.132/24', 'addition');

## test '+' wrap around
$nip = $ip + 257;
is("$nip", '0.0.0.5/24', 'addition wrap around');

## test '-' and wrap
$nip = $ip - 10;
is("$nip", '0.0.0.250/24', 'subtraction and wrap');

## test '++' post
$nip++;
is("$nip", '0.0.0.251/24', 'post increment');

## test '++' pre
++$nip;
is("$nip", '0.0.0.252/24', 'pre increment');

## test '--' post
$ip--;
is("$ip", '0.0.0.3/24', 'post decrement');

## test '--' pre
--$ip;
is("$ip", '0.0.0.2/24', 'pre decrement');

done_testing;
