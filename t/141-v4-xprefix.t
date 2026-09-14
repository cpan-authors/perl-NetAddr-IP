#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP ();

my %addr = (
    '0.0.0.0/1'     => '0-127',
    '128.0.0.0/1'   => '128-255',
    '0.0.0.0/2'     => '0-63',
    '128.0.0.0/2'   => '128-191',
    '10.128.0.0/17' => '10.128.0-127.',
);

for my $input (sort keys %addr) {
    my $ip = NetAddr::IP->new($input);

    is($ip->prefix, $addr{$input}, "$input prefix is $addr{$input}");

    my $p = NetAddr::IP->new($ip->prefix);

    is($p->cidr, $input, "$ip prefix roundtrips to $input");
}

done_testing;
