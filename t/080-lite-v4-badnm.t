#!/usr/bin/env perl

use strict;
use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my @badnets = (
    '10.10.10.10/255.255.0.255',
    '10.10.10.10/255.0.255.255',
    '10.10.10.10/0.255.255.255',
    '10.10.10.10/128.255.0.255',
    '10.10.10.10/255.128.0.255',
    '10.10.10.10/255.255.255.129',
    '10.10.10.10/255.255.129.0',
    '10.10.10.10/255.255.255.130',
    '10.10.10.10/255.255.130.0',
    '10.10.10.10/255.0.0.1',
    '10.10.10.10/255.129.0.1',
    '10.10.10.10/0.255.0.255',
    '58.26.0.0-58.27.127.255',    # Taken from APNIC's WHOIS case
);

my @goodnets = ();
push @goodnets, "10.0.0.1/$_" for (0 .. 32);
push @goodnets, '10.0.0.1/255.255.255.255';

subtest 'bad nets' => sub {
    ok(!defined NetAddr::IP::Lite->new($_), "new $_ should fail")
        for @badnets;
};

subtest 'good nets' => sub {
    ok(defined NetAddr::IP::Lite->new($_), "new $_ should work")
        for @goodnets;
};

done_testing;
