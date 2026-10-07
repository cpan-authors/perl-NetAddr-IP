use Config;
use Getopt::Long qw(GetOptions);

my $useXS;
GetOptions(
    'xs!' => \$useXS,
    'pm'  => sub {
        warn "\n\t" . 'WARNING: Use of "--pm" is deprecated, use "-noxs" instead' . "\n\n";
        $useXS = 0;
    },
);

print STDERR "building for $^O\n";

# pure Perl by default on Windows, Cygwin, macOS and DOS, unless --xs is given
if (!defined $useXS && ($Config{osname} =~ /win/i || $Config{osname} eq 'dos')) {
    $useXS = 0;
}

# build XS when a C compiler works, unless --xs or -noxs was given
unless (defined $useXS) {
    my $compiler = _test_cc();
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
our $VERSION;
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

=item $rv = NetAddr::IP::Util_IS->pure;

Returns true if PurePerl mode, else false.

=item $rv = NetAddr::IP::Util_IS->not_pure;

Returns true if NOT PurePerl mode, else false

=back

=cut

1;
|;
close F;

#
# Set up extra WriteMakefile args for XS build
#
our @mm_args;
if ($useXS) {
    @mm_args = (
        NAME   => 'NetAddr::IP::Util',
        XS     => { 'xs/Util.xs' => 'lib/NetAddr/IP/Util.c' },
        C      => ['lib/NetAddr/IP/Util.c'],
        OBJECT => 'lib/NetAddr/IP/Util.o',
        INC    => '-Ixs',
        LIBS   => [],
        depend => { 'lib/NetAddr/IP/Util.c' => 'xs/localconf.h' },
    );
}

# make clean removes the files Makefile.PL rewrites on every run.
# The XS build also writes Util.o and Util.c under lib/, where ExtUtils::MakeMaker
# does not look for them: its C_FILES and OBJECT are set only when $useXS is true,
# so in a pure Perl build neither is known and a stray Util.o left by an earlier
# XS build is picked up as a module to copy into blib. That pulls the postamble's
# xsubpp rule into the build, where $(XSUBPP) is undefined in a pure Perl Makefile
# and it dies on "-ypemap". Both are generated, so both go.
push @mm_args,
    clean => {
        FILES => join q{ },
        'lib/NetAddr/IP/Util_IS.pm',
        'lib/NetAddr/IP/Util.c',
        'lib/NetAddr/IP/Util.o',
        'lib/NetAddr/IP/Util.c.xsc',
        'xs/localperl.h',
    };

sub _test_cc {
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
