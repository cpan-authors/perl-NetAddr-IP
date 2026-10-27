#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( comp128 ipv6_aton ipv6_n2x );

my %tests = (
    '::' => 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF',
    'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF' => '0:0:0:0:0:0:0:0',
    'A1B2:C3D4:E5D6:F7E8:08F9:190A:2A1B:3B4C' =>
      '5E4D:3C2B:1A29:817:F706:E6F5:D5E4:C4B3',
);

for my $input ( sort keys %tests ) {
    my $bstr = ipv6_aton($input);
    my $cnum = comp128($bstr);
    my $rv   = ipv6_n2x($cnum);
    my $exp  = $tests{$input};
    is( $rv, $exp, "comp128($input)" );
}

subtest 'comp128 reads its first argument alike in both builds' => sub {
    is( prototype('NetAddr::IP::Util::comp128'),
        '$;@', 'comp128 has the prototype $;@' );

    my $arg = NetAddr::IP::Util::ipv6_aton('2001:db8::1');

    # in list context this returns a name and the argument, as a lookup does
    my $answer = sub { return wantarray ? ( 'host.example', $arg ) : $arg };
    is( eval { comp128( $answer->() ) },
        comp128($arg),
        'a first argument that returns a list is read in scalar context' );
    is( $@, '', 'that call does not croak' );
};

done_testing;
