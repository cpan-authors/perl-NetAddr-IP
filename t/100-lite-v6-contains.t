#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my %yes_pairs = (
    '::/0 vs 2001:620:0:4:a00:20ff:fe9c:7e4a'               => [ '::/0', '2001:620:0:4:a00:20ff:fe9c:7e4a' ],
    '3ffe:2000:0:4::/64 vs 3ffe:2000:0:4:a00:20ff:fe9c:7e4a' => [ '3ffe:2000:0:4::/64', '3ffe:2000:0:4:a00:20ff:fe9c:7e4a' ],
    '3ffe:2000:0:4::/64 vs 3ffe:2000:0:4:a00:20ff:fe9c:7e4a/65' => [ '3ffe:2000:0:4::/64', '3ffe:2000:0:4:a00:20ff:fe9c:7e4a/65' ],
    '2001:620:0:4::/64 vs 2001:620:0:4:a00:20ff:fe9c:7e4a'  => [ '2001:620:0:4::/64', '2001:620:0:4:a00:20ff:fe9c:7e4a' ],
    '2001:620:0:4::/64 vs 2001:620:0:4:a00:20ff:fe9c:7e4a/65' => [ '2001:620:0:4::/64', '2001:620:0:4:a00:20ff:fe9c:7e4a/65' ],
    '2001:620:0:4::/64 vs 2001:620:0:4::1'                   => [ '2001:620:0:4::/64', '2001:620:0:4::1' ],
    '2001:620:0:4::/64 vs 2001:620:0:4:0:0:0:1'              => [ '2001:620:0:4::/64', '2001:620:0:4:0:0:0:1' ],
    'deaf:beef::/32 vs deaf:beef::1'                          => [ 'deaf:beef::/32', 'deaf:beef::1' ],
    'deaf:beef::/32 vs deaf:beef::1:1'                        => [ 'deaf:beef::/32', 'deaf:beef::1:1' ],
    'deaf:beef::/32 vs deaf:beef::1:0:1'                      => [ 'deaf:beef::/32', 'deaf:beef::1:0:1' ],
    'deaf:beef::/32 vs deaf:beef::1:0:0:1'                    => [ 'deaf:beef::/32', 'deaf:beef::1:0:0:1' ],
    'deaf:beef::/32 vs deaf:beef::1:0:0:0:1'                  => [ 'deaf:beef::/32', 'deaf:beef::1:0:0:0:1' ],
);

ok(NetAddr::IP::Lite->new('::')->contains(NetAddr::IP::Lite->new('::')),
   ':: contains itself');

subtest 'contains and within pairs' => sub {
    for my $name (sort keys %yes_pairs) {
        my ($a_val, $b_val) = @{$yes_pairs{$name}};
        my $net = NetAddr::IP::Lite->new($a_val);
        my $host = NetAddr::IP::Lite->new($b_val);

        isa_ok($net, ['NetAddr::IP::Lite'], "$a_val");
        isa_ok($host, ['NetAddr::IP::Lite'], "$b_val");

        ok($net->contains($host), "->contains $a_val, $b_val is true");
        ok($host->within($net), "->within $b_val, $a_val is true");
        ok(!$host->contains($net), "->contains $b_val, $a_val is false");
        ok(!$net->within($host), "->within $a_val, $b_val is false");
    }
};

done_testing;
