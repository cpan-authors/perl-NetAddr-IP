use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# $Id: Makefile.PL,v 1.10 2005/03/24 18:55:10 lem Exp $

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

print <<EOF;

======================================================================
W A R N I N G - Please do read below if you have legacy code
======================================================================

Versions 3.21 and above of NetAddr::IP, include hooks for the Storable
class that are incompatible with the old (automatic) method of storing
data. To regain backwards compatibility, the module must be use()d as

    use NetAddr::IP ':old_storable';

Which will disable the new hooks and revert back to the old ways.

If you do  not use Storable along NetAddr::IP or  just don't know what
this all means, most likely you're safe to go along.

EOF
    ;

WriteMakefile(
	      (MM->can('signature_target') ? (SIGN => 1) : ()),    
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
