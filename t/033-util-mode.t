#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Util qw( mode );

my $mode = mode();
note("\tmode $mode");
pass('mode returned successfully');

done_testing;
