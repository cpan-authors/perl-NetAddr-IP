#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw( lives );

plan skip_all => 'Storable not available'
    unless eval { require Storable; Storable->import('freeze', 'thaw'); 1 };

use NetAddr::IP ();

my $oip = NetAddr::IP->new('localhost');
my $nip;

isa_ok($oip, ['NetAddr::IP'], 'Correct return type');

my $serialized;

ok(lives { $serialized = freeze($oip) }, 'Freezing');

ok(lives { $nip = thaw($serialized) }, 'Thawing');

isa_ok($nip, ['NetAddr::IP'], 'Recovered correct type');
is("$nip", "$oip", 'New object eq original object');

done_testing;
