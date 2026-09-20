#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( lives );

SKIP: {
    skip 'Storable not available'
        unless eval { require Storable; Storable->import(qw(freeze thaw)); 1; };

    skip 'NetAddr::IP not available'
        unless eval { require NetAddr::IP; NetAddr::IP->import(':old_storable'); 1; };

    subtest 'old storable round-trip' => sub {
        my $oip = NetAddr::IP->new('localhost');
        isa_ok($oip, ['NetAddr::IP'], 'Correct return type');

        my $serialized;
        ok(lives { $serialized = freeze($oip) }, 'Freezing');

        my $nip;
        ok(lives { $nip = thaw($serialized) }, 'Thawing');

        isa_ok($nip, ['NetAddr::IP'], 'Recovered correct type');
        is("$nip", "$oip", 'New object eq original object');
    };
}

done_testing;
