#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

# perldoc gives one description to a run of =item headings, so the
# compactref heading has to sit with Compact(\@list), ahead of coalesce

my $path = 'lib/NetAddr/IP.pm';
open my $fh, '<', $path or bail_out("cannot read $path: $!");
my $pod = do { local $/; <$fh> };
close $fh or bail_out("cannot close $path: $!");

my $compactref_heading   = '=item C<$me-E<gt>compactref(\@list)>';
my $compact_list_heading = '=item C<$list_ref = Compact(\@list)>';
my $faster_sentence      = 'a faster version of C<-E<gt>compact()>';
my $coalesce_heading     = '=item C<$me-E<gt>coalesce($masklen, $number, @list_of_subnets)>';

my $compactref   = index $pod, $compactref_heading;
my $compact_list = index $pod, $compact_list_heading;
my $faster       = index $pod, $faster_sentence;
my $coalesce     = index $pod, $coalesce_heading;

my $order_name = 'the compactref heading shares the Compact list text, ahead of coalesce';

is( $compactref >= 0, 1, 'the compactref heading is in the POD' );
is( index( $pod, $compactref_heading, $compactref + 1 ),
    -1, 'the compactref heading appears once'
);
is( [ $compactref,                    $compact_list, $faster, $coalesce ],
    [ sort { $a <=> $b } $compactref, $compact_list, $faster, $coalesce ],
    $order_name
);

done_testing;
