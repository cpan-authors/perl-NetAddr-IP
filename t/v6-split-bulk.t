use Test::More;
use NetAddr::IP;

# $Id: v6-split-bulk.t,v 1.2 2003/10/09 00:14:06 lem Exp $

my @addr = ( 
	     [ 'dead:beef::1', 126, 127, 2 ],
	     [ 'dead:beef::1', 127, 127, 1 ],
	     [ 'dead:beef::1', 127, 128, 2 ],
	     [ 'dead:beef::1', 128, 128, 1 ],
	     [ 'dead:beef::1', 124, 128, 16 ],
	     [ 'dead:beef::1', 124, 127, 8 ],
	    );

plan tests => (scalar @addr);

SKIP: {

    skip "NetAddr::IP cannot properly split() v6 addresses yet...",
    scalar @addr unless $ENV{V6DEBUG};

    for my $a (@addr) {
	my $ip = new NetAddr::IP $a->[0], $a->[1];
	my $r = $ip->splitref($a->[2]);
#	diag "$_\n" for @$r;
	is(@$r, $a->[3]);
    }
};
