#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP;

ok( lives { require NetAddr::IP::Count; 1 }, 'NetAddr::IP::Count loads' )
  or bail_out("NetAddr::IP::Count did not load: $@");

# the NetAddr::IP objects for a list of subnets or addresses
sub ips {
    my @texts = @_;
    return map { NetAddr::IP->new($_) } @texts;
}

# a counter with the groups added in the order given, each [ name, @subnets ]
sub counter_with {
    my @groups  = @_;
    my $counter = NetAddr::IP::Count->new;
    $counter->add( $_->[0], ips( @{$_}[ 1 .. $#{$_} ] ) ) for @groups;
    return $counter;
}

# the message a croak starts with, up to the location perl appends
sub croaks_with {
    my ($message) = @_;
    return qr/\A\Q$message\E at /;
}

my @OVERLAPPING = (
    [ customers    => '198.51.100.0/24' ],
    [ 'customer-a' => '198.51.100.0/28' ],
    [ lab          => '203.0.113.0/24', '203.0.113.0/25' ],
);
my @OVERLAPPING_ADDRESSES =
  qw(198.51.100.1 198.51.100.2 198.51.100.77 198.51.100.200 203.0.113.9);

subtest 'new takes a single subnet or an array reference per group' => sub {
    my $counter = NetAddr::IP::Count->new(
        single => NetAddr::IP->new('192.0.2.0/24'),
        list   => [ ips( '198.51.100.0/24', '2001:db8::/32' ) ],
    );
    is(
        $counter->result,
        { list => 0, single => 0 },
        'every group starts at zero'
    );

    $counter->count( ips( '192.0.2.1', '2001:db8::1', '198.51.100.9' ) );
    is(
        $counter->result,
        { list => 2, single => 1 },
        'both forms of group count their addresses'
    );
};

subtest 'new called on a counter returns an empty counter of its class' => sub {
    my $counter = counter_with( [ lab => '203.0.113.0/24' ] );
    my $empty   = $counter->new;
    isa_ok( $empty, 'NetAddr::IP::Count' );
    is( $empty->result, {}, 'the new counter has no groups' );

    {

        package My::Count;
        our @ISA = ('NetAddr::IP::Count');
    }
    isa_ok( My::Count->new->new, 'My::Count' );
};

subtest 'add appends subnets to a group, as a list or an array reference' =>
  sub {
    my $counter = NetAddr::IP::Count->new;
    ref_is( $counter->add( lab => ips('203.0.113.0/25') ),
        $counter, 'add returns the counter' );
    $counter->add( lab => [ ips('203.0.113.128/25') ] );
    $counter->add('empty');
    is(
        $counter->result,
        { empty => 0, lab => 0 },
        'a group added with no subnets starts at zero too'
    );

    $counter->count( ips( '203.0.113.1', '203.0.113.200' ) );
    is(
        $counter->result,
        { empty => 0, lab => 2 },
        'both halves of lab count, and empty counts nothing'
    );
  };

subtest 'groups that do not overlap give each address to one group' => sub {
    my $counter = counter_with(
        [ 'test-00' => '192.0.2.0/25' ],
        [ 'test-01' => '192.0.2.128/25' ],
        [ 'test-02' => '198.51.100.0/24' ],
        [ 'test-03' => '203.0.113.0/26', '203.0.113.192/26' ],
    );
    my @addresses = ips(
        qw(192.0.2.100 198.51.100.1 192.0.2.5 192.0.2.3 192.0.2.1
          192.0.2.200 192.0.2.3 198.51.100.66 198.51.100.66 198.51.100.69
          203.0.113.10 203.0.113.200 203.0.113.100)
    );
    $counter->count($_) for @addresses;
    $counter->count(@addresses);
    is(
        $counter->result,
        { 'test-00' => 10, 'test-01' => 2, 'test-02' => 8, 'test-03' => 4 },
'each address counts in its own group, and one outside all counts nowhere'
    );
};

subtest 'an address counts once in every group with a subnet containing it' =>
  sub {
    my $counter = counter_with(@OVERLAPPING);
    ref_is( $counter->count( ips(@OVERLAPPING_ADDRESSES) ),
        $counter, 'count returns the counter' );
    is(
        $counter->result,
        { customers => 4, 'customer-a' => 2, lab => 1 },
'customers sees all four, and lab counts 203.0.113.9 once for two subnets'
    );
  };

subtest 'totals do not depend on the order of groups, addresses or cache' =>
  sub {
    my $forward = counter_with(@OVERLAPPING);
    $forward->count( ips(@OVERLAPPING_ADDRESSES) );

    my $backward = counter_with( reverse @OVERLAPPING );
    $backward->cache(0);
    $backward->count( ips( reverse @OVERLAPPING_ADDRESSES ) );

    is( $backward->result, $forward->result,
        'groups and addresses in reverse, with no cache, give the same totals'
    );
  };

subtest 'IPv4 and IPv6 subnets count only addresses of their own family' =>
  sub {
    my $counter = counter_with(
        [ 'all-v4' => '0.0.0.0/0' ],
        [ 'all-v6' => '::/0' ],
        [ v4       => '192.0.2.0/24' ],
        [ v6       => '2001:db8::/32' ],
    );
    $counter->count( ips( '192.0.2.1', '2001:db8::1' ) );
    is(
        $counter->result,
        { 'all-v4' => 1, 'all-v6' => 1, v4 => 1, v6 => 1 },
        'each address counts in its own family only'
    );
  };

subtest 'valcount adds each value to every group containing the address' =>
  sub {
    my $counter = counter_with(@OVERLAPPING);
    ref_is(
        $counter->valcount(
            ips('198.51.100.1')  => 5,
            ips('198.51.100.77') => '2',
            ips('203.0.113.9')   => -1,
            ips('198.51.100.2')  => 0.5,
        ),
        $counter,
        'valcount returns the counter'
    );
    is(
        $counter->result,
        { customers => 7.5, 'customer-a' => 5.5, lab => -1 },
        'values add to every matching group, once per group'
    );
  };

subtest 'result returns a copy of the totals' => sub {
    my $counter = counter_with(@OVERLAPPING);
    $counter->count( ips('198.51.100.1') );
    my $totals = $counter->result;
    $totals->{customers} = 99;
    delete $totals->{lab};
    is(
        $counter->result,
        { customers => 1, 'customer-a' => 1, lab => 0 },
        'changing the returned hash leaves the counter as it was'
    );
};

subtest 'cache returns the previous size and leaves the totals alone' => sub {
    my $counter = counter_with(@OVERLAPPING);
    is( $counter->cache,     5,  'a new counter reports a size of 5' );
    is( $counter->cache(10), 5,  'setting a size returns the previous one' );
    is( $counter->cache(-1), 10, 'a negative size is ignored' );
    is( $counter->cache(0),  10, 'a size of zero is accepted' );
    is( $counter->cache,     0,  'and is then reported' );

    $counter->count( ips(@OVERLAPPING_ADDRESSES) );
    is(
        $counter->result,
        { customers => 4, 'customer-a' => 2, lab => 1 },
        'a cache of zero counts the same as any other size'
    );
};

subtest 'count croaks on anything but a NetAddr::IP object' => sub {
    my $counter = counter_with(@OVERLAPPING);
    my %bad     = (
        'an undefined element' => [ undef,          'undefined' ],
        'a string address'     => [ '198.51.100.1', q{'198.51.100.1'} ],
        'an array reference'   => [ [ ips('198.51.100.1') ], 'ARRAY' ],
        'another class'        => [ bless( {}, 'Other' ),    'Other' ],
    );
    for my $case ( sort keys %bad ) {
        my ( $arg, $got ) = @{ $bad{$case} };
        like(
            dies { $counter->count( ips('198.51.100.1'), $arg ) },
            croaks_with(
                    'NetAddr::IP::Count::count needs a NetAddr::IP object'
                  . " for argument 2, got $got"
            ),
            "count of $case names the argument"
        );
    }
    is(
        $counter->result,
        { customers => 0, 'customer-a' => 0, lab => 0 },
        'no total changed, not even for the good address before the bad one'
    );
};

subtest 'add croaks on an undefined name or a subnet that is not an object' =>
  sub {
    my $counter = NetAddr::IP::Count->new;
    like(
        dies { $counter->add( undef, ips('192.0.2.0/24') ) },
        croaks_with('NetAddr::IP::Count::add needs a group name'),
        'an undefined name'
    );
    like(
        dies { $counter->add( lab => ips('203.0.113.0/24'), '192.0.2.0/24' ) },
        croaks_with(
                'NetAddr::IP::Count::add needs a NetAddr::IP object'
              . " for argument 3, got '192.0.2.0/24'"
        ),
        'a string subnet after a good one'
    );
    is( $counter->result, {}, 'no group was created' );
  };

subtest 'new croaks on an odd number of arguments or a bad subnet' => sub {
    like(
        dies { NetAddr::IP::Count->new('lab') },
        croaks_with(
                'NetAddr::IP::Count::new takes group name and subnet'
              . ' pairs, got 1 arguments'
        ),
        'a name with no subnets'
    );
    like(
        dies { NetAddr::IP::Count->new( lab => '203.0.113.0/24' ) },
        croaks_with(
                'NetAddr::IP::Count::add needs a NetAddr::IP object'
              . " for argument 2, got '203.0.113.0/24'"
        ),
        'a string subnet'
    );
};

subtest 'valcount croaks on bad pairs and changes no total' => sub {
    my $counter = counter_with(@OVERLAPPING);
    like(
        dies { $counter->valcount( ips('198.51.100.1') ) },
        croaks_with(
                'NetAddr::IP::Count::valcount takes address and value'
              . ' pairs, got 1 arguments'
        ),
        'an address with no value'
    );
    like(
        dies { $counter->valcount( ips('198.51.100.1') => 'five' ) },
        croaks_with(
                'NetAddr::IP::Count::valcount needs a number'
              . " for argument 2, got 'five'"
        ),
        'a value that is not a number'
    );
    like(
        dies {
            $counter->valcount( ips('198.51.100.1') => 1, '198.51.100.2' => 1 )
        },
        croaks_with(
                'NetAddr::IP::Count::valcount needs a NetAddr::IP object'
              . " for argument 3, got '198.51.100.2'"
        ),
        'a string address in the second pair'
    );
    is(
        $counter->result,
        { customers => 0, 'customer-a' => 0, lab => 0 },
        'no total changed, not even for the good first pair'
    );
};

subtest 'cache croaks on a size that is not a number' => sub {
    my $counter = NetAddr::IP::Count->new;
    like(
        dies { $counter->cache('ten') },
        croaks_with(
                'NetAddr::IP::Count::cache needs a number'
              . " for argument 1, got 'ten'"
        ),
        'a string size'
    );
    is( $counter->cache, 5, 'the size is unchanged' );
};

done_testing;
