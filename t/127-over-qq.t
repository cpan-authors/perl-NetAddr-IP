#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP ();

my %addr = (
    '10.0.0.0/8'     => '10.0.0.0/8',
    '192.168.0.0/16' => '192.168.0.0/16',
    '127.0.0.1/32'   => '127.0.0.1/32',
);

for my $key (sort keys %addr) {
    my $ip = NetAddr::IP->new($key);

    cmp_ok("$ip", 'eq', $key,   "stringify eq address ($key)");
    cmp_ok($ip,   'eq', $key,   "eq address ($key)");
    cmp_ok($key,  'eq', $ip,    "address eq ip ($key)");
    cmp_ok($ip,   'eq', $ip,    "ip eq ip ($key)");
    cmp_ok($ip,   '==', $ip,    "ip num eq ip num ($key)");
}

done_testing;
