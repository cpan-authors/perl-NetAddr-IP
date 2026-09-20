#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( inet_any2n ipv6_n2x );

my %num = (
    'a1b2:c3d4:e5d6:f7e8:08f9:190a:2a1b:3b4c' => 'A1B2:C3D4:E5D6:F7E8:8F9:190A:2A1B:3B4C',
    '1.2.3.4'                                   => '0:0:0:0:0:0:102:304',
    'A1B2:C3D4:E5D6:F7E8:08F9:190A:1.2.3.4'    => 'A1B2:C3D4:E5D6:F7E8:8F9:190A:102:304',
);

for my $input (sort keys %num) {
    my $bstr = inet_any2n($input);
    my $rv   = ipv6_n2x($bstr);
    my $exp  = $num{$input};
    is($rv, $exp, "inet_any2n($input) round-trips to $exp");
}

done_testing;
