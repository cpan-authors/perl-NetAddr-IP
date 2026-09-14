#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Util qw( inet_any2n inet_n2ad ipv6_aton );

my %num = (
    'a1b2:c3d4:e5d6:f7e8:08f9:190a:2a1b:3b4c' => 'A1B2:C3D4:E5D6:F7E8:8F9:190A:42.27.59.76',
    '1.2.3.4'                                   => '1.2.3.4',
    '190A::102:304'                              => '190A:0:0:0:0:0:1.2.3.4',
);

my $ff = ipv6_aton('a1b2:c3d4:e5d6:f7e8:08f9:190a:2a1b:3b4c');
for my $input (sort keys %num) {
    my $bstr = inet_any2n($input);
    my $rv   = inet_n2ad($bstr);
    my $exp  = $num{$input};
    is($rv, $exp, 'inet_n2ad returns expected for ' . $input);
}

done_testing;
