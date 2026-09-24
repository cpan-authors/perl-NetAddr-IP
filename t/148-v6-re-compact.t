#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw(lives);

use NetAddr::IP ();

my @nets = qw(
  2001:db8::/32
  2001:db8::/120
  2001:db8::/117
  2001:db8::800/117
  2001:db8::1/128
  2001:db8:0:0:1::/80
  fe80::/10
  ::ffff:0:0/96
  ::/0
  ::1/128
);

my %in = (
  '2001:db8::/32'     => [qw(2001:db8::1 2001:DB8:: 2001:db8:1:: 2001:db8::1:2 2001:0db8::1 2001:db8:1:2:3:4:5::)],
  '2001:db8::/120'    => [qw(2001:db8::f 2001:db8::0f 2001:db8::00f 2001:db8::ff 2001:db8::)],
  '2001:db8::/117'    => [qw(2001:db8::ff 2001:db8::7ff 2001:db8::07ff 2001:db8::0)],
  '2001:db8::800/117' => [qw(2001:db8::800 2001:db8::fff 2001:db8::0800)],
  '2001:db8::1/128'   => [qw(2001:db8::1 2001:db8::0001 2001:db8:0::1)],
  '2001:db8:0:0:1::/80' => [qw(2001:db8::1:0:0:0 2001:db8:0:0:1:: 2001:db8:0:0:1::1 2001:db8:0:0:1:ffff:ffff:ffff)],
  'fe80::/10'         => [qw(fe80::1 febf:ffff:: FE80::1)],
  '::ffff:0:0/96'     => [qw(::ffff:c000:201 ::ffff:0:0 ::FFFF:ffff:ffff)],
  '::/0'              => [qw(:: ::1 1:: 1:2:3:4:5:6:7:8)],
  '::1/128'           => [qw(::1 0::1 ::0001)],
);

my %out = (
  '2001:db8::/32'     => [qw(2001:db9::1 2001:db8:::1 2001:db8::1:: 2001:db7:ffff::)],
  '2001:db8::/120'    => [qw(2001:db8::100 2001:db8::1:0 2001:db8::ff:0)],
  '2001:db8::/117'    => [qw(2001:db8::800 2001:db8::1:0)],
  '2001:db8::800/117' => [qw(2001:db8::7ff 2001:db8:: 2001:db8::1000)],
  '2001:db8::1/128'   => [qw(2001:db8:: 2001:db8::2 2001:db8::1:1)],
  '2001:db8:0:0:1::/80' => [qw(2001:db8:: 2001:db8::2:0:0:0 2001:db8:0:1:1::)],
  'fe80::/10'         => [qw(fec0:: fe7f:: ff80::)],
  '::ffff:0:0/96'     => [qw(::fffe:0:0 ::1 1::ffff:0:0)],
  '::/0'              => [qw(1::2::3 :::)],
  '::1/128'           => [qw(:: ::2 1::1)],
);

my $MAX_RE_SIZE = 4_096;

subtest 're6 compiles and matches in/out addresses' => sub {
  for my $n (@nets) {
    my $net = NetAddr::IP->new($n);
    my $re  = $net->re6;
    my $rx;

    ok(lives { $rx = qr/^$re$/ }, sprintf('re6(%s) compiles', $n)) or diag $@;
    ok(length($re) < $MAX_RE_SIZE, sprintf('re6(%s) size < %d', $n, $MAX_RE_SIZE));

    for my $addr (@{$in{$n}}) {
      like($addr, $rx, sprintf('re6(%s) matches %s', $n, $addr));
      my $ip = NetAddr::IP->new($addr);
      like($ip->addr, $rx, sprintf('re6(%s) matches full form %s', $n, $ip->addr));
      like($ip->canon, $rx, sprintf('re6(%s) matches canon form %s', $n, $ip->canon));
    }
    for my $addr (@{$out{$n}}) {
      unlike($addr, $rx, sprintf('re6(%s) does not match %s', $n, $addr));
    }
  }
};

done_testing;
