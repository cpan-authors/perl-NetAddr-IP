package MY;

# A pure Perl build has XSMULTI off, so MakeMaker would install the Util.xs
# file under lib/ as an ordinary module. Leave it out then; an XS build claims
# it through XSMULTI and does not install it.
sub libscan {
    my ($self, $path) = @_;
    return if !$useXS && $path =~ m{Util\.xs\z};
    return $path;
}
