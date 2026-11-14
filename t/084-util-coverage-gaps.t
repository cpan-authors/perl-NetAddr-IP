#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw(lives);
use Test2::Tools::Warnings  qw(warnings);

use NetAddr::IP::Util      qw(:all);
use NetAddr::IP::Constants qw($V4_PACKED_BYTES $V6_PACKED_BYTES);

subtest 'DESTROY and :noSock6 import paths are callable' => sub {
    ok(lives { NetAddr::IP::Util->DESTROY; 1 }, 'DESTROY is callable');

    ok(lives { NetAddr::IP::Util->import(':noSock6'); 1 }, ':noSock6 import');
    is(havegethostbyname2(), 0, 'havegethostbyname2 is false after :noSock6');
};

subtest 'inet_4map6 handles IPv6-length inputs' => sub {
    my $v4compat = pack('C16', (0) x 12, 192, 0, 2, 1);
    my $mapped   = inet_4map6($v4compat);
    ok(defined $mapped, 'IPv4-compatible IPv6 address maps');
    is( unpack('H*', $mapped), '00000000000000000000ffffc0000201',
        'mapped form is IPv4-mapped IPv6'
    );

    my $v6 = pack('C16', 0x20, 0x01, 0x0d, 0xb8, (0) x 12);
    is(inet_4map6($v6), undef, 'pure IPv6 address does not map');
};

subtest 'inet_4map6 of undef returns undef without a warning' => sub {
    my $mapped = 'not called';
    is(warnings { $mapped = inet_4map6(undef) }, [],    'inet_4map6 of undef does not warn');
    is($mapped,                                  undef, 'inet_4map6 of undef is undef');
};

subtest '_end_gethostbyname and _addrs_once guard branches' => sub {
    my @empty = NetAddr::IP::UtilPolluted::_end_gethostbyname('x', '', 2, $V4_PACKED_BYTES, pack('C4', 0, 0, 0, 0));
    is(\@empty, [], 'zero first address returns empty list');

    my @addrs = NetAddr::IP::UtilPolluted::_addrs_once(
        sub { return (undef, undef) },
        { addr => 'x' });
    is(\@addrs, [], 'undefined unpacked address is skipped');
};

done_testing;
