#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::InetBase qw( inet_any2n inet_n2ad );

my %num = (
    'a1b2:c3d4:e5d6:f7e8:08f9:190a:2a1b:3b4c' => 'a1b2:c3d4:e5d6:f7e8:8f9:190a:42.27.59.76',
    '1.2.3.4'                                 => '1.2.3.4',
    '190A::102:304'                           => '190a:0:0:0:0:0:1.2.3.4',
);

for my $input (sort keys %num) {
    my $bstr = inet_any2n($input);
    my $rv   = inet_n2ad($bstr);
    is($rv, $num{$input}, "inet_n2ad(inet_any2n($input))");
}

done_testing;
