#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::InetBase qw( ipv6_aton ipv6_n2x isAnyIPv4 isIPv4 isNewIPv4 );

my @num = qw(
    ::
    8000::
    4000::
    2000::
    1000::
    800::
    400::
    200::
    100::
    80::
    40::
    20::
    10::
    1::
    0:8000::
    0:4000::
    0:2000::
    0:1000::
    0:800::
    0:400::
    0:200::
    0:100::
    0:80::
    0:40::
    0:20::
    0:10::
    0:1::
    0:0:8000::
    0:0:4000::
    0:0:2000::
    0:0:1000::
    0:0:800::
    0:0:400::
    0:0:200::
    0:0:100::
    0:0:80::
    0:0:40::
    0:0:20::
    0:0:10::
    0:0:1::
    0:0:0:8000::
    0:0:0:4000::
    0:0:0:2000::
    0:0:0:1000::
    0:0:0:800::
    0:0:0:400::
    0:0:0:200::
    0:0:0:100::
    0:0:0:80::
    0:0:0:40::
    0:0:0:20::
    0:0:0:10::
    0:0:0:1::
    0:0:0:0:8000::
    0:0:0:0:4000::
    0:0:0:0:2000::
    0:0:0:0:1000::
    0:0:0:0:800::
    0:0:0:0:400::
    0:0:0:0:200::
    0:0:0:0:100::
    0:0:0:0:80::
    0:0:0:0:40::
    0:0:0:0:20::
    0:0:0:0:10::
    0:0:0:0:1::
    ::8000:0
    ::4000:0
    ::2000:0
    ::1000:0
    ::800:0
    ::400:0
    ::200:0
    ::100:0
    ::80:0
    ::40:0
    ::20:0
    ::10:0
    ::1:0
    ::8000
    ::4000
    ::2000
    ::1000
    ::800
    ::400
    ::200
    ::100
    ::80
    ::40
    ::20
    ::10
    ::1
);

subtest 'isIPv4' => sub {
    for my $input (@num) {
        my $bstr = ipv6_aton($input);
        my $rv   = isIPv4($bstr);
        my $exp  = ($input =~ m/[0-9]::$/) ? 0 : 1;
        is($rv, $exp, "isIPv4 for " . ipv6_n2x($bstr));
    }
};

subtest 'isAnyIPv4' => sub {
    for my $input (@num) {
        my $bstr = ipv6_aton($input);
        my $rv   = isAnyIPv4($bstr);
        my $exp  = ($input =~ m/[0-9]::$/) ? 0 : 1;
        is($rv, $exp, "isAnyIPv4 for " . ipv6_n2x($bstr));
    }
};

my $compat = ipv6_aton('::FFFF:0:0');

subtest 'isAnyIPv4 with compatible high bits' => sub {
    for my $input (@num) {
        my $bstr = ipv6_aton($input);
        $bstr  ^= $compat;
        my $rv   = isAnyIPv4($bstr);
        my $exp  = ($input =~ m/[0-9]::$/) ? 0 : 1;
        is($rv, $exp, "isAnyIPv4 compat for " . ipv6_n2x($bstr));
    }
};

subtest 'isNewIPv4 with compatible high bits' => sub {
    for my $input (@num) {
        my $bstr = ipv6_aton($input);
        $bstr  ^= $compat;
        my $rv   = isNewIPv4($bstr);
        my $exp  = ($input =~ m/[0-9]::$/) ? 0 : 1;
        is($rv, $exp, "isNewIPv4 compat for " . ipv6_n2x($bstr));
    }
};

done_testing;
