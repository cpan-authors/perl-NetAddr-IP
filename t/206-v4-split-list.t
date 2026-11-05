#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP ();

my %addr = (
    '192.0.2.10' => [
        '255.255.252.0', 24,
        [ '192.0.0.0', '192.0.1.0', '192.0.2.0', '192.0.3.0' ],
    ],
    '192.0.2.1' => [ '255.255.255.254', 32, [ '192.0.2.0', '192.0.2.1' ], ],
    '192.0.2.2' => [ '255.255.255.255', 32, ['192.0.2.2'], ],
    '192.0.2.3' => [
        '255.255.255.252', 32,
        [ '192.0.2.0', '192.0.2.1', '192.0.2.2', '192.0.2.3' ],
    ],
);

for my $input ( sort keys %addr ) {
    my $ip = NetAddr::IP->new( $input, $addr{$input}->[0] );
    my @r  = $ip->split( $addr{$input}->[1] );
    my @m;

    is(
        scalar @r,
        scalar @{ $addr{$input}->[2] },
        "number of splits for $input",
    );

    for my $r (@r) {
        push @m, grep { $_ eq $r->addr } @{ $addr{$input}->[2] };
    }

    is( scalar @m, scalar @r, "match splits for $input", );
}

subtest 'a plan from the largest piece to the smallest gives aligned pieces' =>
  sub {
    my $ip    = NetAddr::IP->new('192.0.2.0/24');
    my %plans = (
        'split(25, 27)' => [
            [ $ip->split( 25, 27 ) ],
            [
                qw(192.0.2.0/25 192.0.2.128/27 192.0.2.160/27 192.0.2.192/27 192.0.2.224/27)
            ],
        ],
        'rsplit(25, 27)' => [
            [ $ip->rsplit( 25, 27 ) ],
            [
                qw(192.0.2.0/27 192.0.2.32/27 192.0.2.64/27 192.0.2.96/27 192.0.2.128/25)
            ],
        ],
        'split(26, 26, 26, 25), the 25 filled by a 26' => [
            [ $ip->split( 26, 26, 26, 25 ) ],
            [qw(192.0.2.0/26 192.0.2.64/26 192.0.2.128/26 192.0.2.192/26)],
        ],
    );
    for my $name ( sort keys %plans ) {
        my ( $pieces, $expected ) = @{ $plans{$name} };
        is( [ map { "$_" } @{$pieces} ], $expected, "$name gives its pieces" );
        is( [ grep { $_->addr ne $_->network->addr } @{$pieces} ],
            [], "every piece of $name starts on its own boundary" );
    }
  };

subtest 'a plan that puts a piece off its own boundary croaks' => sub {
    my %plans = (
        '192.0.2.0/28 split(30, 29)' =>
          [ '192.0.2.0/28', 'split', [ 30, 29 ], '192.0.2.4/29' ],
        '192.0.2.0/28 splitref(30, 29)' =>
          [ '192.0.2.0/28', 'splitref', [ 30, 29 ], '192.0.2.4/29' ],
        '192.0.2.0/24 split(26, 25)' =>
          [ '192.0.2.0/24', 'split', [ 26, 25 ], '192.0.2.64/25' ],
        '192.0.2.0/24 split(28, 29, 28, 29, 26)' =>
          [ '192.0.2.0/24', 'split', [ 28, 29, 28, 29, 26 ], '192.0.2.24/28' ],
        '192.0.2.0/24 rsplit(28, 29, 28, 29, 26)' =>
          [ '192.0.2.0/24', 'rsplit', [ 28, 29, 28, 29, 26 ], '192.0.2.16/26' ],
    );
    for my $name ( sort keys %plans ) {
        my ( $cidr, $method, $plan, $piece ) = @{ $plans{$name} };
        like(
            dies { NetAddr::IP->new($cidr)->$method( @{$plan} ) },
qr{^netmask error: the piece \Q$piece\E does not start on its own boundary; order the split plan from the largest piece to the smallest at },
            "$name croaks naming $piece"
        );
    }
};

done_testing;
