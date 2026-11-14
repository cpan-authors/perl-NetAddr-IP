#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

# a resolver that trims surrounding whitespace, as a platform's may, while $RESOLVER_TRIMS is set,
# and answers from %answer_of first; no mock tool can replace a builtin, so CORE::GLOBAL takes it
# before the modules compile
our $RESOLVER_TRIMS = 0;
our %answer_of;
our @looked_up;

BEGIN {
    *CORE::GLOBAL::gethostbyname = sub {
        my ($name) = @_;
        push @looked_up, $name;
        if (exists $answer_of{$name}) {
            my $addr = $answer_of{$name};
            return wantarray ? ($name, '', 2, 4, $addr) : $addr;
        }
        $name =~ s/\A[\t\n\x0B\f\r ]+|[\t\n\x0B\f\r ]+\z//g if $RESOLVER_TRIMS;
        return CORE::gethostbyname($name);
    };
}

use NetAddr::IP::InetBase qw( fillIPv4 inet_any2n inet_aton ipv6_aton );
use NetAddr::IP::Util     qw( naip_gethostbyname );

sub packed_hex {
    my ($packed) = @_;
    return defined $packed ? unpack('H*', $packed) : undef;
}

sub shown {
    my ($text) = @_;
    $text =~ s/\n/\\n/g;
    $text =~ s/\r/\\r/g;
    $text =~ s/\t/\\t/g;
    return $text;
}

subtest 'a dotted quad tail converts with each octet in decimal' => sub {
    my %packed = (
        '2001:db8::192.0.2.100' => '20010db80000000000000000c0000264',
        '::192.0.2.1'           => '000000000000000000000000c0000201',
        '::ffff:0.0.0.0'        => '00000000000000000000ffff00000000',
        '::ffff:192.0.2.10'     => '00000000000000000000ffffc000020a',
        '::ffff:198.51.100.255' => '00000000000000000000ffffc63364ff',
    );
    for my $text (sort keys %packed) {
        is( packed_hex(ipv6_aton($text)),
            $packed{$text}, "ipv6_aton of '$text'"
        );
        is( packed_hex(inet_any2n($text)),
            $packed{$text}, "inet_any2n of '$text'"
        );
    }
    is( packed_hex(inet_any2n('192.0.2.10')),
        '000000000000000000000000c000020a',
        "inet_any2n of '192.0.2.10'"
    );
};

subtest 'a dotted quad tail with a leading zero is not an address' => sub {
    for my $text (
        '2001:db8::192.0.2.01', '::192.0.2.08',
        '::ffff:192.0.2.000',   '::ffff:192.0.02.1',
        '::ffff:192.0.2.00',    '::ffff:192.0.2.010',
        '::ffff:192.000.2.1',
    ) {
        is(packed_hex(ipv6_aton($text)),  undef, "ipv6_aton of '$text'");
        is(packed_hex(inet_any2n($text)), undef, "inet_any2n of '$text'");
    }
    for my $text ('192.0.02.1', '192.0.2.010', '192.000.2.1') {
        is(packed_hex(inet_any2n($text)), undef, "inet_any2n of '$text'");
    }
};

subtest 'IPv6 text with surrounding whitespace is not an address' => sub {
    for my $text (
        " ::ffff:192.0.2.1",     "2001:db8::1\n",
        "2001:db8::192.0.2.1\n", "::192.0.2.1\n",
        "::ffff:192.0.2.1\n",    "::ffff:192.0.2.1\r\n",
    ) {
        my $name = shown($text);
        is(packed_hex(ipv6_aton($text)),  undef, "ipv6_aton of '$name'");
        is(packed_hex(inet_any2n($text)), undef, "inet_any2n of '$name'");
    }
    is( packed_hex(inet_any2n("192.0.2.1\n")),
        undef, "inet_any2n of '192.0.2.1\\n'"
    );
};

