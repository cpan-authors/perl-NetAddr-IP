use ExtUtils::MakeMaker qw(WriteMakefile);
use Config;
use Cwd;
use File::Spec;
use Getopt::Long qw(GetOptions);

my $pwd = getcwd();

unlink 'Makefile';    # remove Makefile to stabilize CC test

#
# get any command line arguments
#
my ($useXS);
GetOptions(
    'xs!' => \$useXS,
    'pm'  => sub {
        warn "\n\t" . 'WARNING: Use of "--pm" is deprecated, use "-noxs" instead' . "\n\n";
        $useXS = 0;
    },
);

print STDERR "building for $^O\n";

# force NOXS mode for Windows
if ($Config{osname} =~ /win/i || $Config{osname} eq 'dos') {
    $useXS = 0;
}

#
# Check if we have a C compiler
#
unless (defined $useXS) {
    my $compiler = test_cc();
    if ($compiler) {
        $ENV{CC} = $compiler;
        print "You have a working compiler.\n";
        $useXS = 1;
    }
    else {
        $useXS = 0;
        print <<END;

I cannot determine if you have a C compiler. I will install the
perl-only implementation.

You can force installation of the XS version with:

        perl Makefile.PL --xs
END
    }
}

my $begin = '';

while ($useXS) {
    local $ENV{TMPDIR} = File::Spec->tmpdir() if $^O eq 'android';

    unless (-e 'xs/config.h') {
        chdir 'xs';
        system $Config{sh}, 'configure.gcc';
        chdir $pwd;
    }

    unless (open(F, 'xs/config.h')) {
        warn "Cannot read config.h built by 'gcc', trying 'cc'.\n";
        chdir 'xs';
        system $Config{sh}, 'configure.cc';
        chdir $pwd;
        unless (open(F, 'xs/config.h')) {
            warn "Cannot read config.h built by 'cc', using 'pure Perl'.\n";
            $useXS = 0;
            last;
        }
    }

    close F;

    open(F, '>xs/localperl.h') or die "could not open localperl.h for write\n";
    print F q|
/*	Written by Makefile.PL
 *
 *	Do not modify this file, modify Makefile.PL instead
 *
 */
|;
    close F;

    $begin = q|
config  :: xs/config.h
	@$(NOOP)

xs/config.h :
	cd xs && $(SHELL) configure
|;
    last;
}

#
# Generate Util_IS.pm
#
my $util_is_path = 'lib/NetAddr/IP/Util_IS.pm';
open(F, '>', $util_is_path) or die "Cannot write $util_is_path: $!\n";
print F q|#!/usr/bin/perl
#
# DO NOT ALTER THIS FILE
# IT IS WRITTEN BY Makefile.PL
# EDIT THAT INSTEAD
#
package NetAddr::IP::Util_IS;
use vars qw($VERSION);
$VERSION = 1.00;


sub pure {
  return |, (($useXS) ? 0 : 1), q|;
}
sub not_pure {
  return |, (($useXS) ? 1 : 0), q|;
}
1;
__END__

=head1 NAME

NetAddr::IP::Util_IS - Tell about Pure Perl

=head1 SYNOPSIS

  use NetAddr::IP::Util_IS;

  $rv = NetAddr::IP::Util_IS->pure;
  $rv = NetAddr::IP::Util_IS->not_pure;

=head1 DESCRIPTION

Util_IS indicates whether or not B<NetAddr::IP::Util> was compiled in Pure
Perl mode.

=over 4

=item * $rv = NetAddr::IP::Util_IS->pure;

Returns true if PurePerl mode, else false.

=item * $rv = NetAddr::IP::Util_IS->not_pure;

Returns true if NOT PurePerl mode, else false

=back

=cut

1;
|;
close F;

#
# Build parameters
#
my %makeparms = (
    NAME         => 'NetAddr::IP',
    VERSION_FROM => 'lib/NetAddr/IP.pm',
    PREREQ_PM    => { Test::More => 0 },
    ABSTRACT_FROM => 'lib/NetAddr/IP.pm',
    AUTHOR       => 'Luis E. Muñoz <luismunoz@cpan.org>, Michael Robinton <miker@cpan.org>',
    INC          => '-Ixs',
    clean        => { FILES => "*.bs *.o *~ tmp* META.yml Util_IS.pm localperl.h auto* lib/NetAddr/IP/Util.o lib/NetAddr/IP/Util_IS.pm xs/config.h xs/config.log xs/config.status xs/localperl.h" },
    realclean    => { FILES => "config.h config.log config.status xs/config.h xs/localperl.h" },
);

if ($useXS) {
    $makeparms{XS}     = { 'xs/Util.xs' => 'lib/NetAddr/IP/Util.c' };
    $makeparms{C}      = ['lib/NetAddr/IP/Util.c'];
    $makeparms{OBJECT} = 'lib/NetAddr/IP/Util.o';
    $makeparms{depend} = { 'lib/NetAddr/IP/Util.c' => 'xs/localconf.h xs/config.h' };
    $makeparms{LIBS}   = [];

    if (open(my $fh, 'xs/config.h')) {
        while (<$fh>) {
            if (/^#define LIBS\s+(.+)/) {
                $makeparms{LIBS} = [$1];
                last;
            }
        }
        close $fh;
    }
}

WriteMakefile(%makeparms);

#
# Subroutines
#

sub test_cc {
    print "Testing if you have a C compiler and the needed header files....\n";

    unless (open(F, ">compile.c")) {
        warn "Cannot write compile.c, skipping test compilation and installing pure Perl version.\n";
        return 0;
    }

    my $CC;
    foreach $CC (($ENV{CC}, $Config{cc}, $Config{ccname})) {
        next unless $CC;
        my $command = qq|$CC compile.c -o compile.output|;

        print F <<'EOF';
int main() { return 0; }
EOF

        close(F) or return 0;

        print STDERR $command, "\n";

        my $rv = system($command);

        foreach my $file (glob('compile*')) {
            unlink($file) || warn "Could not delete $file: $!\n";
        }
        if ($rv == 0) {
            return $CC;
        }
    }
    return undef;
}

sub MY::top_targets {
    package MY;
    my $inherited = shift->SUPER::top_targets(@_);
    $begin . $inherited;
}

sub MY::postamble {
    package MY;
    my $util_xs = 'xs/Util.xs';
    my $util_c  = 'lib/NetAddr/IP/Util.c';
    my $util_o  = 'lib/NetAddr/IP/Util.o';

    return <<"END_POSTAMBLE";
$util_c : $util_xs xs/typemap
\tcd xs && \$(PERLRUN) \$(XSUBPP) -typemap typemap \$(XSUBPPARGS) Util.xs > ../$util_c.xsc
\t\$(MV) $util_c.xsc $util_c

$util_o : $util_c
\t\$(CCCMD) -Ixs \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) -o $util_o $util_c

END_POSTAMBLE
}

# Remove lib/NetAddr/IP/Util.c from the clean target.
# EUMM adds C_FILES to clean automatically; we need this file tracked in git
# for CPAN distribution, so it must survive make clean.
sub MY::clean {
    package MY;
    my $inherited = shift->SUPER::clean(@_);
    $inherited =~ s{['"]?lib/NetAddr/IP/Util\.c['"]?\s*}{}g;
    $inherited;
}
