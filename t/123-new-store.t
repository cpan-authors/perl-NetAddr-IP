#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( lives );

plan skip_all => 'Storable not available'
    unless eval { require Storable; Storable->import('freeze', 'thaw'); 1 };

subtest 'require NetAddr::IP installs hooks' => sub {
    ok(lives { require NetAddr::IP; 1 }, 'require NetAddr::IP loads module');
    ok(NetAddr::IP->can('STORABLE_freeze'), 'require installs STORABLE_freeze hook');
    ok(NetAddr::IP->can('STORABLE_thaw'), 'require installs STORABLE_thaw hook');
};

subtest 'use NetAddr::IP installs hooks' => sub {
    ok(lives { use NetAddr::IP; 1 }, 'use NetAddr::IP loads module');
    ok(NetAddr::IP->can('STORABLE_freeze'), 'use installs STORABLE_freeze hook');
    ok(NetAddr::IP->can('STORABLE_thaw'), 'use installs STORABLE_thaw hook');
};

subtest 'require vs use consistency - both install hooks' => sub {
    ok(NetAddr::IP->can('STORABLE_freeze'), 'STORABLE_freeze available');
    ok(NetAddr::IP->can('STORABLE_thaw'), 'STORABLE_thaw available');
};

subtest 'new format round-trip' => sub {
    my $oip = NetAddr::IP->new('localhost');

    isa_ok($oip, ['NetAddr::IP'], 'Correct return type');

    my $serialized;
    ok(lives { $serialized = freeze($oip) }, 'Freezing');
    ok(length($serialized) > 0, 'Serialized data is not empty');

    my $nip;
    ok(lives { $nip = thaw($serialized) }, 'Thawing');

    isa_ok($nip, ['NetAddr::IP'], 'Recovered correct type');
    is("$nip", "$oip", 'New object eq original object');

    # Verify the new format uses CIDR string (compact)
    like($serialized, qr|/|, 'Serialized data contains CIDR notation');
    ok(length($serialized) < 100, 'New format is compact');
};

done_testing;
