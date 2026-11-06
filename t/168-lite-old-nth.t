#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Warnings qw( no_warnings warning );

use NetAddr::IP::Lite ();

subtest 'importing :old_nth warns that it is deprecated' => sub {
    like(
        warning { NetAddr::IP::Lite->import(':old_nth') },
qr/^:old_nth is deprecated and will be removed in version 5; without it nth\(0\) is the first usable host and num\(\) counts only usable hosts at /,
        'the warning names the tag and what the code does without it'
    );
    is( $NetAddr::IP::Lite::Old_nth, 1, 'the tag still takes effect' );
    ok(
        no_warnings {
            no warnings 'deprecated';
            NetAddr::IP::Lite->import(':old_nth');
        },
        'no warnings deprecated silences it'
    );
};

my $ip4 = NetAddr::IP::Lite->new('192.0.2.11/29');

my %try = (
    '0' => undef,
    '1' => '192.0.2.9',
    '2' => '192.0.2.10',
    '3' => '192.0.2.11',
    '4' => '192.0.2.12',
    '5' => '192.0.2.13',
    '6' => '192.0.2.14',
    '7' => '192.0.2.15',
    '8' => undef,
);

for my $input ( sort { $a <=> $b } keys %try ) {
    my $rv  = $ip4->nth($input);
    my $got = defined $rv ? $rv->addr : 'undef';
    is(
        $got,
        $try{$input} // 'undef',
        "nth($input) returns " . ( $try{$input} // 'undef' )
    );
}

done_testing;
