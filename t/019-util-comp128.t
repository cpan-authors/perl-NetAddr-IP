#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Util qw( comp128 ipv6_aton ipv6_n2x );

my %tests = (
    '::'                                      => 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF',
    'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF' => '0:0:0:0:0:0:0:0',
    'A1B2:C3D4:E5D6:F7E8:08F9:190A:2A1B:3B4C' => '5E4D:3C2B:1A29:817:F706:E6F5:D5E4:C4B3',
);

for my $input (sort keys %tests) {
    my $bstr = ipv6_aton($input);
    my $cnum = comp128($bstr);
    my $rv   = ipv6_n2x($cnum);
    my $exp  = $tests{$input};
    is($rv, $exp, "comp128($input)");
}

done_testing;
