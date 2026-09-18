#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw( dies lives );

use NetAddr::IP ();

my $ip = NetAddr::IP->new('ffff:a123:b345:c789::/48');
my $rv;

subtest 'splitplan with same cidr' => sub {
    ok(($rv = sprintf("%s", $ip)) eq 'FFFF:A123:B345:C789:0:0:0:0/48', "$rv eq FFFF:A123:B345:C789:0:0:0:0/48");

    my ($plan, $masks) = $ip->_splitplan(48);
    ok($plan,                                          'there is a plan');
    ok(!$masks,                                        'plan returns the original net');
    ok(@$plan == 1,                                    'one item plan');
    ok(($rv = $plan->[0]) == 48,                       "plan $rv is original cidr 48");
};

subtest 'splitplan with mask containing bits' => sub {
    my $cmask = NetAddr::IP->new('ffff:7fff:ffff:ffff::');
    ok(($rv = sprintf("%s", $cmask)) eq 'FFFF:7FFF:FFFF:FFFF:0:0:0:0/128', "$rv eq FFFF:7FFF:FFFF:FFFF:0:0:0:0/128");

    my ($plan, $masks) = $ip->_splitplan($cmask);
    ok(!$plan, 'failing because of bits in mask');
};

subtest 'splitplan with matching object mask' => sub {
    my $cmask = NetAddr::IP->new('FFFF:fFFF:FFFF::');
    ok(($rv = sprintf("%s", $cmask)) eq 'FFFF:FFFF:FFFF:0:0:0:0:0/128', "$rv eq FFFF:FFFF:FFFF:0:0:0:0:0/128");

    my ($plan, $masks) = $ip->_splitplan($cmask);
    ok($plan,       'there is a plan');
    ok(!$masks,     'plan returns the original net');
    ok(@$plan == 1, 'one item plan');
    ok(($rv = $plan->[0]) == 48, "plan $rv is original cidr 48");
};

subtest 'splitplan with text mask' => sub {
    my $cmask = 'FFFF:FFFF:FFFF::';
    my ($plan, $masks) = $ip->_splitplan($cmask);
    ok($plan,       'there is a plan');
    ok(!$masks,     'plan returns the original net');
    ok(@$plan == 1, 'one item plan');
    ok(($rv = $plan->[0]) == 48, "plan $rv is original cidr 48");
};

subtest 'splitplan failing cases' => sub {
    my ($plan, $masks);

    ($plan, $masks) = $ip->_splitplan('FFFF:FFF:FFFF::');
    ok(!$plan, 'failing because of bits in text mask');

    ($plan, $masks) = $ip->_splitplan('garbage');
    ok(!$plan, 'failing because of garbage');

    ($plan, $masks) = $ip->_splitplan(47);
    ok(!$plan, 'failing because of 47 overrange');

    like(dies { $ip->_splitplan(65) }, qr/^netlimit exceeded/, 'netlimit exceeded for 65-48 = 2**17');

    ($plan, $masks) = $ip->_splitplan(49, 49, 49);
    ok(!$plan, 'failing because of 3 * 49 overrange');
};

subtest 'splitplan that just fits' => sub {
    my ($plan, $masks) = $ip->_splitplan(64);
    ok($plan,                       'there is a plan 64');
    ok($masks,                      'plan has masks');
    ok(($rv = @{$plan}) == 2 ** 16, "$rv should = 65536");
};

subtest 'splitplan with netlimit' => sub {
    local $NetAddr::IP::_netlimit = 4;
    my ($plan, $masks);

    ($plan, $masks) = $ip->_splitplan(50);
    ok($plan, "plan of 4 50's");

    ($plan, $masks) = $ip->_splitplan(50, 50, 50, 50, 51);
    ok(!$plan, "plan of 4 50's + 51 is overrange, not a netlimit failure");

    like(dies { $ip->_splitplan(51) }, qr/^netlimit exceeded/, "netlimit exceeded for plan of 8 51's");

    ($plan, $masks) = $ip->_splitplan(49, 50, 51, 51);
    ok($plan, "plan of 49, 50, 51, 51 fits netlimit 4 although 8 51's would not");
    is(scalar @{$plan}, 4, 'that plan has 4 items');
};

done_testing;
