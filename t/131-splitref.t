#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP ();

my $ip = NetAddr::IP->new('ffff:a123:b345:c789::/48');
my $rv;

subtest 'splitref with same cidr' => sub {
    ok( ( $rv = sprintf( '%s', $ip ) ) eq 'FFFF:A123:B345:C789:0:0:0:0/48',
        "$rv eq FFFF:A123:B345:C789:0:0:0:0/48" );
    my $nets = $ip->splitref(48);
    ok( $nets,       'there is a net' );
    ok( @$nets == 1, 'one item net' );
    ok( ( $rv = sprintf( '%s', $ip ) ) eq 'FFFF:A123:B345:C789:0:0:0:0/48',
        "$rv eq FFFF:A123:B345:C789:0:0:0:0/48" );
};

subtest 'splitref with multiple cidrs' => sub {
    my $nets = $ip->splitref( 49, 50 );
    ok( $nets,                 'there are nets' );
    ok( ( $rv = @$nets ) == 3, "$rv is 3 item net" );

    my @exp = qw(
      FFFF:A123:B345:0:0:0:0:0/49
      FFFF:A123:B345:8000:0:0:0:0/50
      FFFF:A123:B345:C000:0:0:0:0/50
    );

    for my $i ( 0 .. $#$nets ) {
        ok( ( $rv = sprintf( '%s', $nets->[$i] ) ) eq $exp[$i],
            "$rv eq $exp[$i]" );
    }
};

subtest q{splitting leaves the caller's $_ alone} => sub {
    my $net  = NetAddr::IP->new('192.0.2.0/30');
    my %call = (
        'array dereference' => sub { @{$net} },
        hostenum            => sub { $net->hostenum },
        hostenumref         => sub { $net->hostenumref },
        rsplit              => sub { $net->rsplit(31) },
        rsplitref           => sub { $net->rsplitref(31) },
        split               => sub { $net->split(31) },
        splitref            => sub { $net->splitref(31) },
    );
    for my $name ( sort keys %call ) {
        my @aliased = ('kept');
        for (@aliased) { my @got = $call{$name}->() }
        is( $aliased[0], 'kept',
            "$name leaves the foreach element in \$_ alone" );
    }

    my @nets   = map { NetAddr::IP->new($_) } qw(192.0.2.0/30 198.51.100.0/30);
    my @halves = map { $_->split(31) } @nets;
    is(
        [ map { "$_" } @nets ],
        [ '192.0.2.0/30', '198.51.100.0/30' ],
        'map over split keeps the source objects'
    );
    is( scalar @halves, 4, 'map over split returns both halves of each net' );
    ok(
        lives {
            for (qw(a b)) { my @got = $net->split(31) }
        },
        'split inside a foreach over a literal list lives'
    );
};

done_testing;
