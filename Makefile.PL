use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# $Id: Makefile.PL,v 1.2 2002/10/31 04:30:22 lem Exp $

WriteMakefile(
    'NAME'		=> 'NetAddr::IP',
    'VERSION_FROM'	=> 'IP.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      Test::More => 0,
    }, # e.g., Module::Name => 1.1
);
