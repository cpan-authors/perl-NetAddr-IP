#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw( lives );

my @ips = qw(
    198.51.100.13
    198.51.100.0/24
    198.51.100.0/27
);

use NetAddr::IP ();

for my $input (@ips) {
    my $subnet = NetAddr::IP->new($input);
    isa_ok($subnet, 'NetAddr::IP');
    my $re = $subnet->re;
    my $rx;

    ok(lives { $rx = qr/$re/ }, 'Compilation of the resulting regular expression');

    for (my $ip = $subnet->network; $ip < $subnet->broadcast && $subnet->masklen != 32; $ip++) {
        ok($ip->addr =~ m/$rx/, "Match of $ip in $subnet");
    }

    ok($subnet->broadcast->addr =~ m/$rx/, "Match of broadcast of $subnet");
    ok(NetAddr::IP->new('default') !~ m/$rx/, '0/0 does not match');
}

done_testing;
