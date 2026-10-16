#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite qw(:lower);

my $ip = NetAddr::IP::Lite->new('2001:DB8::AbCd');
is( "$ip", '2001:db8:0:0:0:0:0:abcd/128',
    ':lower from NetAddr::IP::Lite stringifies in lowercase' );

done_testing;
