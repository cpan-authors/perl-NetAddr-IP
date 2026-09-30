#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Lite ();

my $ip  = NetAddr::IP::Lite->new('0.0.0.4/24');
my $nip;

## test '+' and '-' reject a constant that is not a number
for my $bad ('x', '-x', '--7', '5abc', '0x10', '0b11') {
    like(
        dies { my $sum = $ip + $bad },
        qr/constant must be an exact integer/,
        "addition croaks on '$bad'",
    );
    like(
        dies { my $dif = $ip - $bad },
        qr/constant must be an exact integer/,
        "subtraction croaks on '$bad'",
    );
}

## test '+' and '-' accept a string that is a number
is($ip + ' 7', '0.0.0.11/24', 'addition accepts a padded numeric string');
is($ip - '1e1', '0.0.0.250/24', 'subtraction accepts an exponent string');

## a missing or zero constant returns a copy, as the POD promises, for
## both operators and for undef as well as the empty string
for my $missing (undef, '', 0, '0') {
    my $label = defined $missing ? "'$missing'" : 'undef';
    is($ip + $missing, '0.0.0.4/24', "addition returns a copy for $label");
    is($ip - $missing, '0.0.0.4/24', "subtraction returns a copy for $label");
}

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
