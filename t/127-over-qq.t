#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP ();

my %addr = (
    '10.0.0.0/8'     => '10.0.0.0/8',
    '192.168.0.0/16' => '192.168.0.0/16',
    '127.0.0.1/32'   => '127.0.0.1/32',
);

for my $a (sort keys %addr) {
    my $ip = NetAddr::IP->new($a);

    cmp_ok("$ip", 'eq', $a,   "stringify eq address ($a)");
    cmp_ok($ip,   'eq', $a,   "eq address ($a)");
    cmp_ok($a,    'eq', $ip,  "address eq ip ($a)");
    cmp_ok($ip,   'eq', $ip,  "ip eq ip ($a)");
    cmp_ok($ip,   '==', $ip,  "ip num eq ip num ($a)");
}

done_testing;
