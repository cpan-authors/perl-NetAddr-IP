#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw( dies lives );

use NetAddr::IP::Util qw(
	bcd2bin
	bcdn2bin
	bcdn2txt
	bin2bcd
	bin2bcdn
	simple_pack
);

my $BCD_DIGITS_MAX   = 40;	# digits a 128 bit value can need
my $BCD_PACKED_BYTES = 20;	# bytes holding those digits
my $BIN_BYTES        = 16;	# bytes of a 128 bit address

my $two127_39 = '170141183460469231731687303715884105728';	# 2**127, 39 digits
my $two127_40 = '0' . $two127_39;				# same, padded to the max width
my $two127_bin = "\x80" . ("\0" x 15);

sub hex_of { return unpack 'H*', shift }

# ---------------------------------------------------------------- valid input

subtest 'valid input still converts, so the boundary checks do not overreach' => sub {
    is(hex_of(bcd2bin('0')), '0' x 32, 'bcd2bin of one zero digit');
    is(hex_of(bcd2bin('1')), ('0' x 31) . '1', 'bcd2bin of one nonzero digit');
    is(hex_of(bcd2bin($two127_39)), hex_of($two127_bin),
	'bcd2bin of 39 digits, the widest value that fits');
    is(hex_of(bcd2bin($two127_40)), hex_of($two127_bin),
	"bcd2bin of $BCD_DIGITS_MAX digits, the maximum accepted width");

    is(length(simple_pack('1')), $BCD_PACKED_BYTES, 'simple_pack of one digit packs to 20 bytes');
    is(unpack('H40', simple_pack($two127_40)), $two127_40,
	"simple_pack of $BCD_DIGITS_MAX digits round trips");

    is(length(bin2bcdn($two127_bin)), $BCD_PACKED_BYTES,
	"bin2bcdn of $BIN_BYTES bytes packs to $BCD_PACKED_BYTES bytes");
    is(bin2bcd($two127_bin), $two127_39, "bin2bcd of $BIN_BYTES bytes gives the decimal text");

    is(bcdn2txt(bin2bcdn($two127_bin)), $two127_39,
	"bcdn2txt of exactly $BCD_PACKED_BYTES packed bytes");
    is(bcdn2txt("\x11" x $BCD_PACKED_BYTES), '1' x $BCD_DIGITS_MAX,
	"bcdn2txt of $BCD_PACKED_BYTES packed bytes gives $BCD_DIGITS_MAX digits");

    is(hex_of(bcdn2bin("\x12", 2)), ('0' x 31) . 'c', 'bcdn2bin of one packed byte, 2 digits');
    is(hex_of(bcdn2bin(pack('H40', $two127_40), $BCD_DIGITS_MAX)), hex_of($two127_bin),
	"bcdn2bin of $BCD_PACKED_BYTES packed bytes, $BCD_DIGITS_MAX digits");
};

# --------------------------------------------------------------- empty string

subtest 'an empty string is rejected by every bcd entry point' => sub {
    like(dies { bcd2bin('') }, qr/Bad/, 'bcd2bin of an empty string dies');
    like(dies { simple_pack('') }, qr/Bad/, 'simple_pack of an empty string dies');
    like(dies { bcdn2txt('') }, qr/Bad/, 'bcdn2txt of an empty string dies');
    like(dies { bcdn2bin('', $BCD_DIGITS_MAX) }, qr/Bad/, 'bcdn2bin of an empty string dies');
    like(dies { bin2bcd('') }, qr/Bad/, 'bin2bcd of an empty string dies');
    like(dies { bin2bcdn('') }, qr/Bad/, 'bin2bcdn of an empty string dies');
};

# ------------------------------------------------------------------- one byte

subtest 'a one byte argument is accepted only where one byte is a whole value' => sub {
    is(hex_of(bcdn2bin("\x12", 1)), ('0' x 31) . '1', 'bcdn2bin of one packed byte, 1 digit');
    is(length(simple_pack('7')), $BCD_PACKED_BYTES, 'simple_pack of one digit');

    like(dies { bcdn2txt("\x12") }, qr/Bad/, "bcdn2txt of 1 byte dies, it needs $BCD_PACKED_BYTES");
    like(dies { bin2bcd("\x01") }, qr/Bad/, "bin2bcd of 1 byte dies, it needs $BIN_BYTES");
};

# ---------------------------------------------------- one below and one above

