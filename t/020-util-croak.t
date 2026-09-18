#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Util qw(
    add128
    bcd2bin
    bcdn2bin
    bcdn2txt
    bin2bcd
    bin2bcdn
    comp128
    hasbits
    isIPv4
    shiftleft
    simple_pack
    sub128
);

## simple_pack – bad character input

for my $input (
	'1234/',
	'1234:',
	'a1234',
	'&1234',
	"\x{0663}\x{0663}\x{0663}\x{0663}",	# Arabic-Indic digits
	"\x{0969}\x{0969}\x{0969}\x{0969}",	# Devanagari digits
	"\x{FF13}\x{FF13}\x{FF13}\x{FF13}",	# Fullwidth digits
) {
	like(dies { simple_pack($input) }, qr/Bad/, "simple_pack dies on non-ASCII digit input");
}

## bcd2bin – bad character input

for my $input (
	'1234/',
	'1234:',
	'a1234',
	'&1234',
) {
	like(dies { bcd2bin($input) }, qr/Bad/, "bcd2bin dies on '$input'");
}

## bcdn2bin – bad vector string length

like(dies { bcdn2bin('123456789012345678901') }, qr/Bad/, 'bcdn2bin dies on bad length');

## bcdn2bin – missing length specifier

like(dies { bcdn2bin('12345678901234567890') }, qr/Bad/, 'bcdn2bin dies on missing length specifier');

## bin2bcd – bad vector string length

like(dies { bin2bcd('123') }, qr/Bad/, 'bin2bcd dies on bad length');

## bin2bcdn – bad vector string length

like(dies { bin2bcdn('123') }, qr/Bad/, 'bin2bcdn dies on bad length');

## bcdn2txt – bad vector string length

like(dies { bcdn2txt('123456789012345678901') }, qr/Bad/, 'bcdn2txt dies on bad length');

## bcdn2txt – success case

my $rv  = bcdn2txt('12345678901234567890');
my $exp = '3132333435363738393031323334353637383930';
is($rv, $exp, 'bcdn2txt returns expected value');

## hasbits – bad vector string length

like(dies { hasbits('123') }, qr/Bad/, 'hasbits dies on bad length');

## isIPv4 – bad vector string length

like(dies { isIPv4('12345678901234567') }, qr/Bad/, 'isIPv4 dies on bad length');

## add128 – bad vector string length

like(dies { add128('123', '1234567890123456') }, qr/Bad/, 'add128 dies on bad length');

## sub128 – bad vector string length

like(dies { sub128('1234567890123456', '12345678901234567') }, qr/Bad/, 'sub128 dies on bad length');

## comp128 – bad vector string length

like(dies { comp128('123') }, qr/Bad/, 'comp128 dies on bad length');

## shiftleft – bad vector string length

like(dies { shiftleft('12345678901234567') }, qr/Bad/, 'shiftleft dies on bad length');

## shiftleft – bad shift count (negative)

like(dies { shiftleft('1234567890123456', -1) }, qr/Bad/, 'shiftleft dies on negative shift count');

## shiftleft – bad shift count (too large)

like(dies { shiftleft('1234567890123456', 129) }, qr/Bad/, 'shiftleft dies on shift count too large');

## bcd2bin – empty string

like(dies { bcd2bin('') }, qr/Bad/, 'bcd2bin dies on empty string');

## simple_pack – empty string

like(dies { simple_pack('') }, qr/Bad/, 'simple_pack dies on empty string');

## bcdn2txt – empty string

like(dies { bcdn2txt('') }, qr/Bad/, 'bcdn2txt dies on empty string');

## bcdn2bin – empty string

like(dies { bcdn2bin('', 40) }, qr/Bad/, 'bcdn2bin dies on empty string');

## bcdn2bin – digit count larger than packed string

like(dies { bcdn2bin("\x12", 40) }, qr/Bad/, 'bcdn2bin dies on digit count larger than input');

## bcdn2bin - over-long packed input reports its length in digits, like every other length croak

like(dies { bcdn2bin("\x12" x 21, 40) }, qr/Bad.*length.*42.*should be 1 to 40 digits/,
    'bcdn2bin reports 21 packed bytes as 42 digits');
like(dies { bcdn2bin("\x12" x 41, 40) }, qr/Bad.*length.*82.*should be 1 to 40 digits/,
    'bcdn2bin reports 41 packed bytes as 82 digits');

## bcd2bin – values that do not fit in 128 bits must die

like(dies { bcd2bin('340282366920938463463374607431768211456') },
    qr/larger than 128 bits/, 'bcd2bin dies on 2**128');
like(dies { bcd2bin('9' x 40) },
    qr/larger than 128 bits/, 'bcd2bin dies on 40 nines');

## bcdn2bin – values that do not fit in 128 bits must die

like(dies { bcdn2bin(simple_pack('340282366920938463463374607431768211456'), 40) },
    qr/larger than 128 bits/, 'bcdn2bin dies on 2**128');

done_testing;
