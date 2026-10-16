#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use ExtUtils::Manifest qw(maniread);

# A POD block inside a quoted string in some other file is still POD to a
# parser. MetaCPAN read the Util_IS.pm text that Makefile.PL writes and
# attributed it to the installer, so NetAddr::IP::Util_IS was documented by
# Makefile.PL rather than by the module it belongs to (GH#146). Nothing outside
# lib/ should carry a POD command, and the modules in lib/ are the only place
# one belongs.
#
# The list of files to read is MANIFEST, not a walk of the working tree. On
# Windows actions-setup-perl installs the dependencies into local/lib/perl5
# inside the checkout, where cpanel_json_xs arrives in local/bin carrying POD
# of its own. A walk reads other people's files and then fails on them, which
# is what it did, on all five Windows jobs.

if ( !-f 'MANIFEST' ) {
    skip_all('no MANIFEST here, so there is no shipped file list to read');
}

my $files = maniread('MANIFEST');

my @found;
for my $file ( sort keys %{$files} ) {
    next if $file =~ m{^lib/};
    my $fh;
    if ( !open $fh, '<', $file ) {
        push @found, "$file: unreadable, and the distribution ships it";
        next;
    }
    my $line = 0;
    while ( my $text = <$fh> ) {
        $line++;
        next unless $text =~ m{^=[a-zA-Z]};
        chomp $text;
        push @found, "$file line $line: $text";
    }
    close $fh;
}

ok( !@found, 'no shipped file outside lib/ carries a POD command at column 0' )
  or diag( "found:\n  " . join "\n  ", @found );

done_testing;
