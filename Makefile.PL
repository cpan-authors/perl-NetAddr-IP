use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'NetAddr::IP',
    'VERSION_FROM' => 'IP.pm', # finds $VERSION
    'PREREQ_PM' => { 'Math::BigInt' => 0, },
);
