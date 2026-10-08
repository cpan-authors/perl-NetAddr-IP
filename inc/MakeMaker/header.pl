use Config;
use Getopt::Long qw(GetOptions);

# an XS build writes these under lib/, where a pure Perl build would copy them into blib
my @xs_outputs = qw(lib/NetAddr/IP/Util.c lib/NetAddr/IP/Util.c.xsc lib/NetAddr/IP/Util.o);

# and puts its shared object here, which a pure Perl build would install
my $xs_blib_dir = 'blib/arch/auto/NetAddr/IP/Util';

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

# a pure Perl build drops what an earlier XS build left behind
unless ($useXS) {
    unlink @xs_outputs, glob "$xs_blib_dir/* $xs_blib_dir/.exists";
    rmdir $xs_blib_dir;
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

  my $is_pure = NetAddr::IP::Util_IS->pure();
  my $is_xs   = NetAddr::IP::Util_IS->not_pure();

=head1 DESCRIPTION

Util_IS indicates whether or not B<NetAddr::IP::Util> was compiled in Pure
Perl mode.

=over 4

=item C<pure()>

Returns true if PurePerl mode, else false.

=item C<not_pure()>

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

# make clean removes the file Makefile.PL writes and the XS build's output
push @mm_args, clean => { FILES => join q{ }, $util_is_path, @xs_outputs };

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
