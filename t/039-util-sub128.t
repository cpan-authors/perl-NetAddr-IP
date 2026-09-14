#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Util qw( ipv6_aton ipv6_n2x sub128 );

my @num = qw(
    ::f712:fff:fffe		::f712:fff:fffc		1	0:0:0:0:0:0:0:2
    ::712:fff:fffe		::712:fff:fffc		1	0:0:0:0:0:0:0:2
    ::712:ffff:fffe		::712:ffff:fffc		1	0:0:0:0:0:0:0:2
    ::f712:ffff:fffa	::f712:ffff:fffc	0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
    ::f712:fff:fffa		::f712:fff:fffc		0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
    ::712:fff:fffa		::712:fff:fffc		0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
    ::712:ffff:fffa		::712:ffff:fffc		0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
    ::2			::1			1	0:0:0:0:0:0:0:1
    ::f712:ffff:fffe	::f712:ffff:fffc	1	0:0:0:0:0:0:0:2
    ::1			::3			0	FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
    ::1234			::1234			1	0:0:0:0:0:0:0:0
);

subtest 'sub128 return value' => sub {
    for (my $i = 0; $i < @num; $i += 4) {
        my $num   = ipv6_aton($num[$i]);
        my $minus = ipv6_aton($num[$i + 1]);
        my $rv    = sub128($num, $minus);
        cmp_ok($rv, '==', $num[$i + 2], "sub128 return value for $num[$i] - $num[$i + 1]");
    }
};

subtest 'sub128 difference' => sub {
    for (my $i = 0; $i < @num; $i += 4) {
        my $num   = ipv6_aton($num[$i]);
        my $minus = ipv6_aton($num[$i + 1]);
        my ($rv, $dif) = sub128($num, $minus);
        cmp_ok($rv, '==', $num[$i + 2], "sub128 return value for $num[$i] - $num[$i + 1]");
        $dif = ipv6_n2x($dif);
        is($dif, $num[$i + 3], "sub128 difference for $num[$i] - $num[$i + 1]");
    }
};

done_testing;
