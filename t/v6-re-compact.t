# re6 must match the compressed (::) and shortened forms of an address,
# not only the full 8 group form with every digit present.
use Test::More;
use NetAddr::IP;

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

my $tests = 0;
$tests += 2 + 3 * @{$in{$_}} + @{$out{$_}} for @nets;
plan tests => $tests;

for my $n (@nets) {
  my $net = NetAddr::IP->new($n);
  my $re  = $net->re6;
  my $rx;
  eval { $rx = qr/^$re$/ };
  ok(!$@, "re6($n) compiles") or diag $@;
  ok(length($re) < 4096, "re6($n) is bounded in size (" . length($re) . ")");

  for my $a (@{$in{$n}}) {
    ok($a =~ $rx, "re6($n) matches $a");
    my $ip = NetAddr::IP->new($a);
    ok($ip->addr =~ $rx,  "re6($n) matches full form " . $ip->addr);
    ok($ip->canon =~ $rx, "re6($n) matches canon form " . $ip->canon);
  }
  for my $a (@{$out{$n}}) {
    ok($a !~ $rx, "re6($n) does not match $a");
  }
}