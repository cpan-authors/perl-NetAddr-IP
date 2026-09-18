#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP qw( Compact );

plan skip_all => 'LIGHTERIPTESTS = yes'
    if defined $ENV{LIGHTERIPTESTS} && $ENV{LIGHTERIPTESTS} =~ /yes/i;

my @r = (
    ['10.0.0.0', '255.255.255.0'],
    ['11.0.0.0', '255.255.255.0'],
    ['12.0.0.0', '255.255.255.0'],
    ['20.0.0.0', '255.255.0.0'],
    ['30.0.0.0', '255.255.0.0'],
    ['40.0.0.0', '255.255.0.0'],
);

my @ips1;

for my $ip ('10.0.0.0', '11.0.0.0', '12.0.0.0') {
    push @ips1, NetAddr::IP->new($ip, 24)->split(32);
}

for my $ip ('20.0.0.0', '30.0.0.0', '40.0.0.0') {
    push @ips1, NetAddr::IP->new($ip, 16)->split(28);
}

my @ips1_compact = map { NetAddr::IP->new(@$_)->cidr } @r;

# every host address in 192.0.2.0/24
my @hosts = map { NetAddr::IP->new("192.0.2.$_") } 0 .. 255;

# the four ways to call compact, each returning an array reference
my %compact_call = (
    '->compact(@list)'     => sub { [ shift->compact(@_) ] },
    '->compactref(\@list)' => sub { shift->compactref( [@_] ) },
    'Compact(@list)'       => sub { [ Compact(@_) ] },
    'Compact(\@list)'      => sub { Compact( [@_] ) },
);

for my $form ( sort keys %compact_call ) {
    subtest $form => sub {
        my $call = $compact_call{$form};
        is( [ map { $_->cidr } @{ $call->(@ips1) } ],
            \@ips1_compact, "$form merges the split nets back" );
        is( [ map { $_->cidr } @{ $call->(@hosts) } ],
            ['192.0.2.0/24'], "$form merges 256 hosts into one /24" );
    };
}

subtest 'subclass compactref' => sub {
    @My::Sub::ISA = ('NetAddr::IP');

    my $base = NetAddr::IP->new('192.0.2.0/29');
    my $sub  = bless { %$base }, 'My::Sub';
    isa_ok($sub, 'NetAddr::IP');

    my $r = $sub->compactref([ NetAddr::IP->new('203.0.113.0/24') ]);
    is(ref $r, 'ARRAY', 'subclass compactref returns an array ref');
    is(scalar @$r, 2, 'subclass compactref returns invocant plus the one list item');
    is(join(' ', map { "$_" } @$r), '192.0.2.0/29 203.0.113.0/24',
      'subclass compactref result is the invocant and the list item');

    # the same call on the parent class, for comparison
    my $p = $base->compactref([ NetAddr::IP->new('203.0.113.0/24') ]);
    is(join(' ', map { "$_" } @$p), join(' ', map { "$_" } @$r),
      'subclass compactref agrees with NetAddr::IP compactref');

    # non-adjacent nets given through the list are kept separate
    $r = $sub->compactref([ NetAddr::IP->new('198.51.100.0/29') ]);
    is(scalar @$r, 2, 'subclass compactref keeps non-adjacent nets separate');
    is(join(' ', map { "$_" } @$r), '192.0.2.0/29 198.51.100.0/29',
      'subclass compactref non-adjacent nets are unchanged');

    # ->compact(@list) on a subclass
    my @c = $sub->compact(NetAddr::IP->new('198.51.100.0/29'));
    is(join(' ', map { "$_" } @c), '192.0.2.0/29 198.51.100.0/29',
      'subclass compact keeps non-adjacent nets separate');
};

subtest 'duplicate IP' => sub {
    my @dup;
    for my $ip (qw(198.51.100.111 198.51.100.111 198.51.100.111 198.51.100.111)) {
        push @dup, NetAddr::IP->new($ip);
    }
    my @c = NetAddr::IP::compact(@dup);
    ok(@c == 1 && $c[0]->cidr() eq '198.51.100.111/32', 'duplicate IP compacts to single /32');
};

subtest 'mixed v4/v6' => sub {
    # Compact must not merge IPv4 with IPv6 objects
    my $v4 = NetAddr::IP->new('192.0.2.0/24');
    my $v6 = NetAddr::IP->new6('2001:db8::100/120');

    my @r = Compact($v4, $v6);
    is(scalar @r, 2, 'Compact keeps a v4 and a v6 net apart');
    is("$r[0]", '192.0.2.0/24', 'Compact mixed: v4 net is returned unchanged');
    is("$r[1]", '2001:DB8:0:0:0:0:0:100/120', 'Compact mixed: v6 net is returned unchanged');
    ok(!$r[0]->{isv6}, 'Compact mixed: first result is v4');
    ok($r[1]->{isv6}, 'Compact mixed: second result is v6');

    # each family merges within itself
    @r = Compact(
        NetAddr::IP->new('2001:db8::/33'),
        NetAddr::IP->new('192.0.2.0/25'),
        NetAddr::IP->new('2001:db8:8000::/33'),
        NetAddr::IP->new('192.0.2.128/25'),
    );
    is(scalar @r, 2, 'Compact mixed: each family merges within itself');
    is("$r[0]", '192.0.2.0/24', 'Compact mixed: v4 halves merge to /24');
    is("$r[1]", '2001:DB8:0:0:0:0:0:0/32', 'Compact mixed: v6 halves merge to /32');
};

subtest 'argument preservation' => sub {
    # input objects are left alone
    my @in = (NetAddr::IP->new('192.0.2.0/25'), NetAddr::IP->new('192.0.2.128/25'));
    my @out = Compact(@in);
    is("$in[0]", '192.0.2.0/25', 'Compact does not modify its first argument');
    is("$in[1]", '192.0.2.128/25', 'Compact does not modify its second argument');
    is(scalar @out, 1, 'Compact merges the two adjacent /25 nets');
    is("$out[0]", '192.0.2.0/24', 'Compact merged result is 192.0.2.0/24');

    # compactref does not modify the invocant
    my $me = NetAddr::IP->new('192.0.2.33/27');
    my $ref = $me->compactref([ NetAddr::IP->new('192.0.2.65/27') ]);
    is("$me", '192.0.2.33/27', 'compactref does not modify the invocant');
    is(scalar @$ref, 2, 'compactref returns the two non-adjacent nets');
};

done_testing;
