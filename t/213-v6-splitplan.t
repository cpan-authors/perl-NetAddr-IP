#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies lives );

use NetAddr::IP ();

my $ip = NetAddr::IP->new('ffff:a123:b345:c789::/48');
my $rv;

subtest 'splitplan with same cidr' => sub {
    ok( ($rv = sprintf("%s", $ip)) eq 'FFFF:A123:B345:C789:0:0:0:0/48',
        "$rv eq FFFF:A123:B345:C789:0:0:0:0/48"
    );

    my ($plan, $masks) = $ip->_splitplan(48);
    ok($plan,                    'there is a plan');
    ok(!$masks,                  'plan returns the original net');
    ok(@$plan == 1,              'one item plan');
    ok(($rv = $plan->[0]) == 48, "plan $rv is original cidr 48");
};

subtest 'splitplan with mask containing bits' => sub {
    my $cmask = NetAddr::IP->new('ffff:7fff:ffff:ffff::');
    ok( ($rv = sprintf("%s", $cmask)) eq 'FFFF:7FFF:FFFF:FFFF:0:0:0:0/128',
        "$rv eq FFFF:7FFF:FFFF:FFFF:0:0:0:0/128"
    );

    my ($plan, $masks) = $ip->_splitplan($cmask);
    ok(!$plan, 'failing because of bits in mask');
};

subtest 'splitplan with matching object mask' => sub {
    my $cmask = NetAddr::IP->new('FFFF:fFFF:FFFF::');
    ok( ($rv = sprintf("%s", $cmask)) eq 'FFFF:FFFF:FFFF:0:0:0:0:0/128',
        "$rv eq FFFF:FFFF:FFFF:0:0:0:0:0/128"
    );

    my ($plan, $masks) = $ip->_splitplan($cmask);
    ok($plan,                    'there is a plan');
    ok(!$masks,                  'plan returns the original net');
    ok(@$plan == 1,              'one item plan');
    ok(($rv = $plan->[0]) == 48, "plan $rv is original cidr 48");
};

subtest 'splitplan with text mask' => sub {
    my $cmask = 'FFFF:FFFF:FFFF::';
    my ($plan, $masks) = $ip->_splitplan($cmask);
    ok($plan,                    'there is a plan');
    ok(!$masks,                  'plan returns the original net');
    ok(@$plan == 1,              'one item plan');
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

    like(
        dies { $ip->_splitplan(65) },
        qr/^netlimit exceeded/,
        'netlimit exceeded for 65-48 = 2**17'
    );

    ($plan, $masks) = $ip->_splitplan(49, 49, 49);
    ok(!$plan, 'failing because of 3 * 49 overrange');
};

subtest 'splitplan that just fits' => sub {
    my ($plan, $masks) = $ip->_splitplan(64);
    ok($plan,                     'there is a plan 64');
    ok($masks,                    'plan has masks');
    ok(($rv = @{$plan}) == 2**16, "$rv should = 65536");
};

subtest 'splitplan with netlimit' => sub {
    local $NetAddr::IP::netlimit = 2;
    my ($plan, $masks);

    ($plan, $masks) = $ip->_splitplan(50);
    ok($plan, "plan of 4 50's");

    ($plan, $masks) = $ip->_splitplan(50, 50, 50, 50, 51);
    ok(!$plan, "plan of 4 50's + 51 is overrange, not a netlimit failure");

    like(
        dies { $ip->_splitplan(51) },
        qr/^netlimit exceeded/,
        "netlimit exceeded for plan of 8 51's"
    );

    ($plan, $masks) = $ip->_splitplan(49, 50, 51, 51);
    ok( $plan,
        "plan of 49, 50, 51, 51 fits netlimit 4 although 8 51's would not"
    );
    is(scalar @{$plan}, 4, 'that plan has 4 items');
};

subtest 'splitplan 54 or more bits below the base mask' => sub {
    my $ip64 = NetAddr::IP->new('2001:db8::/64');
    my $all  = NetAddr::IP->new('::/0');

    like(
        dies { $ip64->_splitplan(120, 65) },
        qr/^netlimit exceeded/,
        'netlimit exceeded for one 120 then 65s'
    );
    like(
        dies { $all->_splitplan(128, 1) },
        qr/^netlimit exceeded/,
        'netlimit exceeded for one 128 then 1s'
    );
    like(
        dies { $all->_splitplan(54, 1) },
        qr/^netlimit exceeded/,
        'netlimit exceeded for one 54 then 1s'
    );

    my ($plan, $masks) = $ip64->_splitplan(120, reverse 65 .. 120);
    is(scalar @{$plan}, 57, 'one 120 then 120 down to 65 is a 57 item plan');
    is($plan->[-1],     65, 'that plan ends with a 65');

    ($plan, $masks) = $all->_splitplan(1 .. 128, 128);
    is( scalar @{$plan},
        129, '1 to 128 then one more 128 fills ::/0 in 129 items'
    );
    is([ @{$plan}[ -2, -1 ] ], [ 128, 128 ], 'that plan ends with two 128s');
};

subtest 'splitplan 54 or more bits deep, last mask does not fit' => sub {
    my $ip64 = NetAddr::IP->new('2001:db8::/64');
    my @bits = (120, 120, reverse(67 .. 119), 65);

    my ($plan, $masks) = $ip64->_splitplan(@bits);
    is(scalar @{$plan}, 58, 'a second 65 does not fit, so two 67s follow');
    is( [ @{$plan}[ -3 .. -1 ] ],
        [ 65, 67, 67 ],
        'that plan ends with a 65 and two 67s'
    );

    like(
        dies { $ip64->split(@bits) },
        qr{^netmask error: the piece 2001:DB8:0:0:4000:0:0:0/65 does not start on its own boundary; },
        'that split croaks, since its 65 starts at 2**62'
    );

    my @nets = $ip64->split(65 .. 120, 120);
    is(scalar @nets, 57, 'the same depth largest first splits into 57');
    is( "$nets[-1]",
        '2001:DB8:0:0:FFFF:FFFF:FFFF:FF00/120',
        'the last piece of that split ends the /64'
    );
};

done_testing;
