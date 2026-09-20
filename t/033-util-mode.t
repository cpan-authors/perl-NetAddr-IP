#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( mode );
use NetAddr::IP::Util_IS ();

my $mode = mode();
note("\tmode $mode");

if (NetAddr::IP::Util_IS->not_pure) {
    is($mode, 'CC XS', 'Makefile.PL chose XS and the XS object loaded');
}
else {
    is($mode, 'Pure Perl', 'Makefile.PL chose Pure Perl and Pure Perl loaded');
}

done_testing;