subtest 'fillIPv4 completes only text that is all digits and dots' => sub {
    is(fillIPv4('192.0.2.1'), '192.0.2.1', "fillIPv4 of '192.0.2.1'");
    is(fillIPv4('192.0.2'),   '192.0.0.2', "fillIPv4 of '192.0.2'");
    for my $text ("192.0.2.1\n", "192.0.2\n") {
        my $name = shown($text);
        is(fillIPv4($text), $text, "fillIPv4 returns '$name' as given");
    }
};

subtest 'an IPv4 part with a leading zero is not an address' => sub {
    for my $text (
        '00',         '010',        '010.0.2.1',   '010.1',
        '192.0.02.1', '192.0.2.01', '192.0.2.010', '192.000.002.010',
    ) {
        is(fillIPv4($text),              undef, "fillIPv4 of '$text'");
        is(packed_hex(inet_aton($text)), undef, "inet_aton of '$text'");
        is( packed_hex(scalar naip_gethostbyname($text)),
            undef, "naip_gethostbyname of '$text'"
        );
    }
    my %packed = (
        '0'         => '00000000',
        '0.0.0.0'   => '00000000',
        '10.1'      => '0a000001',
        '192.0.2.0' => 'c0000200',
    );
    for my $text (sort keys %packed) {
        is( packed_hex(inet_aton($text)),
            $packed{$text}, "inet_aton of '$text'"
        );
    }
};

subtest 'text with whitespace does not reach the resolver' => sub {
    local $RESOLVER_TRIMS = 1;
    is( packed_hex(scalar gethostbyname("192.0.2.1\n")),
        'c0000201', "the trimming resolver answers for '192.0.2.1\\n'"
    ) or bail_out('the resolver override is not in place');
    for my $text (
        " 192.0.2.1",  "192.0.2\n",
        "192.0.2.1\t", "192.0.2.1\n",
        "192.0.2.1\r\n",
    ) {
        my $name = shown($text);
        is(packed_hex(inet_aton($text)), undef, "inet_aton of '$name'");
        is( packed_hex(scalar naip_gethostbyname($text)),
            undef, "naip_gethostbyname of '$name'"
        );
    }
};

subtest 'text with a NUL byte is not an address or a name' => sub {
    for my $text (
        "192.0.2.010\0", "192.0.2.1\0junk", "\x{0}192.0.2.1",
        "localhost\0"
    ) {
        my $name = $text =~ s/\0/\\0/gr;
        is(packed_hex(inet_aton($text)), undef, "inet_aton of '$name'");
        is(fillIPv4($text),              undef, "fillIPv4 of '$name'");
        is( [ naip_gethostbyname($text) ], [],
            "naip_gethostbyname of '$name'"
        );
    }
};

subtest 'text whose last label is a number or 0x hex does not reach the resolver' => sub {

    # an answer for each text: what a BSD C library gives for the hex forms, what a DNS server could
    # give for the rest, so a lookup shows in the result as well as in @looked_up
    local %answer_of = (
        '0XC0.0.2.1'   => pack('C4', 192, 0,  2, 1),
        '0xc0.0.2.010' => pack('C4', 192, 0,  2, 8),
        '0xc0.0.2.1'   => pack('C4', 192, 0,  2, 1),
        '0xc0000201'   => pack('C4', 192, 0,  2, 1),
        '192.0.2.1.'   => pack('C4', 192, 0,  2, 1),
        '192.0.2.1.5'  => pack('C4', 192, 0,  2, 1),
        '198.51.0x64'  => pack('C4', 198, 51, 0, 100),
        'example.123'  => pack('C4', 192, 0,  2, 1),
        'name.example' => pack('C4', 192, 0,  2, 1),
    );
    {
        local @looked_up;
        is( packed_hex(inet_aton('name.example')),
            'c0000201', 'a host name reaches the resolver and gets its answer'
        ) or bail_out('the resolver override is not in place');
        is(\@looked_up, ['name.example'], 'the resolver was asked for name.example');
    }
    for my $text (sort grep { $_ ne 'name.example' } keys %answer_of) {
        local @looked_up;
        is(packed_hex(inet_aton($text)), undef, "inet_aton of '$text'");
        is(\@looked_up,                  [],    "the resolver was not asked for '$text'");
    }
};

done_testing;
