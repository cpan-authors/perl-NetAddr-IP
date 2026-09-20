#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( inet_aton );
use NetAddr::IP::Lite ();

ok(! defined NetAddr::IP::Lite->new_from_aton(''), 'blank netaddr returns undef');
ok(! defined NetAddr::IP::Lite->new_from_aton(undef), 'undefined netaddr returns undef');
ok(! defined NetAddr::IP::Lite->new_from_aton('192.0.2.4'), 'Dot Quad IP returns undef');

subtest 'new_from_aton IPv4 addresses' => sub {
    for my $addr (qw(
        0.0.0.0
        127.0.0.1
        255.255.255.255
    )) {
        my $naddr = inet_aton($addr);
        my $ip    = NetAddr::IP::Lite->new_from_aton($naddr);
        ok(defined $ip,           "$addr is defined");
        ok($ip->bits == 32,       "$addr is 32 bits wide");
        ok($ip->mask eq '255.255.255.255', 'mask is all ones');
        ok($ip->version == 4,     'version is IPv4');
    }
};

done_testing;