subtest "one below and one above the $BIN_BYTES byte binary width" => sub {
    like(dies { bin2bcd("\0" x ($BIN_BYTES - 1)) }, qr/Bad/, 'bin2bcd of 15 bytes dies');
    like(dies { bin2bcd("\0" x ($BIN_BYTES + 1)) }, qr/Bad/, 'bin2bcd of 17 bytes dies');
    like(dies { bin2bcdn("\0" x ($BIN_BYTES - 1)) }, qr/Bad/, 'bin2bcdn of 15 bytes dies');
    like(dies { bin2bcdn("\0" x ($BIN_BYTES + 1)) }, qr/Bad/, 'bin2bcdn of 17 bytes dies');

    is(bin2bcd("\0" x $BIN_BYTES), '0', "bin2bcd of exactly $BIN_BYTES bytes lives");
};

subtest "one below and one above the $BCD_PACKED_BYTES byte packed bcd width" => sub {
    like(dies { bcdn2txt("\x11" x ($BCD_PACKED_BYTES - 1)) }, qr/Bad/, 'bcdn2txt of 19 packed bytes dies');
    like(dies { bcdn2txt("\x11" x ($BCD_PACKED_BYTES + 1)) }, qr/Bad/, 'bcdn2txt of 21 packed bytes dies');
    like(dies { bcdn2bin("\x11" x ($BCD_PACKED_BYTES + 1), $BCD_DIGITS_MAX) }, qr/Bad/, 'bcdn2bin of 21 packed bytes dies');

    is(bcdn2txt("\x00" x $BCD_PACKED_BYTES), '0',
	"bcdn2txt of exactly $BCD_PACKED_BYTES packed bytes lives");
};

subtest "one below and one above the $BCD_DIGITS_MAX digit text width" => sub {
    is(length(bcd2bin('1' x ($BCD_DIGITS_MAX - 1))), $BIN_BYTES, 'bcd2bin of 39 digits lives');
    is(length(simple_pack('1' x ($BCD_DIGITS_MAX - 1))), $BCD_PACKED_BYTES,
	'simple_pack of 39 digits lives');

    like(dies { bcd2bin('1' x ($BCD_DIGITS_MAX + 1)) }, qr/Bad/, 'bcd2bin of 41 digits dies');
    like(dies { simple_pack('1' x ($BCD_DIGITS_MAX + 1)) }, qr/Bad/, 'simple_pack of 41 digits dies');
};

# ---------------------------------------------- caller supplied digit count

subtest 'bcdn2bin checks the caller digit count against the buffer it was given' => sub {
    like(dies { bcdn2bin("\x12", $BCD_DIGITS_MAX) }, qr/Bad/, 'bcdn2bin of 1 byte with a count of 40 dies');
    like(dies { bcdn2bin("\x12", 3) }, qr/Bad/, 'bcdn2bin of 1 byte with a count of 3 dies');
    like(dies { bcdn2bin(pack('H20', '1' x 20), $BCD_DIGITS_MAX) }, qr/Bad/, 'bcdn2bin of 10 bytes with a count of 40 dies');
    like(dies { bcdn2bin("\x12", 0) }, qr/Bad/, 'bcdn2bin with a count of 0 dies');
    like(dies { bcdn2bin("\x12", -1) }, qr/Bad/, 'bcdn2bin with a negative count dies');

    is(hex_of(bcdn2bin(pack('H4', '1234'), 4)), ('0' x 28) . '04d2',
	'bcdn2bin of 2 bytes with a count of 4 is unchanged');
    is(hex_of(bcdn2bin(pack('H4', '1234'), 2)), ('0' x 30) . '0c',
	'bcdn2bin of 2 bytes with a count of 2 reads only the first byte');
};

# ------------------------------------------------------------ croak names

subtest 'croak names name the correct function' => sub {
    like(dies { bcdn2bin('1' x ($BCD_DIGITS_MAX + 1)) }, qr/bcdn2bin/, 'the over-long bcdn2bin croak names bcdn2bin');
    like(dies { bcdn2bin('1' x ($BCD_PACKED_BYTES + 1)) }, qr/bcdn2bin/, 'the over-long packed bcdn2bin croak names bcdn2bin');
    like(dies { bcd2bin('1' x ($BCD_DIGITS_MAX + 1)) }, qr/bcd2bin/, 'the over-long bcd2bin croak names bcd2bin');
    like(dies { simple_pack('1' x ($BCD_DIGITS_MAX + 1)) }, qr/simple_pack/, 'the over-long simple_pack croak names simple_pack');
};

done_testing;
