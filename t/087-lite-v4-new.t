#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Warnings qw(no_warnings);

use NetAddr::IP::Lite ();

my $binword;
my $wn = no_warnings { $binword = eval { 0b11111111111111110000000000000000 } };
if ($@) {
    $binword = 0xffff0000;
    note(
        "\t\tskipped! 0b11111111111111110000000000000000",
        "\t\tbinary bit strings unsupported in Perl version $]"
    );
}

my @a = (
    { 'localhost'  => '127.0.0.1' },
    { 0x01010101  => '1.1.1.1' },
    { 1           => '1.0.0.0' },
    { 'default'   => '0.0.0.0' },
    { 'any'       => '0.0.0.0' },
    { -809041407  => '207.199.2.1' },
    { 3485925889  => '207.199.2.1' },
);

my @m = (
    { 0                   => '0.0.0.0' },
    { 1                   => '128.0.0.0' },
    { 2                   => '192.0.0.0' },
    { 4                   => '240.0.0.0' },
    { 8                   => '255.0.0.0' },
    { 16                  => '255.255.0.0' },
    { 17                  => '255.255.128.0' },
    { 24                  => '255.255.255.0' },
    { 'default'           => '0.0.0.0' },
    { 32                  => '255.255.255.255' },
    { 'host'              => '255.255.255.255' },
    { 0xffffff00          => '255.255.255.0' },
    { '255.255.255.240'   => '255.255.255.240' },
    { '255.255.128.0'     => '255.255.128.0' },
    { $binword            => '255.255.0.0' },
);

for my $invalid (qw(
    256.1.1.1
    256.256.1.1
    256.256.256.1
    256.256.256.256
)) {
    ok(
        !defined NetAddr::IP::Lite->new($invalid),
        "Invalid IP $invalid returns undef"
    );
}

for my $entry (@a) {
    for my $m (@m) {
        my ($input,      $expected_addr) = %$entry;
        my ($mask_input, $expected_mask) = %$m;
        my $ip = NetAddr::IP::Lite->new($input, $mask_input);
    SKIP: {
            skip "Failed to make an object for $input/$mask_input", 4
                unless defined $ip;
            is($ip->addr, $expected_addr, "$input / $mask_input is $expected_addr");
            is($ip->mask, $expected_mask, "$input / $mask_input is $expected_mask");
            is($ip->bits, 32,             "$input / $mask_input is 32 bits wide");
            is($ip->version, 4,           "$input / $mask_input is version 4");
        };
    }
}

## issue #5 – trailing newline accepted, leading whitespace rejected

is(NetAddr::IP::Lite->new("10.0.0.1\n"), "10.0.0.1/32", 'trailing newline accepted');
is(NetAddr::IP::Lite->new(" 10.0.0.1"), "10.0.0.1/32", 'leading space accepted');
is(NetAddr::IP::Lite->new("10.0.0.1 "), "10.0.0.1/32", 'trailing space accepted');
is(NetAddr::IP::Lite->new("10.0.0.1/24\n"), "10.0.0.1/24", 'trailing newline with CIDR accepted');
is(NetAddr::IP::Lite->new("  "), undef, 'whitespace-only returns undef');

## issue #31 – large decimal integers should be recognized as IPv6

my $big = NetAddr::IP::Lite->new(4294967296);
is($big->version, 6, 'new(4294967296) is version 6');
is("$big", '0:0:0:0:0:1:0:0/128', 'new(4294967296) stringifies as IPv6');
is($big->{isv6}, 1, 'new(4294967296) has isv6 set');

my $small = NetAddr::IP::Lite->new(4294967295);
is($small->version, 4, 'new(4294967295) is version 4');
is($small->{isv6}, 0, 'new(4294967295) has isv6 false');

## non-ASCII digits must be rejected, not treated as decimal numbers

is(NetAddr::IP::Lite->new("\x{0663}\x{0663}\x{0663}\x{0663}"), undef,
    'Arabic-Indic digits rejected');
is(NetAddr::IP::Lite->new("\x{0969}\x{0969}\x{0969}\x{0969}"), undef,
    'Devanagari digits rejected');
is(NetAddr::IP::Lite->new("\x{FF13}\x{FF13}\x{FF13}\x{FF13}"), undef,
    'Fullwidth digits rejected');

## issue #4 – 0b and 0x literals

is(NetAddr::IP::Lite->new("0b101"), "0.0.0.5/32", 'binary 0b101 parses correctly');
is(NetAddr::IP::Lite->new("0x1f"), "0.0.0.31/32", 'hex 0x1f parses correctly');
is(NetAddr::IP::Lite->new("0x10"), "0.0.0.16/32", 'hex 0x10 parses correctly');
is(NetAddr::IP::Lite->new("0xdeadbeef"), "222.173.190.239/32", 'hex 0xdeadbeef parses correctly');
is(NetAddr::IP::Lite->new("0b101", 8), "5.0.0.0/8", 'binary 0b101 with mask parses correctly');
is(NetAddr::IP::Lite->new("0x1f", 8), "31.0.0.0/8", 'hex 0x1f with mask parses correctly');
is(NetAddr::IP::Lite->new("-0b101"), "255.255.255.251/32", 'negative binary parses correctly');
is(NetAddr::IP::Lite->new("0b12"), undef, 'invalid binary 0b12 rejected');
is(NetAddr::IP::Lite->new("-0b12"), undef, 'invalid negative binary -0b12 rejected');
is(NetAddr::IP::Lite->new("0b12", 8), undef, 'invalid binary 0b12 with mask rejected');
is(NetAddr::IP::Lite->new("0xzz"), undef, 'invalid hex 0xzz rejected');

## negative integers

is(NetAddr::IP::Lite->new("-1"), "255.255.255.255/32", 'negative -1 parses as 2s complement');
is(NetAddr::IP::Lite->new("-4294967296"), "0.0.0.0/32", 'negative -4294967296 parses as 0.0.0.0');
is(NetAddr::IP::Lite->new("-4294967297"), undef, 'negative below -(2**32) rejected');
is(NetAddr::IP::Lite->new("-5000000000"), undef, 'negative -5000000000 rejected');

## non-ASCII digits must not match in IPv4 parsing contexts

is(NetAddr::IP::Lite->new("\x{0663}0.0.1"), undef, 'Arabic-Indic in dotted quad rejected');
is(NetAddr::IP::Lite->new("10.\x{0969}0.0.1"), undef, 'Devanagari in dotted quad rejected');
is(NetAddr::IP::Lite->new("\x{FF13}0.0.1/24"), undef, 'Fullwidth in dotted quad with mask rejected');
is(NetAddr::IP::Lite->new("10.0.0.\x{0663}/24"), undef, 'Arabic-Indic in last octet rejected');
is(NetAddr::IP::Lite->new("\x{0663}0-\x{0663}5"), undef, 'Arabic-Indic in range notation rejected');
is(NetAddr::IP::Lite->new("\x{0663}0.\x{0663}0."), undef, 'Arabic-Indic in implicit /16 rejected');
is(NetAddr::IP::Lite->new("\x{0663}0."), undef, 'Arabic-Indic in implicit /8 rejected');

done_testing;
