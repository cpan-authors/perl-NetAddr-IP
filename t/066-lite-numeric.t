#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my @tval = (    #    IP                              bcd                                      mask bcd
    '8000:0:0:0:0:0:0:1/112', '170141183460469231731687303715884105729', '340282366920938463463374607431768145920',
    '1.2.3.4/24',             '16909060',                                '4294967040',
);

for (my $i = 0; $i < @tval; $i += 3) {
    my $nip = NetAddr::IP::Lite->new($tval[$i]);

    my $sclr = $nip->numeric;
    is($sclr . 'x', $tval[$i + 1] . 'x', 'scalar numeric matches');

    my ($addr, $mask) = $nip->numeric;
    is($addr . 'x', $tval[$i + 1] . 'x', 'addr numeric matches');
    is($mask . 'x', $tval[$i + 2] . 'x', 'mask numeric matches');
}

done_testing;
