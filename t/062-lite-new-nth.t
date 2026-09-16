#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $ip4 = NetAddr::IP::Lite->new('192.0.2.11/29');

subtest 'nth tests' => sub {
    my %try = (
        0 => '192.0.2.9',
        1 => '192.0.2.10',
        2 => '192.0.2.11',
        3 => '192.0.2.12',
        4 => '192.0.2.13',
        5 => '192.0.2.14',
        6 => 'undef',
    );

    for my $input (sort { $a <=> $b } keys %try) {
        my $rv = $ip4->nth($input);
        $rv = defined $rv
            ? $rv->addr
            : 'undef';
        is($rv, $try{$input}, "nth($input) returns $try{$input}");
    }
};

{
    my $ip = NetAddr::IP::Lite->new('192.0.2.4/32');
    my $num = $ip->num();
    is($num, 1, 'num() returns 1 for /32');
}

{
    my $ip = NetAddr::IP::Lite->new('192.0.2.4/31');
    my $num = $ip->num();
    is($num, 2, 'num() returns 2 for /31');
}

## issue #10 – non-integer indices must be rejected

my $net = NetAddr::IP::Lite->new('10.0.0.0/24');

is($net->nth(1.5), undef, 'nth(1.5) returns undef');
is($net->nth(1.9), undef, 'nth(1.9) returns undef');
is($net->nth(0.1), undef, 'nth(0.1) returns undef');
is($net->nth("2.5"), undef, 'nth("2.5") returns undef');
is($net->nth("abc"), undef, 'nth("abc") returns undef');
is($net->nth(undef), undef, 'nth(undef) returns undef');
is(defined $net->nth(0), 1, 'nth(0) is defined');
is(defined $net->nth(1), 1, 'nth(1) is defined');
is(defined $net->nth(-1), '', 'nth(-1) is undef');
is(defined $net->nth(254), '', 'nth(254) is undef');

done_testing;
