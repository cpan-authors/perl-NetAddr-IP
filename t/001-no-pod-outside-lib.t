#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use Cwd            qw(abs_path);
use File::Basename qw(dirname);
use File::Find     qw(find);
use File::Spec;

# A POD block inside a quoted string in some other file is still POD to a
# parser. MetaCPAN read the Util_IS.pm text that Makefile.PL writes and
# attributed it to the installer, so NetAddr::IP::Util_IS was documented by
# Makefile.PL rather than by the module it belongs to (GH#146). Nothing outside
# lib/ should carry a POD command, and the modules in lib/ are the only place
# one belongs.

my $root =
  abs_path( File::Spec->catdir( dirname(__FILE__), File::Spec->updir ) );

my @found;
find(
    {
        no_chdir => 1,
        wanted   => sub {
            return unless -f $_;
            my $path = $_;
            return if $path =~ m{/(?:blib|\.git)/};
            return if $path =~ m{/lib/};
            open my $fh, '<', $path or return;
            my $line = 0;
            while ( my $text = <$fh> ) {
                $line++;
                next unless $text =~ m{^=[a-zA-Z]};
                chomp $text;
                push @found, "$path line $line: $text";
            }
            close $fh;
        },
    },
    $root
);

ok( !@found, 'no file outside lib/ carries a POD command at column 0' )
  or diag( "found:\n  " . join "\n  ", @found );

done_testing;
