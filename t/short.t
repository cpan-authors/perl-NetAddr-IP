use Test::More;

# $Id: short.t,v 1.1 2004/02/22 05:07:51 lem Exp $

my %cases = 
(
 '127.1'		=> '127.0.0.1',
 '127.0.1.1'		=> '127.0.1.1',
 '127.1.0.1'		=> '127.1.0.1',
 'DEAD:BEEF::1'		=> 'dead:beef::1',
 '::1'			=> '::1',
 '::'			=> '::',
 '2001:620:600::1'	=> '2001:620:600::1',
 '2001:620:600:0:1::1'	=> '2001:620:600:0:1::1',
 '2001:620:601:0:1::1'	=> '2001:620:601::1:0:0:1',
 );

my $tests = 2 * keys %cases;
plan tests => 1 + $tests;

SKIP: {
    use_ok('NetAddr::IP') or skip "Failed to load NetAddr::IP", $tests;
    for my $c (sort keys %cases)
    {
	my $ip = new NetAddr::IP $cases{$c};
	isa_ok($ip, 'NetAddr::IP', "$cases{$c}");
	unless (is($ip->short, $c, "short() returns $c"))
	{
	    diag "ip=$ip";
	}
    }
}
