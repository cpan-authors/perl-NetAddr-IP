#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw(dies lives);
use Test2::Plugin::NoWarnings;

plan skip_all => 'LIGHTERIPTESTS = yes'
    if defined $ENV{LIGHTERIPTESTS} && $ENV{LIGHTERIPTESTS} =~ m/yes/i;

use NetAddr::IP qw( Coalesce );

package My::Sub { use parent 'NetAddr::IP'; }
package main;

my @ips;

for my $o (0 .. 255) {
    push @ips, NetAddr::IP->new("10.0.$o.1");
    push @ips, NetAddr::IP->new("10.0.$o.10");
    push @ips, NetAddr::IP->new("10.0.$o.100");
}

sub tst {
    my $r = Coalesce(24, 4, @ips);
    ref_ok($r, 'ARRAY', 'Return type from Coalesce');
    is(scalar @$r, 0, 'Empty array returned as expected');

    $r = Coalesce(24, 2, @ips);
    ref_ok($r, 'ARRAY', 'Return type from Coalesce');
    is(scalar @$r, 256, 'Whole result set as expected');
    my @c = NetAddr::IP::Compact(@$r);
    is(scalar @c, 1, 'Results are compactable');
    ok($c[0] eq '10.0.0.0/16', 'Correct results');

    $r = Coalesce(24, 2, @ips, NetAddr::IP->new('10.0.0.125/23'));
    ref_ok($r, 'ARRAY', 'Return type from Coalesce');
    ok((grep { $_ eq '10.0.0.0/23' } @$r), '/23 went through');
    @c = NetAddr::IP::Compact(@$r);
    is(scalar @c, 1, 'Results are compactable');
    ok($c[0] eq '10.0.0.0/16', 'Correct results');
}

subtest 'default imports' => sub {
    tst();
};

{
    delete $NetAddr::IP::{Coalesce};
    import NetAddr::IP qw(:old_nth);

    subtest ':old_nth imports' => sub {
        tst();
    };
}

subtest 'result order is deterministic' => sub {
    my @h;
    for my $o (0 .. 5) {
        push @h, NetAddr::IP->new("10.0.$o.$_/32") for 1 .. 3;
    }

    my $r = Coalesce(24, 2, @h);
    is(scalar @$r, 6, 'six /24 nets are returned');

    my @got = map { "$_" } @$r;
    my @exp = map { "10.0.$_.0/24" } 0 .. 5;
    is(join(',', @got), join(',', @exp), 'coalesce results are in address order');

    my $rev = Coalesce(24, 2, reverse @h);
    is(join(',', map { "$_" } @$rev), join(',', @got),
       'reversing the argument list does not change the result');

    # pass through nets and counted nets are ordered together
    $r = Coalesce(24, 2, NetAddr::IP->new('10.0.9.0/23'), @h);
    @got = map { "$_" } @$r;
    @exp = ('10.0.0.0/24', '10.0.1.0/24', '10.0.2.0/24', '10.0.3.0/24',
            '10.0.4.0/24', '10.0.5.0/24', '10.0.8.0/23');
    is(join(',', @got), join(',', @exp),
       'a pass through net is sorted in with the counted nets');
};

subtest 'coalesce counts subnet addresses, not usable hosts' => sub {
    # RFC 5737 test ranges: 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24
    my @two25 = (NetAddr::IP->new('198.51.100.0/25'), NetAddr::IP->new('198.51.100.128/25'));
    my @four26 = map { NetAddr::IP->new("203.0.113." . ($_ * 64) . "/26") } 0 .. 3;
    my @all30 = map { NetAddr::IP->new("192.0.2." . ($_ * 4) . "/30") } 0 .. 63;
    my @all32 = map { NetAddr::IP->new("203.0.113.$_/32") } 0 .. 255;

    my $r = Coalesce(24, 256, @two25);
    is(scalar @$r, 1, 'two /25 nets reach a threshold of 256');
    is("$r->[0]", '198.51.100.0/24', 'two /25 nets coalesce to 198.51.100.0/24');

    $r = Coalesce(24, 256, @four26);
    is(scalar @$r, 1, 'four /26 nets reach a threshold of 256');

    $r = Coalesce(24, 256, @all30);
    is(scalar @$r, 1, 'sixty four /30 nets reach a threshold of 256');

    $r = Coalesce(24, 256, @all32);
    is(scalar @$r, 1, 'two hundred and fifty six /32 nets reach a threshold of 256');

    $r = Coalesce(24, 256, NetAddr::IP->new('203.0.113.0/25'));
    is(scalar @$r, 0, 'one /25 net does not reach a threshold of 256');
    $r = Coalesce(24, 128, NetAddr::IP->new('192.0.2.0/25'));
    is(scalar @$r, 1, 'one /25 net reaches a threshold of 128');
    $r = Coalesce(24, 129, NetAddr::IP->new('198.51.100.0/25'));
    is(scalar @$r, 0, 'one /25 net does not reach a threshold of 129');

    $r = Coalesce(24, 257, @two25);
    is(scalar @$r, 0, 'two /25 nets do not reach a threshold of 257');
    $r = Coalesce(24, 257, @all32);
    is(scalar @$r, 0, 'two hundred and fifty six /32 nets do not reach 257');

    import NetAddr::IP qw(:old_nth);
    is($NetAddr::IP::Lite::Old_nth, 1, ':old_nth is in effect');
    $r = Coalesce(24, 256, @two25);
    is(scalar @$r, 1, 'two /25 nets reach a threshold of 256 under :old_nth');
};

