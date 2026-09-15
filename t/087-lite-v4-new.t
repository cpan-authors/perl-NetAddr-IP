#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $binword;
{
    local $SIG{__WARN__} = sub {};
    $binword = eval { 0b11111111111111110000000000000000 };
}
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

for my $a (@a) {
    for my $m (@m) {
        my ($input,      $expected_addr) = %$a;
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

done_testing;
