#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( bcdn2txt bin2bcd bin2bcdn ipv6_aton );

sub val {
    my $bcd = shift;
    my $rv  = unpack('H*', $bcd);
    $rv =~ s/^0+([0-9])/$1/g;
    return $rv;
}

my %num2 = (
    '::'                 => '0',
    '::8000:0'           => '2147483648',
    '::8000:0:0'         => '140737488355328',
    '::8000:0:0:0'       => '9223372036854775808',
    '::8000:0:0:0:0'     => '604462909807314587353088',
    '::8000:0:0:0:0:0'   => '39614081257132168796771975168',
    '::8000:0:0:0:0:0:0' => '2596148429267413814265248164610048',
    '8000:0:0:0:0:0:0:0' => '170141183460469231731687303715884105728',
);

subtest 'bin2bcdn string unpack via val' => sub {
    for my $input (sort { $a cmp $b } keys %num2) {
        my $bstr = ipv6_aton($input);
        my $bcd  = bin2bcdn($bstr);
        my $got  = val($bcd);
        is($got, $num2{$input}, "bin2bcdn($input) via val");
    }
};

subtest 'bin2bcdn string unpack via bcdn2txt' => sub {
    for my $input (sort { $a cmp $b } keys %num2) {
        my $bstr = ipv6_aton($input);
        my $bcd  = bin2bcdn($bstr);
        my $got  = bcdn2txt($bcd);
        is($got, $num2{$input}, "bin2bcdn($input) via bcdn2txt");
    }
};

subtest 'bin2bcd' => sub {
    for my $input (sort { $a cmp $b } keys %num2) {
        my $bstr = ipv6_aton($input);
        my $bcd  = bin2bcd($bstr);
        is($bcd, $num2{$input}, "bin2bcd($input)");
    }
};

done_testing;
