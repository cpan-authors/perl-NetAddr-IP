#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

subtest 'increment loop' => sub {
    my $count = 1;
    for (my $ip = NetAddr::IP::Lite->new('192.0.2.1/28');
         $ip < $ip->broadcast;
         $ip++)
    {
        my $o = $ip->addr;
        $o =~ s/^.+\.([0-9]+)$/$1/;
        ok($o == $count, "IP $count incremented correctly");
        $count++;
    }
};

my $ip = NetAddr::IP::Lite->new('192.0.2.255/24');
$ip++;

is("$ip", '192.0.2.0/24', 'increment wraps around');

subtest 'addition with deltas' => sub {
    my @deltas = (0, 1, 2, 3, 255);
    my $ip = NetAddr::IP::Lite->new('192.0.2.0/24');
    for my $v (@deltas) {
        is($ip + $v, '192.0.2.' . $v . '/24', "add $v to 192.0.2.0/24");
    }
};

done_testing;
