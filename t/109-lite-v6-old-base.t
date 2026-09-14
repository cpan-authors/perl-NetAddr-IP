#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite qw(:old_nth);

my @addr = (
    ['::',  3, '0:0:0:0:0:0:0:0/128', 0],
    ['::1', 3, '0:0:0:0:0:0:0:1/128', 0],
    ['F34::123/40', 3, 'F34:0:0:0:0:0:0:3/40', 1],
    ['DEAD:BEEF::1/40', 3, 'DEAD:BEEF:0:0:0:0:0:3/40', 1],
    ['1000::2/40', 1, '1000:0:0:0:0:0:0:1/40', 1],
    ['1000::2000/40', 1, '1000:0:0:0:0:0:0:1/40', 1],
    ['DEAD::CAFE/40', 1, 'DEAD:0:0:0:0:0:0:1/40', 1],
    ['DEAD:BEEF::1/40', 4, 'DEAD:BEEF:0:0:0:0:0:4/40', 1],
    ['DEAD:BEEF::1/40', 5, 'DEAD:BEEF:0:0:0:0:0:5/40', 1],
    ['DEAD:BEEF::1/40', 6, 'DEAD:BEEF:0:0:0:0:0:6/40', 1],
    ['DEAD:BEEF::1/40', 7, 'DEAD:BEEF:0:0:0:0:0:7/40', 1],
    ['DEAD:BEEF::1/40', 8, 'DEAD:BEEF:0:0:0:0:0:8/40', 1],
    ['DEAD:BEEF::1/40', 9, 'DEAD:BEEF:0:0:0:0:0:9/40', 1],
    ['DEAD:BEEF::1/40', 255, 'DEAD:BEEF:0:0:0:0:0:FF/40', 1],
    ['DEAD:BEEF::1/40', 256, 'DEAD:BEEF:0:0:0:0:0:100/40', 1],
    ['DEAD:BEEF::1/40', 257, 'DEAD:BEEF:0:0:0:0:0:101/40', 1],
    ['DEAD:BEEF::1/40', 65536, 'DEAD:BEEF:0:0:0:0:1:0/40', 1],
    ['DEAD:BEEF::1/40', 65537, 'DEAD:BEEF:0:0:0:0:1:1/40', 1],
    ['2001:620:0:4::/64', 1, '2001:620:0:4:0:0:0:1/64', 1],
    ['3FFE:2000:0:4::/64', 1, '3FFE:2000:0:4:0:0:0:1/64', 1],
    ['2001:620:600::1', 1, '2001:620:600:0:0:0:0:1/128', 0],
    ['2001:620:600:0:1::1', 1,'2001:620:600:0:1:0:0:1/128', 0],
);

subtest 'v6 old base' => sub {
    for my $entry (@addr) {
        my $ip = NetAddr::IP::Lite->new($entry->[0]);
        (my $addr = $entry->[0]) =~ s,/\d+,,;
        isa_ok($ip, ['NetAddr::IP::Lite'], "$addr ");
        is($ip->bits, 128, 'bits == 128');
        is($ip->version, 6, 'version == 6');
        my $index = $entry->[1];
        if ($entry->[3]) {
            is(uc $ip->nth($index), $entry->[2], "nth $addr, $index");
        }
        else {
            ok(!$ip->nth($index), "nth $addr, undef");
        }
    }
};

my $test = NetAddr::IP::Lite->new('f34::1');
isa_ok($test, 'NetAddr::IP::Lite');
ok($test->network->contains($test), '->contains');

$test = NetAddr::IP::Lite->new('f35::1/40');
isa_ok($test, 'NetAddr::IP::Lite');
ok($test->network->contains($test), '->contains');

done_testing;
