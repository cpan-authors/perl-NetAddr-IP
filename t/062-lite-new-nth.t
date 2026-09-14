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

done_testing;
