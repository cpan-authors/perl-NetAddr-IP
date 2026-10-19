#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::InetBase qw( ipv6_aton ipv6_n2x isAnyIPv4 isIPv4 isNewIPv4 );

my @num = qw(
  ::
  8000::
  4000::
  2000::
  1000::
  800::
  400::
  200::
  100::
  80::
  40::
  20::
  10::
  1::
  0:8000::
  0:4000::
  0:2000::
  0:1000::
  0:800::
  0:400::
  0:200::
  0:100::
  0:80::
  0:40::
  0:20::
  0:10::
  0:1::
  0:0:8000::
  0:0:4000::
  0:0:2000::
  0:0:1000::
  0:0:800::
  0:0:400::
  0:0:200::
  0:0:100::
  0:0:80::
  0:0:40::
  0:0:20::
  0:0:10::
  0:0:1::
  0:0:0:8000::
  0:0:0:4000::
  0:0:0:2000::
  0:0:0:1000::
  0:0:0:800::
  0:0:0:400::
  0:0:0:200::
  0:0:0:100::
  0:0:0:80::
  0:0:0:40::
  0:0:0:20::
  0:0:0:10::
  0:0:0:1::
  0:0:0:0:8000::
  0:0:0:0:4000::
  0:0:0:0:2000::
  0:0:0:0:1000::
  0:0:0:0:800::
  0:0:0:0:400::
  0:0:0:0:200::
  0:0:0:0:100::
  0:0:0:0:80::
  0:0:0:0:40::
  0:0:0:0:20::
  0:0:0:0:10::
  0:0:0:0:1::
  ::8000:0
  ::4000:0
  ::2000:0
  ::1000:0
  ::800:0
  ::400:0
  ::200:0
  ::100:0
  ::80:0
  ::40:0
  ::20:0
  ::10:0
  ::1:0
  ::8000
  ::4000
  ::2000
  ::1000
  ::800
  ::400
  ::200
  ::100
  ::80
  ::40
  ::20
  ::10
  ::1
);

subtest 'isIPv4' => sub {
    for my $input (@num) {
        my $bstr = ipv6_aton($input);
        my $rv   = isIPv4($bstr);
        my $exp  = ( $input =~ m/[0-9]::$/ ) ? 0 : 1;
        is( $rv, $exp, "isIPv4 for " . ipv6_n2x($bstr) );
    }
};

subtest 'isAnyIPv4' => sub {
    for my $input (@num) {
        my $bstr = ipv6_aton($input);
        my $rv   = isAnyIPv4($bstr);
        my $exp  = ( $input =~ m/[0-9]::$/ ) ? 0 : 1;
        is( $rv, $exp, "isAnyIPv4 for " . ipv6_n2x($bstr) );
    }
};

my $compat = ipv6_aton('::FFFF:0:0');

subtest 'isAnyIPv4 with compatible high bits' => sub {
    for my $input (@num) {
        my $bstr = ipv6_aton($input);
        $bstr ^= $compat;
        my $rv  = isAnyIPv4($bstr);
        my $exp = ( $input =~ m/[0-9]::$/ ) ? 0 : 1;
        is( $rv, $exp, "isAnyIPv4 compat for " . ipv6_n2x($bstr) );
    }
};

subtest 'isNewIPv4 with compatible high bits' => sub {
    for my $input (@num) {
        my $bstr = ipv6_aton($input);
        $bstr ^= $compat;
        my $rv  = isNewIPv4($bstr);
        my $exp = ( $input =~ m/[0-9]::$/ ) ? 0 : 1;
        is( $rv, $exp, "isNewIPv4 compat for " . ipv6_n2x($bstr) );
    }
};

# arguments that are not 16 bytes, with their length in bits
my %wrong_length = (
    'an empty string'                       => [ '',                     0 ],
    'four bytes'                            => [ "\xc0\0\2\1",           32 ],
    'fifteen bytes'                         => [ "\0" x 15,              120 ],
    'seventeen bytes'                       => [ "\0" x 17,              136 ],
    'twelve bytes ending in the ffff group' => [ "\0" x 10 . "\xff\xff", 96 ],
);

subtest 'all three croak on an argument that is not 16 bytes' => sub {
    for my $case ( sort keys %wrong_length ) {
        my ( $bits128, $bits ) = @{ $wrong_length{$case} };
        for my $name (qw( isAnyIPv4 isIPv4 isNewIPv4 )) {
            my $predicate = NetAddr::IP::InetBase->can($name);
            like(
                dies { $predicate->($bits128) },
qr/\ABad arg length for NetAddr::IP::InetBase::$name, length is $bits, should be 128 at /,
                "$name of $case croaks, naming $name"
            );
        }
    }
};

done_testing;
