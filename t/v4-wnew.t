use Test::More tests => 12;
use NetAddr::IP;

# $Id: v4-wnew.t,v 1.1 2002/10/31 04:30:37 lem Exp $

my @good = (qw(default any broadcast loopback));
my @bad = map { ("$_.neveranydomainlikethis",
		 "nohostlikethis.$_") } @good;

ok(defined NetAddr::IP->new($_), "defined ->new($_)")
    for @good;

ok(! defined NetAddr::IP->new($_), "not defined ->new($_)")
    for @bad;

