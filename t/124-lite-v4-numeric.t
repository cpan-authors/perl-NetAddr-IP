#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %nets = (
    '10.0.0.0/20'    => [ 167772160,  4294963200 ],
    '10.0.15.0/24'   => [ 167776000,  4294967040 ],
    '192.168.0.0/24' => [ 3232235520, 4294967040 ],
    'broadcast'      => [ 4294967295, 4294967295 ],
    'default'        => [ 0,          0 ],
);

for my $cidr (keys %nets) {
    my $ip = NetAddr::IP::Lite->new($cidr);
    my ($addr, $mask) = $ip->numeric;

    my $nip = NetAddr::IP::Lite->new($addr, $mask);

    ok($nip, 'new from numeric returned truthy');

    ok($nip && $nip->cidr eq $ip->cidr, 'round-trip cidr matches');

    is($addr, $nets{$cidr}->[0], 'numeric address matches');

    is($mask, $nets{$cidr}->[1], 'numeric mask matches');
}

subtest 'an address below 0.0.1.0 rebuilds from numeric' => sub {
    for my $cidr ('0.0.0.0/32', '0.0.0.1/32', '0.0.0.5/30', '0.0.0.255/32') {
        my $ip = NetAddr::IP::Lite->new($cidr);
        is( NetAddr::IP::Lite->new($ip->numeric) . '',
            $cidr, "numeric round-trip of $cidr"
        );
    }
    is( NetAddr::IP::Lite->new(NetAddr::IP::Lite->new('0.0.0.5/0')->numeric) . '',
        '5.0.0.0/0',
        'a numeric mask of 0 stays prefix length 0'
    );
    is( NetAddr::IP::Lite->new('0x5', 4_294_967_295) . '',
        '0.0.0.5/32',
        'a raw mask makes a hex number the address value'
    );
    is( NetAddr::IP::Lite->new('0b101', 4_294_967_040) . '',
        '0.0.0.5/24',
        'a raw mask makes a binary number the address value'
    );
    is( NetAddr::IP::Lite->new('5', 8) . '',
        '5.0.0.0/8',
        'a prefix length makes a small number the first octet'
    );
};

done_testing;
