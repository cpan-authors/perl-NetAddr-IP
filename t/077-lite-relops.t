#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %gt = (
    '255.255.255.255/32 vs 0.0.0.0/0'                               => [ '255.255.255.255/32', '0.0.0.0/0' ],
    'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff vs ::/0'                => [ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', '::/0' ],
    '10.0.1.0/16 vs 10.0.0.1/24'                                     => [ '10.0.1.0/16', '10.0.0.1/24' ],
    '10.0.0.1/24 vs 10.0.0.0/24'                                     => [ '10.0.0.1/24', '10.0.0.0/24' ],
    'deaf:beef::1/64 vs dead:beef::/64'                               => [ 'deaf:beef::1/64', 'dead:beef::/64' ],
);

my %ngt = (
    '0.0.0.0/0 vs 255.255.255.255/32'                                => [ '0.0.0.0/0', '255.255.255.255/32' ],
    '::/0 vs ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'                => [ '::/0', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' ],
    '10.0.0.0/24 vs 10.0.0.0/24'                                     => [ '10.0.0.0/24', '10.0.0.0/24' ],
    'dead:beef::/60 vs dead:beef::/60'                               => [ 'dead:beef::/60', 'dead:beef::/60' ],
);

my %cmp = (
    '0.0.0.0/0 vs 255.255.255.255/32'                                => [ '0.0.0.0/0', '255.255.255.255/32', -1 ],
    '::/0 vs ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff'                => [ '::/0', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', -1 ],
    '10.0.0.0/16 vs 10.0.0.0/8'                                      => [ '10.0.0.0/16', '10.0.0.0/8', 1 ],
    'dead:beef::/60 vs dead:beef::/40'                               => [ 'dead:beef::/60', 'dead:beef::/40', 1 ],
    '10.0.0.0/24 vs 10.0.0.0/8'                                      => [ '10.0.0.0/24', '10.0.0.0/8', 1 ],
    '255.255.255.255/32 vs 0.0.0.0/0'                                => [ '255.255.255.255/32', '0.0.0.0/0', 1 ],
    'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff vs ::/0'                => [ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', '::/0', 1 ],
    '142.52.5.87 vs 142.52.2.88'                                     => [ '142.52.5.87', '142.52.2.88', 1 ],
    '10.0.0.0/24 vs 10.0.0.0/24'                                     => [ '10.0.0.0/24', '10.0.0.0/24', 0 ],
    'default vs default'                                              => [ 'default', 'default', 0 ],
    'broadcast vs broadcast'                                          => [ 'broadcast', 'broadcast', 0 ],
    'loopback vs loopback'                                            => [ 'loopback', 'loopback', 0 ],
);

subtest 'greater than' => sub {
    for my $name (sort keys %gt) {
        my ($a_val, $b_val) = @{$gt{$name}};
        my $a_ip = NetAddr::IP::Lite->new($a_val);
        my $b_ip = NetAddr::IP::Lite->new($b_val);

        ok($a_ip > $b_ip, "$a_ip > $b_ip");
    }
};

subtest 'not greater than' => sub {
    for my $name (sort keys %ngt) {
        my ($a_val, $b_val) = @{$ngt{$name}};
        my $a_ip = NetAddr::IP::Lite->new($a_val);
        my $b_ip = NetAddr::IP::Lite->new($b_val);

        ok(!($a_ip > $b_ip), "$a_ip !> $b_ip");
    }
};

subtest 'spaceship and cmp' => sub {
    for my $name (sort keys %cmp) {
        my ($a_val, $b_val, $expected) = @{$cmp{$name}};
        my $a_ip = NetAddr::IP::Lite->new($a_val);
        my $b_ip = NetAddr::IP::Lite->new($b_val);

        is($a_ip <=> $b_ip, $expected, "$a_ip <=> $b_ip is $expected");
        is($a_ip cmp $b_ip, $expected, "$a_ip cmp $b_ip is $expected");
    }
};

done_testing;
