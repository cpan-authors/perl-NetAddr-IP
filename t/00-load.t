# Generic load/POD test suite

# $Id: 00-load.t,v 1.4 2004/03/02 20:21:36 lem Exp $

use Test::More;

my @modules = qw/
	NetAddr::IP
	/;

my @paths = ();

plan tests => 2 * scalar @modules;

use_ok($_) for @modules;

my $checker = 0;

eval { require Test::Pod;
     Test::Pod::import();
       $checker = 1; };

for my $m (@modules)
{
    my $p = $m . ".pm";
    $p =~ s!::!/!g;
    push @paths, $INC{$p};
}

END { unlink "./out.$$" };

SKIP: {
    skip "Test::Pod is not available on this host", scalar @paths
	unless $checker;
    pod_file_ok($_) for @paths;
}

