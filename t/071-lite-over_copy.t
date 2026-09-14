#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite 0.10 qw( Ones );
use NetAddr::IP::Util qw( shiftleft );

*Ones = \&NetAddr::IP::Lite::Ones;

my $ip24 = '192.0.2.4/24';
my $o    = NetAddr::IP::Lite->new($ip24);
my $c    = $o;

my $txto = sprintf('%s', $o);
my $txtc = sprintf('%s', $c);

is($txto, $ip24, 'orig... validate original');
is($txtc, $ip24, 'copy... validate copy');

my $ip28 = '192.0.2.4/28';
my $mask = shiftleft(Ones(), 32 - 28);

$c->{mask} = $mask;
$txto = sprintf('%s', $o);
$txtc = sprintf('%s', $c);

is($txto, $ip28, 'orig... overload does not unlink originals');
is($txtc, $ip28, 'copy... overload does not unlink originals');

my $ip265 = '192.0.2.5/26';
my $ip285 = '192.0.2.5/28';
$mask = shiftleft(Ones(), 32 - 26);

$c++;
$txto = sprintf('%s', $o);
$txtc = sprintf('%s', $c);

is($txto, $ip28,  'orig... overload separates variables');
is($txtc, $ip285, 'copy... mutated copy');

$c->{mask} = $mask;
$txto = sprintf('%s', $o);
$txtc = sprintf('%s', $c);

is($txto, $ip28,  'orig... separation after copy mutation');
is($txtc, $ip265, 'copy... mutated copy after separation');

done_testing;
