#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Util qw( add128 comp128 ipv6_aton ipv6_n2x sub128 );

my @num = qw(
    FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE   ::1                               0  FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
    ::1                                       FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE  0  FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF
    ::2                                       FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE  1  0:0:0:0:0:0:0:0
    FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE   ::2                               1  0:0:0:0:0:0:0:0
    FFFF:FFFF:FFFF:FFFF:FFFF:8FFF:FFFF:FFFE   ::7000:0:2                        1  0:0:0:0:0:0:0:0
    FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE   ::3                               1  0:0:0:0:0:0:0:1
    ::1                                       ::2                               0  0:0:0:0:0:0:0:3
    ::FFFF                                    ::FFFF                            0  0:0:0:0:0:0:1:FFFE
    ::FFFF:FFFF                               ::FFFF:FFFF                       0  0:0:0:0:0:1:FFFF:FFFE
    ::FFFF:FFFF:FFFF                          ::FFFF:FFFF:FFFF                  0  0:0:0:0:1:FFFF:FFFF:FFFE
    ::FFFF:FFFF:FFFF:FFFF                     ::FFFF:FFFF:FFFF:FFFF             0  0:0:0:1:FFFF:FFFF:FFFF:FFFE
    ::FFFF:FFFF:FFFF:FFFF:FFFF                ::FFFF:FFFF:FFFF:FFFF:FFFF        0  0:0:1:FFFF:FFFF:FFFF:FFFF:FFFE
    ::FFFF:FFFF:FFFF:FFFF:FFFF:FFFF           ::FFFF:FFFF:FFFF:FFFF:FFFF:FFFF   0  0:1:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
    ::FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF      ::FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF  0  1:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE
);

subtest 'check carry' => sub {
    for (my $i = 0; $i < @num; $i += 4) {
        my $num  = ipv6_aton($num[$i]);
        my $plus = ipv6_aton($num[$i + 1]);
        my $rv   = add128($num, $plus);
        is($rv, $num[$i + 2], "add128 carry: $num[$i] + $num[$i + 1]");
    }
};

subtest 'check carry + result' => sub {
    for (my $i = 0; $i < @num; $i += 4) {
        my $num  = ipv6_aton($num[$i]);
        my $plus = ipv6_aton($num[$i + 1]);
        my ($rv, $result) = add128($num, $plus);
        is($rv, $num[$i + 2], "add128 result: $num[$i] + $num[$i + 1]");
        $result = ipv6_n2x($result);
        is($result, $num[$i + 3], "add128 hex: $num[$i] + $num[$i + 1]");
    }
};

## subtraction of comp of 'plus' should invert carry and add 1 to 'exp'
## start at first 'number' that starts with '::FFFF'
subtest 'sub128 with comp of plus' => sub {
    for (my $i = 0; $i < @num; $i += 4) {
        next unless $num[$i] =~ m/^::FFFF/;
        my $num   = ipv6_aton($num[$i]);
        my $plus  = ipv6_aton($num[$i + 1]);
        my $minus = comp128($plus);
        my ($rv, $result) = sub128($num, $minus);
        is($rv, $num[$i + 2], "sub128 carry: $num[$i] - ~$num[$i + 1]");
        $num[$i + 3] =~ s/FFFE$/FFFF/;
        $result = ipv6_n2x($result);
        is($result, $num[$i + 3], "sub128 hex: $num[$i] - ~$num[$i + 1]");
    }
};

done_testing;
