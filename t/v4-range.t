use NetAddr::IP;

use Test::More;

# $Id: v4-range.t,v 1.3 2003/11/27 20:04:02 lem Exp $

my @ranges = (
	      [ '10.0.0.0/8', '10.0.0.0', '10.255.255.255' ],
	      [ '192.168.0.0/16', '192.168.0.0', '192.168.255.255' ],
	      );

my @weird = (
	     [ '128.111.12.0', '128.111.12.129' ],
	     );

plan tests => 6 * @ranges + 2 * @weird + 28;

for my $r (@ranges) {
    my $r1 = new NetAddr::IP $r->[1] . '-' . $r->[2];
    isa_ok($r1, 'NetAddr::IP');
    is($r1, $r->[0], "Correct interpretation (with space)");

    $r1 = new NetAddr::IP $r->[1] . ' - ' . $r->[2];
    isa_ok($r1, 'NetAddr::IP');
    is($r1, $r->[0], "Correct interpretation (w/o space)");

    $r1 = new NetAddr::IP $r->[0];
    isa_ok($r1, 'NetAddr::IP');
    is($r1->range, $r->[1] . ' - ' . $r->[2], "Correct reverse");
}

for my $r (@weird)
{
    my $r1 = new NetAddr::IP $r->[0] . '-' . $r->[1];
    ok(! defined $r1, "Weird range w/o space produces undef");
    $r1 = new NetAddr::IP $r->[0] . ' - ' . $r->[1];
    ok(! defined $r1, "Weird range with space produces undef");
}

for my $o (254, 252, 248, 240, 224, 192, 128)
{
    my $r1 = new NetAddr::IP '0.0.0.0 - ' . $o . '.0.0.0';
    ok(! defined $r1, "Weird $o range, first octet");
    $r1 = new NetAddr::IP '0.0.0.0 - 0.' . $o . '.0.0';
    ok(! defined $r1, "Weird $o range, second octet");
    $r1 = new NetAddr::IP '0.0.0.0 - 0.0.' . $o . '.0';
    ok(! defined $r1, "Weird $o range, third octet");
    $r1 = new NetAddr::IP '0.0.0.0 - 0.0.0.' . $o;
    ok(! defined $r1, "Weird $o range, fourth octet");
}
