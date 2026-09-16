#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my %nets = (
    '10.1.2.3'   => [32, 0],
    '10.2.3.4'   => [31, 1],
    '10.0.0.16'  => [24, 255],
    '10.128.0.1' => [8,  2 ** 24 - 1],
    '10.0.0.5'   => [30, 3],
    '0.0.0.0'    => [0,  2 ** 32 - 1],
);

my $new = 1;

subtest 'new numeric returns' => sub {
    for my $key (keys %nets) {
        my $nc = $nets{$key}->[1] - $new;
        $nc = 1 if $nc < 0;
        $nc = 2 if $new && $nets{$key}->[0] == 31;
        my $ip = NetAddr::IP::Lite->new($key, $nets{$key}->[0]);
        cmp_ok($ip->num, '==', $nc, "$key num");
    }
};

import NetAddr::IP::Lite qw(:old_nth);
$new = 0;

subtest 'old numeric returns' => sub {
    for my $key (keys %nets) {
        my $nc = $nets{$key}->[1] - $new;
        $nc = 1 if $nc < 0;
        $nc = 2 if $new && $nets{$key}->[0] == 31;
        my $ip = NetAddr::IP::Lite->new($key, $nets{$key}->[0]);
        cmp_ok($ip->num, '==', $nc, "$key num (old)");
    }
};

done_testing;
