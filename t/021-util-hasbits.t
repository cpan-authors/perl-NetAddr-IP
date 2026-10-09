#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use Config;
use NetAddr::IP::Util
  qw( add128 hasbits inet_aton ipv4to6 ipv6_aton ipv6_n2x mask4to6 );

my $POINTER_FORMAT = $Config{ptrsize} == 8 ? 'Q' : 'L';
my $WORD_BYTES     = 4;

# Address of the caller's own string buffer, read through the alias in @_
# because a copy would get a new buffer.
sub buffer_address {    ## no critic (Subroutines::RequireArgUnpacking)
    return unpack $POINTER_FORMAT, pack 'p', $_[0];
}

# Copies the bytes behind a leading byte and chops that byte, so the buffer
# starts off word alignment; returns a reference since returning a scalar copies it.
sub offset_copy {
    my ( $bytes, $label ) = @_;
    my $offset = 'X' . $bytes;
    substr $offset, 0, 1, '';
    isnt( buffer_address($offset) % $WORD_BYTES,
        0, "$label buffer is not word aligned" );
    return \$offset;
}

my @num = (
    '::',               '8000::',
    '4000::',           '2000::',
    '1000::',           '800::',
    '400::',            '200::',
    '100::',            '80::',
    '40::',             '20::',
    '10::',             '1::',
    '0:8000::',         '0:4000::',
    '0:2000::',         '0:1000::',
    '0:800::',          '0:400::',
    '0:200::',          '0:100::',
    '0:80::',           '0:40::',
    '0:20::',           '0:10::',
    '0:1::',            '0:0:8000::',
    '0:0:4000::',       '0:0:2000::',
    '0:0:1000::',       '0:0:800::',
    '0:0:400::',        '0:0:200::',
    '0:0:100::',        '0:0:80::',
    '0:0:40::',         '0:0:20::',
    '0:0:10::',         '0:0:1::',
    '0:0:0:8000::',     '0:0:0:4000::',
    '0:0:0:2000::',     '0:0:0:1000::',
    '0:0:0:800::',      '0:0:0:400::',
    '0:0:0:200::',      '0:0:0:100::',
    '0:0:0:80::',       '0:0:0:40::',
    '0:0:0:20::',       '0:0:0:10::',
    '0:0:0:1::',        '::8000:0:0:0',
    '::4000:0:0:0',     '::2000:0:0:0',
    '::1000:0:0:0',     '::800:0:0:0',
    '::400:0:0:0',      '::200:0:0:0',
    '::100:0:0:0',      '::80:0:0:0',
    '::40:0:0:0',       '::20:0:0:0',
    '::10:0:0:0',       '::1:0:0:0',
    '::8000:0:0',       '::4000:0:0',
    '::2000:0:0',       '::1000:0:0',
    '::800:0:0',        '::400:0:0',
    '::200:0:0',        '::100:0:0',
    '::80:0:0',         '::40:0:0',
    '::20:0:0',         '::10:0:0',
    '::1:0:0',          '::8000:0',
    '::4000:0',         '::2000:0',
    '::1000:0',         '::800:0',
    '::400:0',          '::200:0',
    '::100:0',          '::80:0',
    '::40:0',           '::20:0',
    '::10:0',           '::1:0',
    '::8000',           '::4000',
    '::2000',           '::1000',
    '::800',            '::400',
    '::200',            '::100',
    '::80',             '::40',
    '::20',             '::10',
    '::1',              '::8000:0:0:0:0',
    '::8000:0:0:0:0:0', '::8000:0:0:0:0:0:0',
    '8000:0:0:0:0:0:0:0',
);

for my $input (@num) {
    my $bstr = ipv6_aton($input);
    my $rv   = hasbits($bstr);
    my $exp  = ( $input eq '::' ) ? 0 : 1;
    is( $rv, $exp, 'hasbits for ' . ipv6_n2x($bstr) );
}

subtest 'hasbits on an offset, misaligned buffer matches a fresh copy' => sub {
    for my $input ( '::', '::1', '2001:db8::' ) {
        my $fresh  = ipv6_aton($input);
        my $offset = offset_copy( $fresh, "hasbits $input" );
        is( hasbits( ${$offset} ),
            hasbits($fresh), "hasbits $input on an offset buffer" );
    }
};

subtest 'ipv4to6 on an offset, misaligned buffer matches a fresh copy' => sub {
    for my $input ( '0.0.0.0', '192.0.2.1', '203.0.113.255' ) {
        my $fresh  = inet_aton($input);
        my $offset = offset_copy( $fresh, "ipv4to6 $input" );
        is(
            ipv6_n2x( ipv4to6( ${$offset} ) ),
            ipv6_n2x( ipv4to6($fresh) ),
            "ipv4to6 $input on an offset buffer"
        );
    }
};

subtest 'add128 on offset, misaligned buffers matches fresh copies' => sub {
    for my $pair (
        [ '2001:db8::1',          '2001:db8::ffff' ],
        [ '2001:db8:ffff:ffff::', '2001:db8::1' ]
      )
    {
        my ( $fresh_a, $fresh_b ) = map { ipv6_aton($_) } @{$pair};
        my $offset_a = offset_copy( $fresh_a, "add128 $pair->[0]" );
        my $offset_b = offset_copy( $fresh_b, "add128 $pair->[1]" );
        my ( $carry, $sum )             = add128( ${$offset_a}, ${$offset_b} );
        my ( $fresh_carry, $fresh_sum ) = add128( $fresh_a, $fresh_b );
        is(
            [ $carry,       ipv6_n2x($sum) ],
            [ $fresh_carry, ipv6_n2x($fresh_sum) ],
            "add128 $pair->[0] + $pair->[1] on offset buffers"
        );
    }
};

subtest 'mask4to6 on an offset, misaligned buffer matches a fresh copy' => sub {
    for my $input ( '255.255.255.0', '255.255.255.255' ) {
        my $fresh  = inet_aton($input);
        my $offset = offset_copy( $fresh, "mask4to6 $input" );
        is(
            ipv6_n2x( mask4to6( ${$offset} ) ),
            ipv6_n2x( mask4to6($fresh) ),
            "mask4to6 $input on an offset buffer"
        );
    }
};

done_testing;
