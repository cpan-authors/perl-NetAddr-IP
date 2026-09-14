#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();
*_no_octal = \&NetAddr::IP::Lite::_no_octal;

my @ranges = (
    ['10.0.0.0/8',     '10.0.0.0',     '10.255.255.255'],
    ['192.68.0.0/16',  '192.068.0.0',  '192.068.255.255'],
);

my @weird = (
    ['128.111.12.0', '128.111.12.129'],
);

subtest 'ranges' => sub {
    for my $r (@ranges) {
        my $r1 = NetAddr::IP::Lite->new_no($r->[1] . '-' . $r->[2]);
        isa_ok($r1, 'NetAddr::IP::Lite');
        is("$r1", $r->[0], 'Correct interpretation (with space)');

        $r1 = NetAddr::IP::Lite->new_no($r->[1] . ' - ' . $r->[2]);
        isa_ok($r1, 'NetAddr::IP::Lite');
        is("$r1", $r->[0], 'Correct interpretation (w/o space)');

        $r1 = NetAddr::IP::Lite->new_no($r->[0]);
        isa_ok($r1, 'NetAddr::IP::Lite');
        my @rev = (undef, _no_octal($r->[1]), _no_octal($r->[2]));
        is($r1->range, $rev[1] . ' - ' . $rev[2], 'Correct reverse');
    }
};

subtest 'weird' => sub {
    for my $r (@weird) {
        my $r1 = NetAddr::IP::Lite->new_no($r->[0] . '-' . $r->[1]);
        ok(!defined $r1, 'Weird range w/o space produces undef');
        $r1 = NetAddr::IP::Lite->new_no($r->[0] . ' - ' . $r->[1]);
        ok(!defined $r1, 'Weird range with space produces undef');
    }
};

subtest 'weird octets' => sub {
    for my $o (254, 252, 248, 240, 224, 192, 128) {
        my $r1 = NetAddr::IP::Lite->new_no('0.0.0.0 - ' . $o . '.0.0.0');
        ok(!defined $r1, "Weird $o range, first octet");
        $r1 = NetAddr::IP::Lite->new_no('0.0.0.0 - 0.' . $o . '.0.0');
        ok(!defined $r1, "Weird $o range, second octet");
        $r1 = NetAddr::IP::Lite->new_no('0.0.0.0 - 0.0.' . $o . '.0');
        ok(!defined $r1, "Weird $o range, third octet");
        $r1 = NetAddr::IP::Lite->new_no('0.0.0.0 - 0.0.0.' . $o);
        ok(!defined $r1, "Weird $o range, fourth octet");
    }
};

done_testing;
