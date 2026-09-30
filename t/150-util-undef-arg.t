#!/usr/bin/env perl

# An undefined packed address used to warn from inside the library before the
# check that reports it could run, because the check did its arithmetic on the
# undef that length() returns. The caller got a warning pointing at a line in
# the distribution, then a message that named the function but left the length
# blank, or said 0 for something that was never a length at all.
#
# NoWarnings below is the load-bearing part: if any of these calls warns
# again, the test fails even though the croak still happens.

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies lives );

use NetAddr::IP::InetBase qw(
  inet_ntoa
  ipv6_ntoa
);
use NetAddr::IP::Util qw(
  add128
  addconst
  bcd2bin
  bcdn2bin
  bcdn2txt
  bin2bcd
  bin2bcdn
  comp128
  hasbits
  ipanyto6
  ipv4to6
  ipv6to4
  mask4to6
  maskanyto6
  notcontiguous
  shiftleft
  simple_pack
  sub128
);

my $V6_PACKED_BYTES = 16;

# Every sub that guards a packed argument with length() and reports through
# _deadlen, rather than computing the length inline. Each entry is the
# wrapper that supplies the undefined argument, and the bit count the guard
# expects it to have. The XS build has a matching !SvOK branch for each of
# these, so CI runs the same expectations against both implementations.
#
# The undefined argument is spelled out rather than forwarded through @_,
# which does work, but only because perl flattens @_ for a sub that takes a
# scalar argument. Spelling it out keeps these expectations independent of how
# the XS prototypes interact with that flattening, so a test failure here
# always means the guard changed and not the call.
my @via_deadlen = (
    [ sub { hasbits(undef) },         128 ],
    [ sub { ipv4to6(undef) },         32 ],
    [ sub { mask4to6(undef) },        32 ],
    [ sub { bin2bcd(undef) },         128 ],
    [ sub { comp128(undef) },         128 ],
    [ sub { shiftleft( undef, 1 ) },  128 ],
    [ sub { ipv6to4(undef) },         128 ],
    [ sub { notcontiguous(undef) },   128 ],
    [ sub { add128( undef, undef ) }, 128 ],
    [ sub { addconst( undef, 1 ) },   128 ],
);

# These report a range rather than a single width, and the two implementations
# word them differently enough to be worth naming separately.
my @via_range = (
    [ 'ipanyto6',   sub { ipanyto6(undef) },   '32 or 128' ],
    [ 'maskanyto6', sub { maskanyto6(undef) }, '32 or 128' ],
);

# ------------------------------------------------------- undefined argument

subtest 'an undefined argument is named as undefined, not measured' => sub {
    like(
        dies { inet_ntoa(undef) },
        qr/^Bad arg length for \S+inet_ntoa, length is undefined should be 4/,
        'inet_ntoa says the length is undefined'
    );

    like(
        dies { ipv6_ntoa(undef) },
        qr/^Bad arg length for \S+ipv6_ntoa, length is undefined should be 16/,
'ipv6_ntoa says the length is undefined, rather than passing undef to inet_ntop'
    );

    for my $case (@via_deadlen) {
        my ( $thrower, $bits ) = @$case;
        like(
            dies { $thrower->(undef) },
qr/^Bad arg length for \S+, length is undefined, should be \Q$bits\E/,
            'reports the length as undefined'
        );
    }

    for my $case (@via_range) {
        my ( $name, $thrower, $should ) = @$case;
        like(
            dies { $thrower->(undef) },
qr/^Bad arg length for \S+\Q$name\E, length is undefined, should be \Q$should\E/,
            "$name names the widths it accepts"
        );
    }

    like(
        dies { sub128( undef, undef ) },
        qr/^Bad arg length for \S+sub128, length is undefined, should be 128/,
        'sub128 reports the first of its two undefined arguments'
    );

    like(
        dies { bcdn2txt(undef) },
qr/^Bad arg length for \S+bcdn2txt, length is undefined, should be 40 digits/,
        'bcdn2txt says the length is undefined'
    );

    like(
        dies { bcdn2bin( undef, 40 ) },
qr/^Bad arg length for \S+bcdn2bin, length is undefined, should be 1 to 40 digits/,
        'bcdn2bin says the length is undefined'
    );

    like(
        dies { bcd2bin(undef) },
qr/^Bad arg length for \S+bcd2bin, length is undefined, should be 1 to 40 digits/,
        'bcd2bin says the length is undefined'
    );

    like(
        dies { simple_pack(undef) },
qr/^Bad arg length for \S+simple_pack, length is undefined, should be 1 to 40 digits/,
        'simple_pack says the length is undefined'
    );

    like(
        dies { bin2bcdn(undef) },
        qr/^Bad arg length for \S+bin2bcdn, length is undefined, should be 128/,
        'bin2bcdn says the length is undefined'
    );
};

