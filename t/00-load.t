# Generic load/POD test suite

# $Id: 00-load.t,v 1.3 2003/10/08 06:46:02 lem Exp $

use Test::More;

my @modules = qw/
	NetAddr::IP
	/;

my @paths = ();

plan tests => 2 * scalar @modules;

use_ok($_) for @modules;

my $checker = 0;

eval { use Test::Pod;
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

