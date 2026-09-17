#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw( dies lives );
use NetAddr::IP ();

my $big = NetAddr::IP->new('10.0.0.0/8');

like(dies { $big->hostenum }, qr/^netlimit exceeded/, 'hostenum over netlimit');
like(dies { $big->hostenumref }, qr/^netlimit exceeded/, 'hostenumref over netlimit');
like(dies { $big->splitref(32) }, qr/^netlimit exceeded/, 'splitref over netlimit');
like(dies { $big->split(32) }, qr/^netlimit exceeded/, 'split over netlimit');
like(dies { $big->rsplit(24, 32) }, qr/^netlimit exceeded/, 'rsplit with mask list over netlimit');
like(dies { NetAddr::IP->new('2001:db8::/48')->split(128) }, qr/^netlimit exceeded/, 'ipv6 split over netlimit');

like(dies { NetAddr::IP->new('10.0.0.0/24')->split(16) }, qr/^netmask error/, 'shorter mask still dies with netmask error');

ok(lives { NetAddr::IP->new('10.0.0.0/16')->splitref(32) }, 'split of exactly netlimit nets succeeds');

done_testing;
