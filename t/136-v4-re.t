#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw( lives );

my @ips = qw(
    10.11.12.13
    10.11.12/24
    10.11.0/27
);

use NetAddr::IP ();

for my $input (@ips) {
    my $a = NetAddr::IP->new($input);
    isa_ok($a, 'NetAddr::IP');
    my $re = $a->re;
    my $rx;

    ok(lives { $rx = qr/$re/ }, 'Compilation of the resulting regular expression');

    for (my $ip = $a->network; $ip < $a->broadcast && $a->masklen != 32; $ip++) {
        ok($ip->addr =~ m/$rx/, "Match of $ip in $a");
    }

    ok($a->broadcast->addr =~ m/$rx/, "Match of broadcast of $a");
    ok(NetAddr::IP->new('default') !~ m/$rx/, '0/0 does not match');
}

done_testing;
