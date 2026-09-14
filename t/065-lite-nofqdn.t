#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Require::Internet;

use NetAddr::IP::Lite ();

my $skip;

subtest 'DNS resolution check' => sub {
    my $ip = NetAddr::IP::Lite->new('arin.net');
    if (defined $ip) {
        pass("resolved $ip");
    }
    else {
        pass('resolver not working');
    }
    $skip = !defined $ip;
};

if (!$skip) {
    import NetAddr::IP::Lite qw(:nofqdn);

    my $ip = NetAddr::IP::Lite->new('arin.net');
    ok(!defined $ip, 'unexpected response with :nofqdn');
}

done_testing;