subtest 'coalesce empty address list' => sub {
    my $r = Coalesce(24, 2);
    ref_ok($r, 'ARRAY', 'an empty address list gives an array ref');
    is(scalar @$r, 0, 'the result is empty');
};

subtest 'coalesce pass through nets' => sub {
    # shorter nets pass through
    my $r = Coalesce(24, 2, NetAddr::IP->new('203.0.113.9/23'));
    is(scalar @$r, 1, 'a shorter net passes through even below the threshold');
    is("$r->[0]", '203.0.112.0/23', 'a shorter net passes through as its network');

    # equal nets pass through
    $r = Coalesce(24, 1000, NetAddr::IP->new('192.0.2.9/24'));
    is(scalar @$r, 1, 'a net of exactly masklen passes through');
    is("$r->[0]", '192.0.2.0/24', 'a net of exactly masklen passes as its network');

    # a pass through net absorbs counted subnets
    my @h24 = map { NetAddr::IP->new("198.51.100.$_/32") } 1 .. 4;
    $r = Coalesce(24, 2, NetAddr::IP->new('198.51.100.0/22'), @h24);
    is(scalar @$r, 1, 'a containing pass through net absorbs a counted subnet');
    is("$r->[0]", '198.51.100.0/22', 'the containing net is the only result');

    # default route absorbs everything
    $r = Coalesce(24, 2, NetAddr::IP->new('default'), @h24);
    is(scalar @$r, 1, 'a default route pass through absorbs everything');
    is("$r->[0]", '0.0.0.0/0', 'the default route is the only result');

    # duplicate pass through nets collapse
    $r = Coalesce(24, 2, NetAddr::IP->new('203.0.113.1/23'), NetAddr::IP->new('203.0.113.5/23'));
    is(scalar @$r, 1, 'two args in the same shorter net give one result');

    # unrelated pass through nets are kept
    $r = Coalesce(24, 2, NetAddr::IP->new('192.0.2.0/23'), @h24);
    is(scalar @$r, 2, 'an unrelated pass through net is kept alongside');
};

subtest 'coalesce method form' => sub {
    my $me = NetAddr::IP->new('203.0.113.5/32');
    my $r = $me->coalesce(24, 2, NetAddr::IP->new('203.0.113.6/32'));
    is(scalar @$r, 1, 'the invocant counts towards masklen');
    is("$r->[0]", '203.0.113.0/24', 'the method call result is the containing /24');
    is(scalar @{$me->coalesce(24, 3, NetAddr::IP->new('203.0.113.6/32'))}, 0,
       'the invocant is counted once, not twice');
    my @method = map { "$_" } @{$me->coalesce(24, 2, NetAddr::IP->new('203.0.113.6/32'))};
    my @func   = map { "$_" } @{Coalesce(24, 2, $me, NetAddr::IP->new('203.0.113.6/32'))};
    is(join(',', @method), join(',', @func),
       'the method form and the function form agree');
};

subtest 'coalesce does not modify arguments' => sub {
    my @in = (NetAddr::IP->new('192.0.2.7/23'), NetAddr::IP->new('192.0.2.25/23'));
    Coalesce(24, 2, @in);
    is("$in[0]", '192.0.2.7/23', 'coalesce does not modify its first argument');
    is("$in[1]", '192.0.2.25/23', 'coalesce does not modify its second argument');

    my $me = NetAddr::IP->new('203.0.113.1/32');
    Coalesce(24, 2, $me);
    is("$me", '203.0.113.1/32', 'coalesce does not modify the invocant');
};

