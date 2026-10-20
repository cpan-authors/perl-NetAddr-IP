#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::InetBase qw(
  :lower
  inet_n2ad
  inet_n2dx
  ipv6_n2d
  ipv6_n2x
  isAnyIPv4
  isIPv4
);

my $ISANY_DIES =
  'Bad arg length for NetAddr::IP::InetBase::isAnyIPv4, length is';
my $ISIPV4_DIES = 'Bad arg length for NetAddr::IP::InetBase::isIPv4, length is';
my $N2D_DIES    = q{Bad arg length for 'ipv6_n2d', length is};
my $N2X_DIES    = q{Bad arg length for 'ipv6_n2x', length is};
my $V4_TEXT     = '192.0.2.1';
my $V6_TEXT_D   = '2001:db8:0:0:0:0:0.0.0.1';
my $V6_TEXT_X   = '2001:db8:0:0:0:0:0:1';

my $v4_compat = pack 'H*', '000000000000000000000000c0000201';    # ::192.0.2.1
my $v6_packed = pack 'H*', '20010db8000000000000000000000001';
my $seventeen = $v6_packed . "\0";

subtest 'an undefined argument is named as undefined, without a warning' =>
  sub {
    like(
        dies { ipv6_n2x(undef) },
        qr/\A\Q$N2X_DIES undefined should be 16 bytes\E at /,
        'ipv6_n2x of undef says undefined'
    );
    like(
        dies { ipv6_n2d(undef) },
        qr/\A\Q$N2D_DIES undefined should be 16 bytes\E at /,
        'ipv6_n2d of undef says undefined'
    );
    like(
        dies { isIPv4(undef) },
        qr/\A\Q$ISIPV4_DIES undefined, should be 128\E at /,
        'isIPv4 of undef says undefined'
    );
    like(
        dies { isAnyIPv4(undef) },
        qr/\A\Q$ISANY_DIES undefined, should be 128\E at /,
        'isAnyIPv4 of undef says undefined'
    );
    like(
        dies { inet_n2dx(undef) },
        qr/\A\Q$ISANY_DIES undefined, should be 128\E at /,
        'inet_n2dx of undef stops at the isAnyIPv4 it calls first'
    );
    like(
        dies { inet_n2ad(undef) },
        qr/\A\Q$N2D_DIES undefined should be 16 bytes\E at /,
        'inet_n2ad of undef stops at the ipv6_n2d it calls first'
    );
  };

subtest 'a defined argument of the wrong length is measured' => sub {
    like(
        dies { ipv6_n2x('') },
        qr/\A\Q$N2X_DIES 0 should be 16 bytes\E at /,
        'ipv6_n2x of an empty string measures 0 bytes'
    );
    like(
        dies { ipv6_n2x($seventeen) },
        qr/\A\Q$N2X_DIES 17 should be 16 bytes\E at /,
        'ipv6_n2x of seventeen bytes measures 17 bytes'
    );
    like(
        dies { ipv6_n2d('') },
        qr/\A\Q$N2D_DIES 0 should be 16 bytes\E at /,
        'ipv6_n2d of an empty string measures 0 bytes'
    );
    like(
        dies { ipv6_n2d($seventeen) },
        qr/\A\Q$N2D_DIES 17 should be 16 bytes\E at /,
        'ipv6_n2d of seventeen bytes measures 17 bytes'
    );
    like(
        dies { isIPv4('') },
        qr/\A\Q$ISIPV4_DIES 0, should be 128\E at /,
        'isIPv4 of an empty string measures 0 bits'
    );
    like(
        dies { isIPv4($seventeen) },
        qr/\A\Q$ISIPV4_DIES 136, should be 128\E at /,
        'isIPv4 of seventeen bytes measures 136 bits'
    );
};

subtest 'sixteen bytes still convert' => sub {
    is( ipv6_n2x($v6_packed),  $V6_TEXT_X, 'ipv6_n2x of 2001:db8::1' );
    is( ipv6_n2d($v6_packed),  $V6_TEXT_D, 'ipv6_n2d of 2001:db8::1' );
    is( isIPv4($v4_compat),    1,          'isIPv4 of ::192.0.2.1' );
    is( isIPv4($v6_packed),    0,          'isIPv4 of 2001:db8::1' );
    is( inet_n2dx($v4_compat), $V4_TEXT,   'inet_n2dx of ::192.0.2.1' );
    is( inet_n2ad($v6_packed), $V6_TEXT_D, 'inet_n2ad of 2001:db8::1' );
};

done_testing;
