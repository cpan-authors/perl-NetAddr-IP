#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my @addr = (
    ['::',                     3,     '0:0:0:0:0:0:0:0/128',        0],
    ['::1',                    3,     '0:0:0:0:0:0:0:1/128',        0],
    ['F34::123 40',            2,     'F34:0:0:0:0:0:0:3/40',       1],
    ['DEAD:BEEF::1 40',        2,     'DEAD:BEEF:0:0:0:0:0:3/40',   1],
    ['1000::2 40',             0,     '1000:0:0:0:0:0:0:1/40',      1],
    ['1000::2000 40',          0,     '1000:0:0:0:0:0:0:1/40',      1],
    ['DEAD::CAFE 40',          0,     'DEAD:0:0:0:0:0:0:1/40',      1],
    ['DEAD:BEEF::1 40',        3,     'DEAD:BEEF:0:0:0:0:0:4/40',   1],
    ['DEAD:BEEF::1 40',        4,     'DEAD:BEEF:0:0:0:0:0:5/40',   1],
    ['DEAD:BEEF::1 40',        5,     'DEAD:BEEF:0:0:0:0:0:6/40',   1],
    ['DEAD:BEEF::1 40',        6,     'DEAD:BEEF:0:0:0:0:0:7/40',   1],
    ['DEAD:BEEF::1 40',        7,     'DEAD:BEEF:0:0:0:0:0:8/40',   1],
    ['DEAD:BEEF::1 40',        8,     'DEAD:BEEF:0:0:0:0:0:9/40',   1],
    ['DEAD:BEEF::1 40',        254,   'DEAD:BEEF:0:0:0:0:0:FF/40',  1],
    ['DEAD:BEEF::1 40',        255,   'DEAD:BEEF:0:0:0:0:0:100/40', 1],
    ['DEAD:BEEF::1 40',        256,   'DEAD:BEEF:0:0:0:0:0:101/40', 1],
    ['DEAD:BEEF::1 40',        65535, 'DEAD:BEEF:0:0:0:0:1:0/40',   1],
    ['DEAD:BEEF::1 40',        65536, 'DEAD:BEEF:0:0:0:0:1:1/40',   1],
    ['2001:620:0:4::/64',      0,     '2001:620:0:4:0:0:0:1/64',    1],
    ['3FFE:2000:0:4::/64',     0,     '3FFE:2000:0:4:0:0:0:1/64',   1],
    ['2001:620:600::1',         0,     '2001:620:600:0:0:0:0:1/128', 1],
    ['2001:620:600:0:1::1',     0,     '2001:620:600:0:1:0:0:1/128', 1],
);

subtest 'new_cis6 basic v6 tests' => sub {
    for my $a (@addr) {
        my $ip = NetAddr::IP::Lite->new_cis6($a->[0]);
        my $input = $a->[0];
        $input =~ s,/[0-9]+,,;
        isa_ok($ip, ['NetAddr::IP::Lite'], "$input ");
        is($ip->bits, 128, 'bits == 128');
        is($ip->version, 6, 'version == 6');
        my $index = $a->[1];
        if ($a->[3]) {
            is(uc $ip->nth($index), $a->[2], "nth $input, $index");
        }
        else {
            ok(!$ip->nth($index), "nth $input, undef");
        }
    }
};

my $ip = NetAddr::IP::Lite->new_cis6('f34::1');
isa_ok($ip, 'NetAddr::IP::Lite');
ok($ip->network->contains($ip), '->contains');

$ip = NetAddr::IP::Lite->new_cis6('f35::1 40');
isa_ok($ip, 'NetAddr::IP::Lite');
ok($ip->network->contains($ip), '->contains');

done_testing;