subtest 'coalesce IPv6' => sub {
    # RFC 3849: 2001:db8::/32
    my @h6 = map { NetAddr::IP->new6(sprintf '2001:db8::%x/128', $_) } 1 .. 4;
    my $r = Coalesce(120, 4, @h6);
    is(scalar @$r, 1, 'four v6 /128 nets in one /120 give one result');
    is("$r->[0]", '2001:DB8:0:0:0:0:0:0/120', 'the v6 result is the containing /120');
    ok($r->[0]->{isv6}, 'the v6 result is an IPv6 object');
    is(scalar @{Coalesce(120, 5, @h6)}, 0, 'a v6 threshold above the count does not fire');
    $r = Coalesce(120, 256, NetAddr::IP->new6('2001:db8::/121'),
                  NetAddr::IP->new6('2001:db8::80/121'));
    is(scalar @$r, 1, 'two v6 /121 nets count the full 256 addresses of the /120');
    $r = Coalesce(120, 2, NetAddr::IP->new6('2001:db8::/119'), @h6);
    is(scalar @$r, 1, 'a shorter v6 net absorbs the counted v6 subnet');
    is("$r->[0]", '2001:DB8:0:0:0:0:0:0/119', 'the shorter v6 net is the only result');
};

subtest 'coalesce on a subclass' => sub {
    my $base = NetAddr::IP->new('198.51.100.5/32');
    my $sub  = bless { %$base }, 'My::Sub';
    isa_ok($sub, 'NetAddr::IP');

    my $r = $sub->coalesce(24, 2, NetAddr::IP->new('198.51.100.6/32'));
    ref_ok($r, 'ARRAY', 'subclass coalesce returns an array ref');
    is(scalar @$r, 1, 'subclass coalesce counts the invocant towards number');
    is("$r->[0]", '198.51.100.0/24', 'subclass coalesce result is the containing /24');

    my $p = $base->coalesce(24, 2, NetAddr::IP->new('198.51.100.6/32'));
    is(join(',', map { "$_" } @$r), join(',', map { "$_" } @$p),
       'subclass coalesce agrees with NetAddr::IP coalesce');

    $r = $sub->coalesce(24, 2);
    is(scalar @$r, 0, 'subclass coalesce with an empty list does not fire');

    $r = $sub->coalesce(24, 1);
    is(scalar @$r, 1, 'subclass coalesce with an empty list fires at number 1');
};

subtest 'coalesce validates masklen and number' => sub {
    # RFC 5737 test ranges: 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24
    my @h = (NetAddr::IP->new('192.0.2.1/32'), NetAddr::IP->new('198.51.100.5/32'));

    like(dies { Coalesce(undef, 2, @h) }, qr/masklen must be an integer/,
	 'undef masklen croaks');
    like(dies { Coalesce(-1, 2, @h) }, qr/masklen must be an integer/,
	 'negative masklen croaks');
    like(dies { Coalesce(24.7, 2, @h) }, qr/masklen must be an integer/,
	 'fractional masklen croaks');
    like(dies { Coalesce('abc', 2, @h) }, qr/masklen must be an integer/,
	 'non numeric masklen croaks');
    like(dies { Coalesce(129, 2, @h) }, qr/masklen must be an integer/,
	 'masklen above 128 croaks');
    like(dies { Coalesce(33, 2, @h) }, qr/exceeds the 32 bits/,
	 'masklen above 32 with IPv4 croaks');

    like(dies { Coalesce(24, undef, @h) }, qr/number must be a non-negative integer/,
	 'undef number croaks');
    like(dies { Coalesce(24, -5, @h) }, qr/number must be a non-negative integer/,
	 'negative number croaks');
    like(dies { Coalesce(24, 'abc', @h) }, qr/number must be a non-negative integer/,
	 'non numeric number croaks');
    like(dies { Coalesce(24, 2, $h[0], '192.0.2.9/32') },
 qr/must be NetAddr::IP objects/,
	 'a non object in the list croaks');

    ok(lives { Coalesce(24, 0, @h) }, 'a threshold of 0 is valid');

    ok(lives { Coalesce(24, 1000, @h) }, 'a threshold above the count is valid');
};

done_testing;
