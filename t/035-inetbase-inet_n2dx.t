#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::InetBase qw( inet_any2n inet_n2dx );

my %num = (
    'a1b2:c3d4:e5d6:f7e8:08f9:190a:2a1b:3b4c' => 'a1b2:c3d4:e5d6:f7e8:8f9:190a:2a1b:3b4c',
    '1.2.3.4'                                 => '1.2.3.4',
    'A1B2:C3D4:E5D6:F7E8:08F9:190A:1.2.3.4'   => 'a1b2:c3d4:e5d6:f7e8:8f9:190a:102:304',
    '::1.2.3.4'                               => '1.2.3.4',
    '::FFFF:1.2.3.4'                          => '1.2.3.4',
);

for my $input (sort keys %num) {
    my $bstr = inet_any2n($input);
    my $rv   = inet_n2dx($bstr);
    is($rv, $num{$input}, "inet_n2dx(inet_any2n($input))");
}

done_testing;
