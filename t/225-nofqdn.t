#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Require::Internet;

use NetAddr::IP ();

subtest 'DNS resolution check' => sub {
    my $ip = NetAddr::IP->new('arin.net');
  SKIP: {
        skip( 'resolver cannot resolve arin.net', 1 ) unless defined $ip;
        NetAddr::IP->import(':nofqdn');
        is( NetAddr::IP->new('arin.net'),
            undef, 'arin.net, which resolves, is undef under :nofqdn' );
    }
};

done_testing;
