#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( lives );

plan skip_all => 'Storable not available'
    unless eval { require Storable; Storable->import('freeze', 'thaw'); 1 };

subtest 'require NetAddr::IP installs hooks' => sub {
    ok(lives { require NetAddr::IP; 1 }, 'require NetAddr::IP loads module');
    ok( NetAddr::IP->can('STORABLE_freeze'),
        'require installs STORABLE_freeze hook'
    );
    ok( NetAddr::IP->can('STORABLE_thaw'),
        'require installs STORABLE_thaw hook'
    );
};

subtest 'use NetAddr::IP installs hooks' => sub {
    ok(lives { use NetAddr::IP; 1 }, 'use NetAddr::IP loads module');
    ok( NetAddr::IP->can('STORABLE_freeze'),
        'use installs STORABLE_freeze hook'
    );
    ok(NetAddr::IP->can('STORABLE_thaw'), 'use installs STORABLE_thaw hook');
};

subtest 'require vs use consistency - both install hooks' => sub {
    ok(NetAddr::IP->can('STORABLE_freeze'), 'STORABLE_freeze available');
    ok(NetAddr::IP->can('STORABLE_thaw'),   'STORABLE_thaw available');
};

subtest 'new format round-trip' => sub {
    my $oip = NetAddr::IP->new('localhost');

    isa_ok($oip, ['NetAddr::IP'], 'Correct return type');

    my $serialized;
    ok(lives { $serialized = freeze($oip) }, 'Freezing');
    ok(length($serialized) > 0,              'Serialized data is not empty');

    my $nip;
    ok(lives { $nip = thaw($serialized) }, 'Thawing');

    isa_ok($nip, ['NetAddr::IP'], 'Recovered correct type');
    is("$nip", "$oip", 'New object eq original object');

    # Verify the new format uses CIDR string (compact)
    like($serialized, qr|/|, 'Serialized data contains CIDR notation');
    ok(length($serialized) < 100, 'New format is compact');
};

subtest 'data frozen as a plain hash thaws with the hooks in place' => sub {
    my $oip = NetAddr::IP->new('192.0.2.1/24');

    my $serialized = do {
        no warnings 'once';

        # with the freeze hook hidden, Storable writes the plain hash
        local *NetAddr::IP::STORABLE_freeze;
        freeze($oip);
    };
    unlike(
        $serialized, qr|/|,
        'Data frozen as a plain hash holds no CIDR string'
    );
    ok( NetAddr::IP->can('STORABLE_freeze'),
        'STORABLE_freeze is back after the block'
    );

    ok( NetAddr::IP->can('STORABLE_thaw'),
        'STORABLE_thaw is in place for the thaw'
    );
    my $nip;
    ok( lives { $nip = thaw($serialized) },
        'Thawing data frozen as a plain hash'
    );
    is("$nip", '192.0.2.1/24', 'Thawed object eq original object');
};

# a subclass that keeps keys of its own beside addr, mask and isv6
{

    package Local::Labelled;
    our @ISA = ('NetAddr::IP');
}

subtest 'a subclass object keeps its own keys through Storable' => sub {
    my $oip = bless { %{ NetAddr::IP->new('192.0.2.1/24') }, label => 'edge', tags => ['core'] },
        'Local::Labelled';
    for my $case (
        [ 'freeze and thaw' => sub { thaw(freeze($_[0])) } ],
        [ 'dclone'          => sub { Storable::dclone($_[0]) } ],
    ) {
        my ($how, $copy) = @{$case};
        my $nip = $copy->($oip);
        isa_ok($nip, ['Local::Labelled'], "$how keeps the subclass");
        is("$nip",                '192.0.2.1/24',                  "$how keeps the address and mask");
        is($nip->{label},         'edge',                          "$how keeps a subclass key holding text");
        is($nip->{tags},          ['core'],                        "$how keeps a subclass key holding a reference");
        is([ sort keys %{$nip} ], [qw(addr isv6 label mask tags)], "$how adds no keys");
    }
};

subtest 'a plain object freezes as its CIDR text alone' => sub {
    is( [ NetAddr::IP->new('192.0.2.1/24')->STORABLE_freeze(0) ],
        ['192.0.2.1/24'], 'the freeze hook of an IPv4 object returns only its CIDR text'
    );
    is( [ NetAddr::IP->new('2001:db8::1/64')->STORABLE_freeze(0) ],
        ['2001:DB8:0:0:0:0:0:1/64'], 'the freeze hook of an IPv6 object returns only its CIDR text'
    );
};

subtest 'data frozen as CIDR text alone still thaws' => sub {

    # nfreeze output of 4.080_09, whose hooks froze only the CIDR text
    my $plain    = pack 'H*', '050b13020b4e6574416464723a3a49500c3139322e302e322e312f3234';
    my $labelled = pack 'H*',
        '050b13020f4c6f63616c3a3a4c6162656c6c656417323030313a4442383a303a303a303a303a303a312f3634';

    my $nip = thaw($plain);
    isa_ok($nip, ['NetAddr::IP'], 'a plain object frozen as CIDR text thaws as NetAddr::IP');
    is("$nip",                '192.0.2.1/24',       'a plain object frozen as CIDR text keeps its address and mask');
    is([ sort keys %{$nip} ], [qw(addr isv6 mask)], 'a plain object frozen as CIDR text gains no keys');

    $nip = thaw($labelled);
    isa_ok($nip, ['Local::Labelled'], 'a subclass object frozen as CIDR text keeps its subclass');
    is("$nip", '2001:DB8:0:0:0:0:0:1/64', 'a subclass object frozen as CIDR text keeps its address and mask');
};

done_testing;
