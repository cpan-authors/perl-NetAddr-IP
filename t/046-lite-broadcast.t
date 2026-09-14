#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $loip = NetAddr::IP::Lite->new('::1.2.3.4/120');
my $hiip = NetAddr::IP::Lite->new('FF00::4/120');

subtest 'stringify hiip' => sub {
    my $exp = 'FF00:0:0:0:0:0:0:4/120';
    is("$hiip", $exp, 'hiip stringifies correctly');
};

subtest 'broadcast lo' => sub {
    my $exp   = '0:0:0:0:0:0:102:3FF/120';
    my $broad = $loip->broadcast;
    is("$broad", $exp, 'loip broadcast correct');
};

subtest 'broadcast hi' => sub {
    my $exp   = 'FF00:0:0:0:0:0:0:FF/120';
    my $broad = $hiip->broadcast;
    is("$broad", $exp, 'hiip broadcast correct');
};

done_testing;
