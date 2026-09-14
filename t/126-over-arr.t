#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP ();

my $addr = {
    '10.0.0.0/24'    => '10.0.0.1/32',
    '192.168.0.0/24' => '192.168.0.1/32',
    '127.0.0.1/32'   => '127.0.0.1/32',
};

SKIP: {
    skip "overload dereferencing not supported in version $] of Perl", scalar keys %$addr
        unless $overload::ops{dereferencing} && $overload::ops{dereferencing} =~ m/\@\{\}/;

    for my $input (sort keys %$addr) {
        my $ip = NetAddr::IP->new($input);
        ok(@$ip[0]->cidr eq $addr->{$input}, $input);
    }
}

done_testing;
