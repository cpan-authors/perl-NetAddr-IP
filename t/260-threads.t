#!/usr/bin/env perl

# Several ithreads run the same battery of Util functions and NetAddr::IP
# methods at once, and every result must match the single-threaded one.
# The module-wide settings are per interpreter: a thread inherits them when
# it starts, and a change made afterwards stays in the thread that made it.

use strict;
use warnings;
use Config;

BEGIN {
    unless ( $Config{useithreads} ) {
        print "1..0 # SKIP this perl was built without ithreads\n";
        exit 0;
    }
}

use threads;
use threads::shared;
use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );
use Tie::Scalar;

use NetAddr::IP;
use NetAddr::IP::Util qw(
  add128
  addconst
  bcd2bin
  bcdn2bin
  bin2bcd
  comp128
  hasbits
  ipanyto6
  ipv4to6
  ipv6_aton
  ipv6_n2x
  mask4to6
  notcontiguous
  shiftleft
  simple_pack
  sub128
);

my $THREADS          = 4;
my $ROUNDS           = 50;
my $READERS          = 3;
my $READS_PER_READER = 500;
my $RAISED_NETLIMIT  = 17;
my $V6_TEXT          = '2001:db8::ab';
my $V6_UPPER         = '2001:DB8:0:0:0:0:0:AB/128';
my $V6_LOWER         = '2001:db8:0:0:0:0:0:ab/128';

# every result the battery produces, as printable text
sub battery {
    my $packed = ipv6_aton('2001:db8::ff');
    my $mask   = ipv6_aton('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00');
    tie my $tied, 'Tie::StdScalar';
    $tied = $packed;
    my $net = NetAddr::IP->new('192.0.2.0/28');
    my $compact =
      NetAddr::IP::compactref(
        [ map { NetAddr::IP->new("192.0.2.$_/32") } 0 .. 15 ] );
    return [
        ipv6_n2x( ( add128( $packed, $packed ) )[1] ),
        ipv6_n2x( ( sub128( $packed, $packed ) )[1] ),
        ipv6_n2x( ( addconst( $packed, 7 ) )[1] ),
        ipv6_n2x( shiftleft( $packed, 3 ) ),
        ipv6_n2x( comp128($packed) ),
        hasbits($tied),
        bin2bcd($packed),
        ipv6_n2x( bcd2bin('12345678901234567890') ),
        ipv6_n2x( bcdn2bin( simple_pack('987654321'), 9 ) ),
        join( ',', notcontiguous($mask) ),
        ipv6_n2x( ipv4to6( pack 'C4', 192, 0, 2, 1 ) ),
        ipv6_n2x( mask4to6( pack 'C4', 255, 255, 255, 0 ) ),
        ipv6_n2x( ipanyto6( pack 'C4', 198, 51, 100, 7 ) ),
        join( ',', map { "$_" } $net->split(30) ),
        scalar( $net->hostenum ),
        "" . $net->numeric,
        NetAddr::IP->new6('2001:db8::1:0:0:1')->short,
        NetAddr::IP->new($V6_TEXT)->canon,
        "" . ( $net + 5 ),
        NetAddr::IP->new('198.51.100.0/24')
          ->contains( NetAddr::IP->new('198.51.100.7') ) ? 1 : 0,
        join( ',', map { "$_" } @{$compact} ),
    ];
}

subtest 'results in several threads match the single-threaded ones' => sub {
    my $want    = battery();
    my @workers = map {
        threads->create(
            sub {
                my @mismatch;
                for my $round ( 1 .. $ROUNDS ) {
                    my $got = battery();
                    for my $i ( 0 .. $#{$want} ) {
                        push @mismatch, "round $round item $i: $got->[$i]"
                          if $got->[$i] ne $want->[$i];
                    }
                }
                return join "\n", @mismatch;
            }
        )
    } 1 .. $THREADS;
    for my $worker (@workers) {
        my $tid = $worker->tid;
        is( $worker->join, q{},
            "thread $tid matches the single-threaded results" );
    }
};

subtest 'a case change in one thread stays in that thread' => sub {
    my $stop : shared = 0;
    my $flipper = threads->create(
        sub {
            my $flips = 0;
            until ($stop) {
                $flips++ % 2
                  ? NetAddr::IP::Util::upper()
                  : NetAddr::IP::Util::lower();
            }
            return $flips;
        }
    );
    my @readers = map {
        threads->create(
            sub {
                return
                  scalar grep { "" . NetAddr::IP->new($V6_TEXT) ne $V6_UPPER }
                  1 .. $READS_PER_READER;
            }
        )
    } 1 .. $READERS;
    my @changed = map { $_->join } @readers;
    $stop = 1;
    ok( $flipper->join > 0, 'the flipping thread changed the case setting' );
    is( \@changed, [ (0) x $READERS ], 'no other thread saw the change' );
};

subtest 'a thread inherits the settings in force when it starts' => sub {
    NetAddr::IP::Util::lower();
    my $child =
      threads->create( sub { return "" . NetAddr::IP->new($V6_TEXT) } );
    NetAddr::IP::Util::upper();
    is( $child->join, $V6_LOWER,
        'the thread started after lower() prints lowercase' );
    is( "" . NetAddr::IP->new($V6_TEXT),
        $V6_UPPER, 'the main thread is back to uppercase' );
};

subtest 'netlimit raised in a thread does not change the caller' => sub {
    my $raiser =
      threads->create( sub { return NetAddr::IP::netlimit($RAISED_NETLIMIT) } );
    ok( $raiser->join, 'the thread raised its netlimit' );
    like(
        dies { NetAddr::IP->new('2001:db8::/111')->split(128) },
        qr/netlimit exceeded/,
        'the main thread still has the default netlimit'
    );
};

done_testing;
