#!/usr/bin/env perl

use Test2::V1 -ipP;

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

done_testing;
