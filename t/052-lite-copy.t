#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite 0.10 qw( Ones );
*Ones = \&NetAddr::IP::Lite::Ones;
use NetAddr::IP::Util qw( shiftleft );

my $ip24 = '192.0.2.4/24';
my $o    = NetAddr::IP::Lite->new($ip24);
my $c    = $o->copy;

is("$o", $ip24, 'original matches expected');
is("$c", $ip24, 'copy matches expected');

my $ip28 = '192.0.2.4/28';
my $mask = shiftleft(Ones(), 32 - 28);

$c->{mask} = $mask;

is("$o", $ip24, 'original unchanged after copy mutation');
is("$c", $ip28, 'copy reflects mutation');

done_testing;
