#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP ();

my $ip = NetAddr::IP->new('ffff:a123:b345:c789::/48');
my $rv;

subtest 'splitref with same cidr' => sub {
    ok(($rv = sprintf('%s', $ip)) eq 'FFFF:A123:B345:C789:0:0:0:0/48', "$rv eq FFFF:A123:B345:C789:0:0:0:0/48");
    my $nets = $ip->splitref(48);
    ok($nets,         'there is a net');
    ok(@$nets == 1,   'one item net');
    ok(($rv = sprintf('%s', $ip)) eq 'FFFF:A123:B345:C789:0:0:0:0/48', "$rv eq FFFF:A123:B345:C789:0:0:0:0/48");
};

subtest 'splitref with multiple cidrs' => sub {
    my $nets = $ip->splitref(49, 50);
    ok($nets,                'there are nets');
    ok(($rv = @$nets) == 3,  "$rv is 3 item net");

    my @exp = qw(
        FFFF:A123:B345:0:0:0:0:0/49
        FFFF:A123:B345:8000:0:0:0:0/50
        FFFF:A123:B345:C000:0:0:0:0/50
    );

    for my $i (0 .. $#$nets) {
        ok(($rv = sprintf('%s', $nets->[$i])) eq $exp[$i], "$rv eq $exp[$i]");
    }
};

done_testing;