# ------------------------------------------- defined but wrongly sized input

# The fix adds a defined test, not a redefinition of the length test, so a
# real short or long argument must still be measured and reported as its
# actual length.

subtest 'a defined argument of the wrong length is still measured' => sub {
    like(
        dies { inet_ntoa('') },
        qr/^Bad arg length for \S+inet_ntoa, length is 0 should be 4/,
        'an empty string measures 0'
    );

    like(
        dies { inet_ntoa('ab') },
        qr/^Bad arg length for \S+inet_ntoa, length is 2 should be 4/,
        'a two byte string measures 2'
    );

    like(
        dies { hasbits('ab') },
        qr/^Bad arg length for \S+hasbits, length is 16, should be 128/,
        'a two byte string measures 16 bits'
    );

    like(
        dies { bcdn2txt( "\x11" x 21 ) },
        qr/^Bad arg length for \S+bcdn2txt, length is 42, should be 40 digits/,
        'bcdn2txt still converts bytes to digits before reporting'
    );
};

# ---------------------------------------------------------- valid input

subtest 'arguments of the right length are unaffected' => sub {
    is( inet_ntoa( pack( 'C4', 10, 4, 12, 123 ) ),
        '10.4.12.123', 'inet_ntoa of a four byte address' );
    is(
        ipv6_ntoa( pack( 'C16', 1 .. 16 ) ),
        '102:304:506:708:90a:b0c:d0e:f10',
        'ipv6_ntoa of a sixteen byte address'
    );
    is( hasbits( pack( 'C16', 1 .. 16 ) ),
        1, 'hasbits of a sixteen byte address' );
    is( length( ipv4to6( pack( 'C4', 10, 4, 12, 123 ) ) ),
        $V6_PACKED_BYTES, 'ipv4to6 widens a four byte address' );
    is( length( mask4to6( pack( 'C4', 10, 4, 12, 123 ) ) ),
        $V6_PACKED_BYTES, 'mask4to6 widens a four byte mask' );
    my $bcd = bin2bcd( pack( 'C16', 1 .. 16 ) );
    like( $bcd, qr/^\d+$/, 'bin2bcd returns decimal text digits' );
    cmp_ok( length($bcd), '<=', 39,
        'bin2bcd of a 128 bit value needs at most 39 digits' );
    cmp_ok( length( bin2bcdn( pack( 'C16', 1 .. 16 ) ) ),
        '<=', 20, 'bin2bcdn packs those digits into at most 20 bytes' );
    is( bcdn2txt( "\x11" x 20 ), '1' x 40, 'bcdn2txt of twenty bytes' );

    # L3a4 puts the three leading words first, so the widened address keeps
    # the original four bytes at the end.
    is(
        ipanyto6( pack( 'C4', 10, 4, 12, 123 ) ),
        ( "\0" x 12 ) . pack( 'C4', 10, 4, 12, 123 ),
        'ipanyto6 widens a four byte address'
    );
    is(
        maskanyto6( pack( 'C4', 10, 4, 12, 123 ) ),
        ( "\xff" x 12 ) . pack( 'C4', 10, 4, 12, 123 ),
        'maskanyto6 widens a four byte mask'
    );
    is(
        ipv6to4( ( "\0" x 10 ) . "\xff\xff" . pack( 'C4', 10, 4, 12, 123 ) ),
        pack( 'C4', 10, 4, 12, 123 ),
        'ipv6to4 narrows a v4 mapped address'
    );
    is( length( bin2bcdn( "\0" x 16 ) ),
        20, 'bin2bcdn pads to the twenty byte packed BCD width' );

    lives { comp128( pack( 'C16', 1 .. 16 ), pack( 'C16', reverse 1 .. 16 ) ) }
      and pass('comp128 of two sixteen byte addresses');
    lives { sub128( pack( 'C16', 1 .. 16 ), pack( 'C16', reverse 1 .. 16 ) ) }
      and pass('sub128 of two sixteen byte addresses');
    lives { notcontiguous( pack( 'C16', 1 .. 16 ) ) }
      and pass('notcontiguous of a sixteen byte address');
    lives { shiftleft( pack( 'C16', 1 .. 16 ), 1 ) }
      and pass('shiftleft of a sixteen byte address');
};

done_testing;
