#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( ipv6_aton ipv6_n2x shiftleft );

my @num =    # input	shift	expected
  (
    [ '1::1', 'none', '1:0:0:0:0:0:0:1' ],
    [ '1::1', '0',    '1:0:0:0:0:0:0:1' ],
    [ '1::1', '1',    '2:0:0:0:0:0:0:2' ],
    [ '1::1', '2',    '4:0:0:0:0:0:0:4' ],
    [ '1::1', '3',    '8:0:0:0:0:0:0:8' ],
    [ '1::1', '15',   '8000:0:0:0:0:0:0:8000' ],
    [ '1::1', '16',   '0:0:0:0:0:0:1:0' ],
    [ '1::1', '128',  '0:0:0:0:0:0:0:0' ],
  );

for my $entry (@num) {
    my ( $input, $shift, $expected ) = @$entry;
    my $bstr = ipv6_aton($input);
    my $rv;
    if ( $shift =~ m/[^\d]/ ) {
        $rv = shiftleft($bstr);
    }
    else {
        $rv = shiftleft( $bstr, $shift );
    }
    my $got = ipv6_n2x($rv);
    is( $got, $expected, "shiftleft($input, $shift)" );
}

subtest 'shiftleft reads its first argument alike in both builds' => sub {
    is( prototype('NetAddr::IP::Util::shiftleft'),
        '$;@', 'shiftleft has the prototype $;@' );

    my $arg = NetAddr::IP::Util::ipv6_aton('2001:db8::1');

    # in list context this returns a name and the argument, as a lookup does
    my $answer = sub { return wantarray ? ( 'host.example', $arg ) : $arg };
    is(
        eval { shiftleft( $answer->(), 1 ) },
        shiftleft( $arg, 1 ),
        'a first argument that returns a list is read in scalar context'
    );
    is( $@, '', 'that call does not croak' );
};

done_testing;
