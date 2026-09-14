#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

subtest 'stringify' => sub {
    my $hiip = NetAddr::IP::Lite->new('FF00::1:4/120');
    is(
        sprintf('%s', $hiip),
        'FF00:0:0:0:0:0:1:4/120',
        'stringify hi ip',
    );
};

subtest 'lo ip mask' => sub {
    my $loip = NetAddr::IP::Lite->new('::1.2.3.4/120');
    my $mask = $loip->mask;
    is($mask, 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FF00', 'lo ip mask');
    ok(!ref $mask, 'lo ip mask is not a reference');
};

subtest 'hi ip mask' => sub {
    my $hiip = NetAddr::IP::Lite->new('FF00::1:4/120');
    my $mask = $hiip->mask;
    is($mask, 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FF00', 'hi ip mask');
    ok(!ref $mask, 'hi ip mask is not a reference');
};

subtest 'dot quad mask' => sub {
    my $dqip = NetAddr::IP::Lite->new('192.0.2.4/24');
    my $mask = $dqip->mask;
    is($mask, '255.255.255.0', 'dot quad mask');
    ok(!ref $mask, 'dot quad mask is not a reference');
};

done_testing;
