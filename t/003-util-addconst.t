#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Util qw( addconst ipv6_aton ipv6_n2x );

subtest 'addconst positive' => sub {
    my %num = (
        '::'                                      => ['0:0:0:0:0:0:0:0',    0],
        '::FFFF'                                  => ['0:0:0:0:0:0:1:3',    4],
        '::FFFF:FFFF'                             => ['0:0:0:0:0:1:0:5',    6],
        '::FFFF:FFFF:FFFF'                        => ['0:0:0:0:1:0:0:7',    8],
        '::FFFF:FFFF:FFFF:ffff'                   => ['0:0:0:1:0:0:0:9',   10],
        '::FFFF:FFFF:FFFF:ffff:ffff'              => ['0:0:1:0:0:0:0:B',   12],
        '::FFFF:FFFF:FFFF:ffff:ffff:ffff'         => ['0:1:0:0:0:0:0:D',   14],
        '0:FFFF:FFFF:FFFF:ffff:ffff:ffff:ffff'    => ['1:0:0:0:0:0:0:F',   16],
        'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF' => ['0:0:0:0:0:0:0:11',  18],
    );

    for my $input (sort { $a cmp $b } keys %num) {
        my ($expected, $const) = @{$num{$input}};
        my $bnum = ipv6_aton($input);
        my ($carry, $rv) = addconst($bnum, $const);
        $rv = ipv6_n2x($rv);
        is($rv, $expected, "addconst($input, $const)");
    }
};

subtest 'addconst negative' => sub {
    my %num = (
        '::'                                      => ['FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE',   2],
        'FFFF::'                                  => ['FFFE:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFC',   4],
        'FFFF:FFFF::'                             => ['FFFF:FFFE:FFFF:FFFF:FFFF:FFFF:FFFF:FFFA',   6],
        'FFFF:FFFF:FFFF::'                        => ['FFFF:FFFF:FFFE:FFFF:FFFF:FFFF:FFFF:FFF8',   8],
        'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:0'    => ['FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE:FFF0',  16],
        'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF' => ['FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF',   0],
        'ffff:ffff:ffff:ffff::'                   => ['FFFF:FFFF:FFFF:FFFE:FFFF:FFFF:FFFF:FFF6',  10],
        'ffff:ffff:ffff:ffff:ffff::'              => ['FFFF:FFFF:FFFF:FFFF:FFFE:FFFF:FFFF:FFF4',  12],
        'ffff:ffff:ffff:ffff:ffff:ffff::'         => ['FFFF:FFFF:FFFF:FFFF:FFFF:FFFE:FFFF:FFF2',  14],
    );

    for my $input (sort { $a cmp $b } keys %num) {
        my ($expected, $const) = @{$num{$input}};
        my $bnum = ipv6_aton($input);
        my ($carry, $rv) = addconst($bnum, -$const);
        $rv = ipv6_n2x($rv);
        is($rv, $expected, "addconst($input, -$const)");
    }
};

done_testing;
