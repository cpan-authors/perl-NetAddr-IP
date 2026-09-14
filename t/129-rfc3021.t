#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP ();

my $ip = NetAddr::IP->new('192.0.2.8/31');
my @hosts = $ip->hostenum;

is(scalar @hosts, 0, 'no hosts before :rfc3021 import');

NetAddr::IP::import(qw(:rfc3021));

@hosts = $ip->hostenum;

is(scalar @hosts, 2, '2 hosts after :rfc3021 import');

is("$hosts[0]", '192.0.2.8/32', 'first host is 192.0.2.8/32');
is("$hosts[1]", '192.0.2.9/32', 'second host is 192.0.2.9/32');

done_testing;
