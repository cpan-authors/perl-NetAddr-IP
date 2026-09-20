#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $four = NetAddr::IP::Lite->new('::4');
$four->{val} = 4;
my $five = NetAddr::IP::Lite->new('::5');
$five->{val} = 5;

my @t = (
#   arg1    arg2    <   <=   ==   >=   >   <=>   cmp
    $four,  $four,  0,  1,   1,   1,  0,   0,    0,
    $four,  $five,  1,  1,   0,   0,  0,  -1,   -1,
    $five,  $four,  0,  0,   0,   1,  1,   1,    1,
);

for (my $i = 0; $i < @t; $i += 9) {
    my $arg1 = $t[$i];
    my $arg2 = $t[$i + 1];
    my ($lt, $le, $eq, $ge, $gt, $nc, $cmp) = @t[$i + 2, $i + 3, $i + 4, $i + 5, $i + 6, $i + 7, $i + 8];

    subtest "comparison tests for $arg1->{val} vs $arg2->{val}" => sub {
        cmp_ok($arg1 < $arg2,   '==', $lt,  "$arg1->{val} < $arg2->{val}");
        cmp_ok($arg1 <= $arg2,  '==', $le,  "$arg1->{val} <= $arg2->{val}");
        cmp_ok($arg1 == $arg2,  '==', $eq,  "$arg1->{val} == $arg2->{val}");
        cmp_ok($arg1 >= $arg2,  '==', $ge,  "$arg1->{val} >= $arg2->{val}");
        cmp_ok($arg1 > $arg2,   '==', $gt,  "$arg1->{val} > $arg2->{val}");
        cmp_ok($arg1 <=> $arg2, '==', $nc,  "$arg1->{val} <=> $arg2->{val}");
        cmp_ok($arg1 cmp $arg2, '==', $cmp, "$arg1->{val} cmp $arg2->{val}");
    };
}

done_testing;
