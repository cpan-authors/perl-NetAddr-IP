#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %ips = (
    '126.255.255.255' => 0,
    '127.0.0.0'       => 1,
    '127.0.0.1'       => 1,
    '127.255.255.254' => 1,
    '127.255.255.255' => 1,
    '128.0.0.0'       => 0,
    '::0'             => 0,
    '::1'             => 1,
    '::2'             => 0,
    '::127.0.0.1'     => 1,
    '::127.255.255.255' => 1,
    '::126.255.255.255' => 0,
    '::ffff:127.0.0.1'   => 1,
    '::ffff:128.0.0.0'   => 0,
);

for my $addr (sort keys %ips) {
    my $ip  = NetAddr::IP::Lite->new($addr);
    my $got = $ip->is_local();
    my $exp = $ips{$addr};
    cmp_ok($got, '==', $exp, "is_local($addr) returns $exp");
}

my @ips6 = (
    '127.0.0.1'       => 1,
    '127.255.255.255' => 1,
    '128.0.0.0'       => 0,
);

for (my $i = 0; $i <= $#ips6; $i += 2) {
    my $ip  = NetAddr::IP::Lite->new6($ips6[$i]);
    my $got = $ip->is_local();
    my $exp = $ips6[$i + 1];
    cmp_ok($got, '==', $exp, "is_local(new6($ips6[$i])) returns $exp");
}

done_testing;
