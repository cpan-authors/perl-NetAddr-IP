#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

subtest 'new6' => sub {
    my $exp = '0:0:0:0:0:0:0:3039/1';

    my $ip  = NetAddr::IP::Lite->new6(12345, 1);
    my $got = $ip->cidr();
    is($got, $exp, 'new6 with numeric args');

    $ip  = NetAddr::IP::Lite->new6('12345', 1);
    $got = $ip->cidr();
    is($got, $exp, 'new6 with string numeric args');

    $ip  = NetAddr::IP::Lite->new6('12345/1');
    $got = $ip->cidr();
    is($got, $exp, 'new6 with string cidr');

    # 2^127	170141183460469231731687303715884105728
    $exp = '8000:0:0:0:0:0:0:0/1';

    $ip  = NetAddr::IP::Lite->new6('170141183460469231731687303715884105728/1');
    $got = $ip->cidr();
    is($got, $exp, 'new6 with 2^127');

    # 2^128	340282366920938463463374607431768211456 minus one
    $exp = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF/1';

    $ip  = NetAddr::IP::Lite->new6('340282366920938463463374607431768211455/1');
    $got = $ip->cidr();
    is($got, $exp, 'new6 with 2^128 minus one');
};

subtest 'new' => sub {
    my $exp = '0.0.48.57/1';

    my $ip  = NetAddr::IP::Lite->new(12345, 1);
    my $got = $ip->cidr();
    is($got, $exp, 'new with numeric args');

    $ip  = NetAddr::IP::Lite->new('12345', 1);
    $got = $ip->cidr();
    is($got, $exp, 'new with string numeric args');

    $ip  = NetAddr::IP::Lite->new('12345/1');
    $got = $ip->cidr();
    is($got, $exp, 'new with string cidr');

    # 2^127	170141183460469231731687303715884105728
    $exp = '8000:0:0:0:0:0:0:0/1';

    $ip  = NetAddr::IP::Lite->new('170141183460469231731687303715884105728/1');
    $got = $ip->cidr();
    is($got, $exp, 'new with 2^127');

    # 2^128	340282366920938463463374607431768211456 minus one
    $exp = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF/1';

    $ip  = NetAddr::IP::Lite->new('340282366920938463463374607431768211455/1');
    $got = $ip->cidr();
    is($got, $exp, 'new with 2^128 minus one');
};

done_testing;
