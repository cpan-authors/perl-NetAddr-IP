#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::InetBase qw( inet_any2n ipv6_n2x );

my %num = (
    'a1b2:c3d4:e5d6:f7e8:08f9:190a:2a1b:3b4c' =>
      'a1b2:c3d4:e5d6:f7e8:8f9:190a:2a1b:3b4c',
    '1.2.3.4'                               => '0:0:0:0:0:0:102:304',
    'A1B2:C3D4:E5D6:F7E8:08F9:190A:1.2.3.4' =>
      'a1b2:c3d4:e5d6:f7e8:8f9:190a:102:304',
);

for my $input ( sort keys %num ) {
    my $bstr = inet_any2n($input);
    my $rv   = ipv6_n2x($bstr);
    my $exp  = $num{$input};
    is( $rv, $exp, "inet_any2n($input)" );
}

subtest 'text without a colon has to be a dotted quad' => sub {
    for my $text (qw( 0 10 010 192 ffff 192.0.2 1.2 )) {
        is( inet_any2n($text), undef, "inet_any2n('$text')" );
    }
    is( ipv6_n2x( inet_any2n('192.0.2.1') ),
        '0:0:0:0:0:0:c000:201', 'a dotted quad still converts' );
    is( ipv6_n2x( inet_any2n('') ),
        '0:0:0:0:0:0:0:0', 'an empty string is still the all-zero address' );
};

done_testing;
