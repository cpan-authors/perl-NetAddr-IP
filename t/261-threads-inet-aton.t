#!/usr/bin/env perl

# gethostbyname keeps one static buffer. inet_aton packs a literal
# itself, so threads parsing addresses at once keep their own answers.

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
use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP;

my $THREADS = 4;
my $ROUNDS  = 50;
my $WANT    = '1 192.0.2.0/28';

# contains and compactref on objects built from literal text. A single
# thread is the reference the workers have to match.
sub once {
    my $contains =
      NetAddr::IP->new('198.51.100.0/24')
      ->contains( NetAddr::IP->new('198.51.100.7') ) ? 1 : 0;
    my $compact = join(
        ',',
        @{
            NetAddr::IP::compactref(
                [ map { NetAddr::IP->new("192.0.2.$_/32") } 0 .. 15 ]
            )
        }
    );
    return "$contains $compact";
}

subtest 'literal addresses agree across threads' => sub {
    is( once(), $WANT, 'one thread compacts 192.0.2.0 to 192.0.2.15' );
    my @workers = map {
        threads->create(
            sub {
                my @bad;
                for my $round ( 1 .. $ROUNDS ) {
                    my $got = once();
                    push @bad, "round $round: $got" if $got ne $WANT;
                }
                return join "\n", @bad;
            }
        );
    } 1 .. $THREADS;
    for my $worker (@workers) {
        my $tid = $worker->tid;
        is( $worker->join, q{},
            "thread $tid matches the single-threaded result" );
    }
};

done_testing;
