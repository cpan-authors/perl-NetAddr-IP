#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my %addr = (
    'localhost'       => '127.0.0.1',
    'broadcast'       => '255.255.255.255',
    '254.254.0.1'     => '254.254.0.1',
    'default'         => '0.0.0.0',
    '10.0.0.1'        => '10.0.0.1',
);

my %packed = (
    'localhost'       => pack('N', 0x7f000001),
    'broadcast'       => pack('N', 0xffffffff),
    '254.254.0.1'     => pack('N', 0xfefe0001),
    'default'         => pack('N', 0),
    '10.0.0.1'        => pack('N', 0x0a000001),
    '127.0.0.1'       => pack('N', 0x7f000001),
    '255.255.255.255' => pack('N', 0xffffffff),
    '0.0.0.0'         => pack('N', 0),
);

sub l_inet_aton {
    my $rv = (exists $packed{$_[0]}) ? $packed{$_[0]} : undef;
}

my $x;

ok(! defined NetAddr::IP::Lite->new("\1\1\1\1"),
   "binary unrecognized by default ". ($x ? $x->addr : ''));

NetAddr::IP::Lite::import(':aton');

ok(defined ($x = NetAddr::IP::Lite->new("\1\1\1\1")),
   "...but can be recognized ". $x->addr);

ok(!defined ($x = NetAddr::IP::Lite->new('bad rfc-952 characters')),
   "bad rfc-952 characters ". ($x ? $x->addr : ''));

subtest "aton returns packed address" => sub {
    for my $name (sort keys %addr) {
        my $expected = $addr{$name};
        is(NetAddr::IP::Lite->new($name)->aton, l_inet_aton($expected), "->aton($name)");
    }
};

subtest "new accepts aton packed address" => sub {
    for my $name (sort keys %addr) {
        my $expected = $addr{$name};
        ok(defined NetAddr::IP::Lite->new(l_inet_aton($expected)), "->new aton($expected)");
    }
};

subtest "new aton round-trips to expected address" => sub {
    for my $name (sort keys %addr) {
        my $expected = $addr{$name};
        is(NetAddr::IP::Lite->new(l_inet_aton($expected))->addr, $expected, "->new aton($expected)");
    }
};

done_testing;
