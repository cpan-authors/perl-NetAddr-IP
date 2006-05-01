# Generic load/POD test suite

# $Id: 00-load.t,v 1.6 2006/05/01 15:24:50 lem Exp $

use Test::More;

my @modules = qw/
	NetAddr::IP
	/;

my @paths = ();

plan tests => 3 * scalar @modules;

use_ok($_) for @modules;

my $checker = 0;
my $coverage = 0;

eval { require Test::Pod;
       Test::Pod::import();
       $checker = 1; };

eval { require Pod::Coverage;
       Pod::Coverage::import();
       $coverage = 1; };

for my $m (@modules)
{
    my $p = $m . ".pm";
    $p =~ s!::!/!g;
    push @paths, $INC{$p};
}

SKIP: {
    skip "Test::Pod is not available on this host", scalar @paths
	unless $checker;
    pod_file_ok($_) for @paths;
}

SKIP: { skip "Pod::Coverage is not available on this host", scalar @paths
	unless $coverage;

	for my $m (@modules)
	{
	    my $pc = Pod::Coverage->new(package => $m,
					also_private => [qr/^STORABLE_/,
							 qr/^new4$/,
							 qr/^expand_v6$/,
							 qr/^do_prefix$/,
							],
					trustme => [ qr/^Coalesce$|^Compact$/,
						     qr/^(plus){1,2}$/,
						     qr/^(minus){1,2}$/
						   ],
				       );
	    unless (is($pc->coverage, 1, "Coverage for $m"))
	    {
#	    diag "Symbols covered:\n", 
#	    join("\n", map { "  " . $_ } $pc->covered);
		diag "Symbols NOT covered:\n", 
		join("\n", map { "  " . $_ } $pc->naked);
	    }
	}
      }


