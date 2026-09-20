#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $four    = NetAddr::IP::Lite->new('0.0.0.4');
my $four120 = NetAddr::IP::Lite->new('::4/120');

my $t432  = '0.0.0.4/32';
my $t4120 = '0:0:0:0:0:0:0:4/120';

my $five = NetAddr::IP::Lite->new('0.0.0.5');
my $t532 = '0.0.0.5/32';

subtest 'string overloading and eq/ne' => sub {
    ## test '""' overload
    my $txt = sprintf('%s', $four120);
    is($txt, $t4120, 'string overloading of ::4/120');

    ## test '""' again
    $txt = sprintf('%s', $four);
    is($txt, $t432, 'string overloading of 0.0.0.4');

    ## test 'eq' to scalar
    ok($four eq $t432, 'eq object to scalar');

    ## test scalar 'eq' to
    ok($t432 eq $four, 'eq scalar to object');

    ## test 'eq' to self
    ok($four eq $four, 'eq object to self');

    ## test 'ne' to scalar
    ok($four120 ne $t432, 'ne object to scalar');

    ## test scalar 'ne' to
    ok($t432 ne $four120, 'ne scalar to object');

    ## test 'ne' to cidr
    ok($four ne $four120, 'ne different cidr objects');
};

subtest 'numeric comparisons' => sub {
    ## test '==' not for scalars
    ok(!($t432 == $four), '== not for scalar');

    ## test '==' not for scalar, reversed args
    ok(!($four == $t432), '== not for scalar, reversed args');

    ## test '!=' not for scalar, reversed args
    my $rv = $five != $four ? 1 : 0;
    ok($rv, '!= object to object');

    no warnings 'numeric';

    ## test '!=' not for scalars
    $rv = $t432 != $five ? 1 : 0;
    ok($rv, '!= scalar to object');

    ## since both of these are string scalars, the != should fail
    $rv = $t532 != $t432 ? 1 : 0;
    ok(!$rv, '!= scalar to scalar should be false');
};

done_testing;
