#!/usr/bin/env perl

use Test2::V1 -ipP;
use Config;

use NetAddr::IP::InetBase qw( AF_INET AF_INET6 fake_AF_INET6 );

is(AF_INET(), 2, 'AF_INET is 2');

my $fake      = fake_AF_INET6();
my $af_inet6  = AF_INET6();
my $af_info   = $fake
    ? "Socket does not have AF_INET6, Socket6 not present; guessed AF_INET6 for $Config{osname} = $fake"
    : "AF_INET6 = $af_inet6 derived from Socket or Socket6";
note($af_info);

ok(defined $af_inet6, 'AF_INET6 is defined');

done_testing;
