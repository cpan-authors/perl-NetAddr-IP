#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Require::Internet;

use NetAddr::IP ();

subtest 'DNS resolution check' => sub {
    my $ip = NetAddr::IP->new('arin.net');
    my $ip2;
    if (defined $ip) {
        pass("resolved $ip");
        NetAddr::IP->import(':nofqdn');
        $ip2 = NetAddr::IP->new('arin.net');
    }
    else {
        pass('resolver not working');
        skip('resolver not working', 1);
    }

    ok(!defined $ip2, 'unexpected response with :nofqdn');
};

done_testing;
