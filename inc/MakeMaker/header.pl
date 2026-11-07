use Config;
use Getopt::Long qw(GetOptions);

# an XS build writes these under lib/, where the next perl Makefile.PL would take them for module files
my @xs_outputs = qw(lib/NetAddr/IP/Util.c lib/NetAddr/IP/Util.c.xsc lib/NetAddr/IP/Util.o);

# and puts its shared object here, which a pure Perl build would install
my $xs_blib_dir = 'blib/arch/auto/NetAddr/IP/Util';

# where a plain perl Makefile.PL builds pure Perl, matched exactly against $^O
my %pure_perl_os = map { $_ => 1 } qw(cygwin dos MSWin32);

my $useXS;
GetOptions(
    'xs!' => \$useXS,
    'pm'  => sub {
        warn "\n\t" . 'WARNING: Use of "--pm" is deprecated, use "-noxs" instead' . "\n\n";
        $useXS = 0;
    },
);

print STDERR "building for $^O\n";

# pure Perl by default on Windows, Cygwin and DOS, unless --xs is given
if ( !defined $useXS && $pure_perl_os{$^O} ) {
    $useXS = 0;
}

# the compiler and linker MakeMaker writes into the Makefile: CC= and LD= on this command line, else perl's own
my %mm_tool = ( CC => $Config{cc}, LD => $Config{ld}, map { /\A(CC|LD)=(.+)\z/s ? ( $1 => $2 ) : () } @ARGV );

# build XS when that compiler works, unless --xs or -noxs was given
unless ( defined $useXS ) {
    if ( _test_cc( @mm_tool{qw(CC LD)} ) ) {
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

# drop the files an earlier XS build left; make writes them again
unlink @xs_outputs;

# a pure Perl build also drops the shared object an earlier XS build put in blib
unless ($useXS) {
    unlink glob "$xs_blib_dir/* $xs_blib_dir/.exists";
    rmdir $xs_blib_dir;
}

#
# Generate Util_IS.pm
#
my $util_is_path = 'lib/NetAddr/IP/Util_IS.pm';
open( F, '>', $util_is_path ) or die "Cannot write $util_is_path: $!\n";

# indented, so no line of Makefile.PL starts a POD command; the indent comes off below
my $util_is = q|#!/usr/bin/perl
    #
    # DO NOT ALTER THIS FILE
    # IT IS WRITTEN BY Makefile.PL
    # EDIT THAT INSTEAD
    #
    package NetAddr::IP::Util_IS;
    our $VERSION;
    $VERSION = 1.00;


    sub pure {
        return | . ( ($useXS) ? 0 : 1 ) . q|;
    }
    sub not_pure {
        return | . ( ($useXS) ? 1 : 0 ) . q|;
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
$util_is =~ s/^ {4}//mg;
print F $util_is;
close F;

#
# Set up extra WriteMakefile args, and the XS ones for an XS build
#
our @mm_args;
if ($useXS) {
    push @mm_args, (
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

# true when the given compiler and linker build and link an empty C program
sub _test_cc {
    my ( $cc, $ld ) = @_;
    print "Testing for a working C compiler, $cc...\n";
    require ExtUtils::CBuilder;

    # CBuilder reads these ahead of its config, where MakeMaker ignores them
    local %ENV = %ENV;
    delete @ENV{qw(CFLAGS LDFLAGS)};
    @ENV{qw(CC LD)} = ( $cc, $ld );
    return ExtUtils::CBuilder->new( quiet => 1 )->have_compiler;
}
