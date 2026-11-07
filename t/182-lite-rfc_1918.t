#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %ips = (
    '9.255.255.255'   => 0,
    '10.0.0.0'        => 1,
    '10.255.255.255'  => 1,
    '11.0.0.0'        => 0,
    '172.15.255.255'  => 0,
    '172.16.0.0'      => 1,
    '172.31.255.255'  => 1,
    '172.32.0.0'      => 0,
    '192.167.255.255' => 0,
    '192.168.0.0'     => 1,
    '192.168.255.255' => 1,
    '192.169.0.0'     => 0,
);

for my $addr ( sort keys %ips ) {
    my $ip  = NetAddr::IP::Lite->new($addr);
    my $got = $ip->is_rfc1918();
    my $exp = $ips{$addr};
    is( $got, $exp, "$ip is_rfc1918 = $exp" );
}

subtest 'an IPv4 address held in IPv6 answers as its IPv4 form' => sub {
    my %held = (
        '::10.0.0.1'               => 1,
        '::11.0.0.0'               => 0,
        '::ffff:10.0.0.1'          => 1,
        '::ffff:10.0.0.0/104'      => 1,
        '::ffff:10.0.0.0/103'      => 0,
        '::ffff:11.0.0.0'          => 0,
        '::ffff:172.16.0.0/108'    => 1,
        '::ffff:172.32.0.0'        => 0,
        '::ffff:192.168.255.255'   => 1,
        '::ffff:192.169.0.0'       => 0,
        '0:0:0:0:1:ffff:a00:1'     => 0,
        '2001:db8::a00:1'          => 0,
        'ffff:ffff::ffff:10.0.0.1' => 0,
    );
    for my $addr ( sort keys %held ) {
        is( NetAddr::IP::Lite->new($addr)->is_rfc1918(),
            $held{$addr}, "is_rfc1918($addr) is $held{$addr}"
        );
    }
    for my $addr (qw(10.0.0.1 172.31.255.255 192.168.0.1 192.169.0.0)) {
        is( NetAddr::IP::Lite->new6($addr)->is_rfc1918(),
            NetAddr::IP::Lite->new($addr)->is_rfc1918(),
            "is_rfc1918(new6($addr)) matches is_rfc1918($addr)"
        );
    }
};

done_testing;
