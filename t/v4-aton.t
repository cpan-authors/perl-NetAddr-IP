use Test::More tests => 15;
use Socket;
use NetAddr::IP;

# $Id: v4-aton.t,v 1.2 2002/10/31 13:45:29 lem Exp $

my @addr = (
	[ 'localhost', '127.0.0.1' ],
	[ 'broadcast', '255.255.255.255' ],
	[ '254.254.0.1', '254.254.0.1' ],
	[ 'default', '0.0.0.0' ],
	[ '10.0.0.1', '10.0.0.1' ],

);

is(NetAddr::IP->new($_->[0])->aton, inet_aton($_->[1]), "->aton($_->[0])")
    for @addr;

ok(defined NetAddr::IP->new(inet_aton($_->[1])), "->new aton($_->[1])")
    for @addr;

is(NetAddr::IP->new(inet_aton($_->[1]))->addr, $_->[1], "->new aton($_->[1])")
    for @addr;
