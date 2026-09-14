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

done_testing;
