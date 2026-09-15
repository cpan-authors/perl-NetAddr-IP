package MY;

sub top_targets {
    my $inherited = shift->SUPER::top_targets(@_);
    $main::begin . $inherited;
}

sub postamble {
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
sub clean {
    my $inherited = shift->SUPER::clean(@_);
    $inherited =~ s{['"]?lib/NetAddr/IP/Util\.c['"]?\s*}{}g;
    $inherited;
}
