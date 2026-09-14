#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my @addr = ('192.0.2.0/8', '192.0.2.1/16', '127.0.0.1/32');

subtest 'stringification and comparison' => sub {
    for my $a (@addr) {
        my $ip = NetAddr::IP::Lite->new($a);

        is("$ip",      $a, "stringified $a eq $a");
        is($ip,        $a, "stringify eq $a");
        is($ip,        $a, "stringify eq $a (reversed)");
        is($ip,        $ip, "self eq self");
        cmp_ok($ip, '==', $ip, "self numeric eq self");
    }
};

done_testing;
