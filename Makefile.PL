use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# $Id: Makefile.PL,v 1.8 2003/11/27 20:01:45 lem Exp $

my $checker = 0;

eval q{ use Test::Pod;
	$checker = 1; };

unless ($checker)
{
    print <<EOF;

Looks like this host does not have Test::Pod installed. Without this module,
the Pod documentation cannot be tested. This is not a big deal really, but
you might want to install Test::Mod by issuing the following command:

    perl -MCPAN -e "install('Test::Pod')"

at a nearby shell. This is nice because it allows easy tests of your own
documentation.

EOF
    ;
}

WriteMakefile(
    'NAME'		=> 'NetAddr::IP',
    'VERSION_FROM'	=> 'IP.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      Test::More => 0,
      Math::BigInt => 0,
    }, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM	=> 'IP.pm',
		AUTHOR     	=> 'Luis E. Muñoz <luismunoz@cpan.org>') : ()),
);




