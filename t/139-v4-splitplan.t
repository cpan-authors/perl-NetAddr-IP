#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies lives );

use NetAddr::IP ();

my $ip = NetAddr::IP->new('192.168.21.13/15');
my $rv;

subtest 'splitplan with same cidr' => sub {
    ok(($rv = sprintf('%s', $ip)) eq '192.168.21.13/15', "$rv eq 192.168.21.13/15");

    my ($plan, $masks) = $ip->_splitplan(15);
    ok($plan,       'there is a plan');
    ok(!$masks,     'plan returns the original net');
    ok(@$plan == 1, 'one item plan');
    ok(($rv = $plan->[0]) == 15, "plan $rv is original cidr 15");
};

subtest 'splitplan with mask containing bits' => sub {
    my $cmask = NetAddr::IP->new('255.126.0.0');
    ok(($rv = sprintf('%s', $cmask)) eq '255.126.0.0/32', "$rv eq 255.126.0.0/32");

    my ($plan, $masks) = $ip->_splitplan($cmask);
    ok(!$plan, 'failing because of bits in mask');
};

subtest 'splitplan with matching object mask' => sub {
    my $cmask = NetAddr::IP->new('255.254.0.0');
    ok(($rv = sprintf('%s', $cmask)) eq '255.254.0.0/32', "$rv eq 255.254.0.0/32");

    my ($plan, $masks) = $ip->_splitplan($cmask);
    ok($plan,       'there is a plan');
    ok(!$masks,     'plan returns the original net');
    ok(@$plan == 1, 'one item plan');
    ok(($rv = $plan->[0]) == 15, "plan $rv is original cidr 15");
};

subtest 'splitplan with text mask' => sub {
    my $cmask = '255.254.0.0';
    my ($plan, $masks) = $ip->_splitplan($cmask);
    ok($plan,       'there is a plan');
    ok(!$masks,     'plan returns the original net');
    ok(@$plan == 1, 'one item plan');
    ok(($rv = $plan->[0]) == 15, "plan $rv is original cidr 15");
};

subtest 'splitplan failing cases' => sub {
    my ($plan, $masks);

    ($plan, $masks) = $ip->_splitplan('255.126.0.0');
    ok(!$plan, 'failing because of bits in text mask');

    ($plan, $masks) = $ip->_splitplan('garbage');
    ok(!$plan, 'failing because of garbage');

    ($plan, $masks) = $ip->_splitplan(14);
    ok(!$plan, 'failing because of 15 overrange');

    like(dies { $ip->_splitplan(32) }, qr/^netlimit exceeded/, 'netlimit exceeded for 32 - 15 = 2**17');

    ($plan, $masks) = $ip->_splitplan(16, 16, 16);
    ok(!$plan, 'failing because of 3 * 16 overrange');
};

subtest 'splitplan that just fits' => sub {
    my ($plan, $masks) = $ip->_splitplan(31);
    ok($plan,                       'there is a plan 31');
    ok($masks,                      'plan has masks');
    ok(($rv = @{$plan}) == 2 ** 16, "$rv should = 65536");
};

subtest 'splitplan with netlimit' => sub {
    local $NetAddr::IP::_netlimit = 4;
    my ($plan, $masks);

    ($plan, $masks) = $ip->_splitplan(17);
    ok($plan, "plan of 4 17's");

    ($plan, $masks) = $ip->_splitplan(17, 17, 17, 17, 18);
    ok(!$plan, "plan of 4 17's + 18 is overrange, not a netlimit failure");

    like(dies { $ip->_splitplan(18) }, qr/^netlimit exceeded/, "netlimit exceeded for plan of 8 18's");

    ($plan, $masks) = $ip->_splitplan(16, 17, 18, 18);
    ok($plan, "plan of 16, 17, 18, 18 fits netlimit 4 although 8 18's would not");
    is(scalar @{$plan}, 4, 'that plan has 4 items');
};

subtest 'invalid masks return no plan' => sub {
    my ($plan, $masks);

    ($plan, $masks) = $ip->_splitplan(-24);
    ok(!$plan, '_splitplan(-24) returns no plan');

    ($plan, $masks) = $ip->_splitplan('d');
    ok(!$plan, '_splitplan(d) returns no plan');

    ($plan, $masks) = $ip->_splitplan('dd');
    ok(!$plan, '_splitplan(dd) returns no plan');
};

subtest 'invalid masks die on split' => sub {
    my @s;

    @s = eval { $ip->split(-24) };
    like($@, qr/^netmask error/, 'split(-24) dies with netmask error');
    is(scalar @s, 0, 'split(-24) returns nothing');

    @s = eval { $ip->split(28, -30) };
    like($@, qr/^netmask error/, 'split(28, -30) dies with netmask error');

    @s = eval { $ip->split('d') };
    like($@, qr/^netmask error/, 'split(d) dies with netmask error');

    @s = eval { $ip->split('dd') };
    like($@, qr/^netmask error/, 'split(dd) dies with netmask error');
};

done_testing;
