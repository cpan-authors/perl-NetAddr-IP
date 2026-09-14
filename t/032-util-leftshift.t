#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Util qw( ipv6_aton ipv6_n2x shiftleft );

my @num = # input	shift	expected
(
    ['1::1', 'none', '1:0:0:0:0:0:0:1'],
    ['1::1', '0',    '1:0:0:0:0:0:0:1'],
    ['1::1', '1',    '2:0:0:0:0:0:0:2'],
    ['1::1', '2',    '4:0:0:0:0:0:0:4'],
    ['1::1', '3',    '8:0:0:0:0:0:0:8'],
    ['1::1', '15',   '8000:0:0:0:0:0:0:8000'],
    ['1::1', '16',   '0:0:0:0:0:0:1:0'],
    ['1::1', '128',  '0:0:0:0:0:0:0:0'],
);

for my $entry (@num) {
    my ($input, $shift, $expected) = @$entry;
    my $bstr = ipv6_aton($input);
    my $rv;
    if ($shift =~ m/[^\d]/) {
        $rv = shiftleft($bstr);
    }
    else {
        $rv = shiftleft($bstr, $shift);
    }
    my $got = ipv6_n2x($rv);
    is($got, $expected, "shiftleft($input, $shift)");
}

done_testing;
