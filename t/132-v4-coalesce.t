#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

plan skip_all => 'LIGHTERIPTESTS = yes'
    if defined $ENV{LIGHTERIPTESTS} && $ENV{LIGHTERIPTESTS} =~ m/yes/i;

use NetAddr::IP qw( Coalesce );

my @ips;

for my $o (0 .. 255) {
    push @ips, NetAddr::IP->new("10.0.$o.1");
    push @ips, NetAddr::IP->new("10.0.$o.10");
    push @ips, NetAddr::IP->new("10.0.$o.100");
}

sub tst {
    my $r = Coalesce(24, 4, @ips);
    ok(ref($r) eq 'ARRAY', 'Return type from Coalesce');
    is(scalar @$r, 0, 'Empty array returned as expected');

    $r = Coalesce(24, 2, @ips);
    ok(ref($r) eq 'ARRAY', 'Return type from Coalesce');
    is(scalar @$r, 256, 'Whole result set as expected');
    my @c = NetAddr::IP::Compact(@$r);
    is(scalar @c, 1, 'Results are compactable');
    ok($c[0] eq '10.0.0.0/16', 'Correct results');

    $r = Coalesce(24, 2, @ips, NetAddr::IP->new('10.0.0.125/23'));
    ok(ref($r) eq 'ARRAY', 'Return type from Coalesce');
    ok((grep { $_ eq '10.0.0.0/23' } @$r), '/23 went through');
    @c = NetAddr::IP::Compact(@$r);
    is(scalar @c, 1, 'Results are compactable');
    ok($c[0] eq '10.0.0.0/16', 'Correct results');
}

subtest 'default imports' => sub {
    tst();
};

{
    delete $NetAddr::IP::{Coalesce};
    import NetAddr::IP qw(:old_nth);

    subtest ':old_nth imports' => sub {
        tst();
    };
}

subtest 'result order is deterministic' => sub {
    my @h;
    for my $o (0 .. 5) {
        push @h, NetAddr::IP->new("10.0.$o.$_/32") for 1 .. 3;
    }

    my $r = Coalesce(24, 2, @h);
    is(scalar @$r, 6, 'six /24 nets are returned');

    my @got = map { "$_" } @$r;
    my @exp = map { "10.0.$_.0/24" } 0 .. 5;
    is(join(',', @got), join(',', @exp), 'coalesce results are in address order');

    my $rev = Coalesce(24, 2, reverse @h);
    is(join(',', map { "$_" } @$rev), join(',', @got),
       'reversing the argument list does not change the result');

    # pass through nets and counted nets are ordered together
    $r = Coalesce(24, 2, NetAddr::IP->new('10.0.9.0/23'), @h);
    @got = map { "$_" } @$r;
    @exp = ('10.0.0.0/24', '10.0.1.0/24', '10.0.2.0/24', '10.0.3.0/24',
            '10.0.4.0/24', '10.0.5.0/24', '10.0.8.0/23');
    is(join(',', @got), join(',', @exp),
       'a pass through net is sorted in with the counted nets');
};

subtest 'coalesce counts subnet addresses, not usable hosts' => sub {
    # RFC 5737 test ranges: 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24
    my @two25 = (NetAddr::IP->new('198.51.100.0/25'), NetAddr::IP->new('198.51.100.128/25'));
    my @four26 = map { NetAddr::IP->new("203.0.113." . ($_ * 64) . "/26") } 0 .. 3;
    my @all30 = map { NetAddr::IP->new("192.0.2." . ($_ * 4) . "/30") } 0 .. 63;
    my @all32 = map { NetAddr::IP->new("203.0.113.$_/32") } 0 .. 255;

    my $r = Coalesce(24, 256, @two25);
    is(scalar @$r, 1, 'two /25 nets reach a threshold of 256');
    is("$r->[0]", '198.51.100.0/24', 'two /25 nets coalesce to 198.51.100.0/24');

    $r = Coalesce(24, 256, @four26);
    is(scalar @$r, 1, 'four /26 nets reach a threshold of 256');

    $r = Coalesce(24, 256, @all30);
    is(scalar @$r, 1, 'sixty four /30 nets reach a threshold of 256');

    $r = Coalesce(24, 256, @all32);
    is(scalar @$r, 1, 'two hundred and fifty six /32 nets reach a threshold of 256');

    $r = Coalesce(24, 256, NetAddr::IP->new('203.0.113.0/25'));
    is(scalar @$r, 0, 'one /25 net does not reach a threshold of 256');
    $r = Coalesce(24, 128, NetAddr::IP->new('192.0.2.0/25'));
    is(scalar @$r, 1, 'one /25 net reaches a threshold of 128');
    $r = Coalesce(24, 129, NetAddr::IP->new('198.51.100.0/25'));
    is(scalar @$r, 0, 'one /25 net does not reach a threshold of 129');

    $r = Coalesce(24, 257, @two25);
    is(scalar @$r, 0, 'two /25 nets do not reach a threshold of 257');
    $r = Coalesce(24, 257, @all32);
    is(scalar @$r, 0, 'two hundred and fifty six /32 nets do not reach 257');

    import NetAddr::IP qw(:old_nth);
    is($NetAddr::IP::Lite::Old_nth, 1, ':old_nth is in effect');
    $r = Coalesce(24, 256, @two25);
    is(scalar @$r, 1, 'two /25 nets reach a threshold of 256 under :old_nth');
};

done_testing;
