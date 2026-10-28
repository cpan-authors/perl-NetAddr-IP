#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Mock;

use NetAddr::IP::Lite ();

my @ranges = (
    [ '10.0.0.0/8',     '10.0.0.0',    '10.255.255.255' ],
    [ '192.168.0.0/16', '192.168.0.0', '192.168.255.255' ],
);

my @weird = ( [ '128.111.12.0', '128.111.12.129' ], );

subtest 'IP ranges' => sub {
    for my $r (@ranges) {
        my $r1 = NetAddr::IP::Lite->new( $r->[1] . '-' . $r->[2] );
        isa_ok( $r1, 'NetAddr::IP::Lite' );
        is( $r1, $r->[0], 'Correct interpretation (with space)' );

        $r1 = NetAddr::IP::Lite->new( $r->[1] . ' - ' . $r->[2] );
        isa_ok( $r1, 'NetAddr::IP::Lite' );
        is( $r1, $r->[0], 'Correct interpretation (w/o space)' );

        $r1 = NetAddr::IP::Lite->new( $r->[0] );
        isa_ok( $r1, 'NetAddr::IP::Lite' );
        is( $r1->range, $r->[1] . ' - ' . $r->[2], 'Correct reverse' );
    }
};

subtest 'Weird ranges' => sub {
    for my $r (@weird) {
        my $r1 = NetAddr::IP::Lite->new( $r->[0] . '-' . $r->[1] );
        ok( !defined $r1, 'Weird range w/o space produces undef' );
        $r1 = NetAddr::IP::Lite->new( $r->[0] . ' - ' . $r->[1] );
        ok( !defined $r1, 'Weird range with space produces undef' );
    }
};

subtest 'Weird octet offsets' => sub {
    for my $o ( 254, 252, 248, 240, 224, 192, 128 ) {
        my $r1 = NetAddr::IP::Lite->new( '0.0.0.0 - ' . $o . '.0.0.0' );
        ok( !defined $r1, "Weird $o range, first octet" );
        $r1 = NetAddr::IP::Lite->new( '0.0.0.0 - 0.' . $o . '.0.0' );
        ok( !defined $r1, "Weird $o range, second octet" );
        $r1 = NetAddr::IP::Lite->new( '0.0.0.0 - 0.0.' . $o . '.0' );
        ok( !defined $r1, "Weird $o range, third octet" );
        $r1 = NetAddr::IP::Lite->new( '0.0.0.0 - 0.0.0.' . $o );
        ok( !defined $r1, "Weird $o range, fourth octet" );
    }
};

# the text, or undef when the constructor refuses it
sub made {
    my ( $method, @args ) = @_;
    my $ip = NetAddr::IP::Lite->$method(@args);
    return defined $ip ? $ip->cidr : undef;
}

subtest 'a range bound or a negative number with a leading zero is refused by new' => sub {
    for my $text (
        '10-011',        '192.0-03.',        '192.0.2-02',       '192.0.2-02.',
        '192.0.2.8-011', '198.51.100.0-0255', '192.0.2.8-011/32', '192.0.2.8-011 32',
        '-012',          '-012/32',          '-012 32',
      )
    {
        for my $method (qw( new new6 )) {
            is( made( $method, $text ), undef, "->$method('$text')" );
        }
    }
    my %cidr = (
        '-12'          => '255.255.255.244/32',
        '10-11'        => '10.0.0.0/7',
        '192.0-3.'     => '192.0.0.0/14',
        '192.0.2-2'    => '192.0.2.0/24',
        '192.0.2.8-11' => '192.0.2.8/30',
        '192.0.2.0-0'  => '192.0.2.0/32',
    );
    for my $text ( sort keys %cidr ) {
        is( made( 'new', $text ), $cidr{$text}, "->new('$text')" );
    }
};

subtest 'new_no reads a range bound or a negative number with a leading zero as decimal' => sub {
    my %cidr = (
        '-012'               => '255.255.255.244/32',
        '-012/host'          => '255.255.255.244/32',
        '10-011'             => '10.0.0.0/7',
        '192.0.2.8-011'      => '192.0.2.8/30',
        '192.0.2.8-011/host' => '192.0.2.8/30',
    );
    for my $text ( sort keys %cidr ) {
        is( made( 'new_no', $text ), $cidr{$text}, "->new_no('$text')" );
    }
};

subtest 'text that only looks like a range with a leading zero is still looked up' => sub {
    # new6 asks naip_gethostbyname before anything else, so nothing reaches the real resolver
    my @asked;
    my $mock = Test2::Mock->new(
        class    => 'NetAddr::IP::Lite',
        override => [
            havegethostbyname2 => sub { 1 },
            naip_gethostbyname => sub {
                push @asked, $_[0];
                return $_[0] eq '555-0123'
                  ? pack( 'n8', 0x2001, 0x0db8, 0, 0, 0, 0, 0, 0x55 )
                  : undef;
            },
        ],
    );
    is( made( 'new6', '555-0123' ), '2001:DB8:0:0:0:0:0:55/128',
        "->new6('555-0123') is the name's address" );
    is( \@asked, ['555-0123'], 'the name was looked up once' );
};

done_testing;
