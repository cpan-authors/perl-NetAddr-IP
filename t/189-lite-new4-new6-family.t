#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Mock;
use Test2::Tools::Warnings qw(no_warnings);

use Math::BigInt      ();
use NetAddr::IP       ();
use NetAddr::IP::Lite ();
use NetAddr::IP::Util qw(inet_aton ipv4to6 ipv6_aton);

my $L = 'NetAddr::IP::Lite';

# the string form of an object, or undef
sub show {
    my ($ip) = @_;
    return defined $ip ? "$ip" : undef;
}

# the arguments as they would be written in a call
sub label {
    return join ', ', map { "'$_'" } @_;
}

subtest 'an IPv4 input passed to new4 reads as new does' => sub {
    for my $args (
        ['192.0.2.1'],
        ['192.0.2.1/24'],
        [ '192.0.2.1', '255.255.255.0' ],
        [ '192.0.2.1', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00' ],
        ['192.0.2.4-7'],
        [ '10',  8 ],
        [ '10',  4_294_967_040 ],
        [ '300', 24 ],
        ['3221225985'],
        ['0xc0000201'],
        ['-1'],
        ['any'],
        ['broadcast'],
        ['default'],
        ['loopback'],
    ) {
        my $ip = $L->new4(@$args);
        is( show($ip),
            show($L->new(@$args)),
            'a call new4(' . label(@$args) . ') matches new'
        );
        is( $ip && $ip->version,
            4, 'a call new4(' . label(@$args) . ') is IPv4'
        );
    }
    isa_ok(NetAddr::IP->new4('192.0.2.1'), 'NetAddr::IP');
};

subtest 'input that is not IPv4 is undef from new4' => sub {
    for my $args (
        ['4294967296'],  ['2001:db8::1'],         ['::1'], ['::'],
        ['::192.0.2.1'], ['::ffff:192.0.2.0/64'], ['unspecified'],
        [ 'loopback', 'ipv6' ],
    ) {
        is( $L->new4(@$args), undef,
            'a call new4(' . label(@$args) . ') is undef'
        );
    }
    is( $L->new4(Math::BigInt->new(2)->bpow(40)),
        undef, 'a call new4 of a Math::BigInt from 2**32 is undef'
    );
};

subtest 'IPv4-mapped text passed to new4 reads as the IPv4 address' => sub {
    my @cases = (
        [ ['::ffff:192.0.2.1'],        '192.0.2.1/32' ],
        [ ['::ffff:c000:201'],         '192.0.2.1/32' ],
        [ ['::ffff:192.0.2.0/120'],    '192.0.2.0/24' ],
        [ [ '::ffff:192.0.2.0', 120 ], '192.0.2.0/24' ],
        [   [ '::ffff:192.0.2.0', 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00' ],
            '192.0.2.0/24'
        ],
    );
    for my $case (@cases) {
        my ($args, $want) = @$case;
        my $ip = $L->new4(@$args);
        is(show($ip), $want, 'a call new4(' . label(@$args) . ')');
        is( $ip && $ip->version,
            4, 'a call new4(' . label(@$args) . ') is IPv4'
        );
    }
};

subtest 'a host name passed to new4 takes the IPv4 answer' => sub {
    my %answer = (
        'host4.example' => [ ipv4to6(inet_aton('192.0.2.7')) ],
        'host6.example' => [ ipv6_aton('2001:db8::7'), 1 ],
    );
    my $mock = Test2::Mock->new(
        class    => 'NetAddr::IP::Lite',
        override => [ _resolve_host => sub { @{ $answer{ $_[0] } || [] } } ],
    );
    is( show($L->new4('host4.example')),
        '192.0.2.7/32', 'a name with an IPv4 answer'
    );
    is($L->new4('host6.example'), undef, 'a name with only an IPv6 answer');
    is( show($L->new('host6.example')),
        '2001:DB8:0:0:0:0:0:7/128',
        'a call to new keeps the IPv6 answer'
    );
};

subtest 'an IPv4 object rebuilds from new4 when the mask is above 128' => sub {
    for my $cidr (
        '0.0.0.0/32',      '0.0.0.5/30',
        '0.0.0.255/32',    '192.0.2.0/24',
        '198.51.100.7/31', '255.255.255.255/32'
    ) {
        my $ip = $L->new($cidr);
        is( show($L->new4($ip->numeric)),
            $cidr, "a call new4(numeric) of $cidr"
        );
    }
    is( show($L->new4($L->new('0.0.0.5/0')->numeric)),
        '5.0.0.0/0', 'a numeric mask of 0 stays prefix length 0'
    );
};

subtest 'a whole number passed to new6 reads as 128 bits' => sub {
    my @cases = (
        [ [ '0', 0 ],     '0:0:0:0:0:0:0:0/0' ],
        [ [ '5', 8 ],     '0:0:0:0:0:0:0:5/8' ],
        [ [ '5', 64 ],    '0:0:0:0:0:0:0:5/64' ],
        [ [ '127', 8 ],   '0:0:0:0:0:0:0:7F/8' ],
        [ ['127/8'],      '0:0:0:0:0:0:0:7F/8' ],
        [ [ '255', 8 ],   '0:0:0:0:0:0:0:FF/8' ],
        [ [ '0x5', 8 ],   '0:0:0:0:0:0:0:5/8' ],
        [ [ '0b101', 8 ], '0:0:0:0:0:0:0:5/8' ],
    );
    for my $case (@cases) {
        my ($args, $want) = @$case;
        is( show($L->new6(@$args)),
            $want, 'a call new6(' . label(@$args) . ')'
        );
    }
    is( show($L->new6(Math::BigInt->new(5), 8)),
        '0:0:0:0:0:0:0:5/8',
        'a call new6 of a Math::BigInt 5 with a prefix length'
    );
};

subtest 'dotted text passed to new6 keeps an IPv4 prefix length' => sub {
    my @cases = (
        [ ['127.0/8'], '0:0:0:0:0:0:7F00:0/104' ],
        [ [ '10.1',      8 ],        '0:0:0:0:0:0:A01:0/104' ],
        [ [ '192.0.2.1', 24 ],       '0:0:0:0:0:0:C000:201/120' ],
        [ [ '192.0.2.1', 'ffff::' ], '0:0:0:0:0:0:C000:201/16' ],
    );
    for my $case (@cases) {
        my ($args, $want) = @$case;
        is( show($L->new6(@$args)),
            $want, 'a call new6(' . label(@$args) . ')'
        );
    }
};

subtest 'a negative number passed to new6 is undef' => sub {
    for my $args (['-1'], ['-4294967296'], [ '-1', 24 ], ['-0x5']) {
        is( $L->new6(@$args), undef,
            'a call new6(' . label(@$args) . ') is undef'
        );
    }
    is( $L->new6(Math::BigInt->new(-5)),
        undef, 'a call new6 of a negative Math::BigInt is undef'
    );
    is( show($L->new('-1')),
        '255.255.255.255/32', 'a call to new still accepts -1'
    );
};

subtest 'an IPv6 object rebuilds from new6' => sub {
    for my $cidr (
        '::/0',            '::1/0',
        '::/128',          '::1',
        '::4/126',         '::5/8',
        '::ffff:c000:201', '2001:db8::/32',
        '2001:db8::1'
    ) {
        my $ip = $L->new6($cidr);
        is( show($L->new6($ip->numeric)),
            show($ip), "a call new6(numeric) of $cidr"
        );
    }
};

subtest 'the values of an IPv6 object inside ::/96 read as IPv4 through new' => sub {
    my $ip = $L->new6('::1');
    is( show($L->new($ip->numeric)),
        '0.0.0.1/32', 'a call to new of the numeric values of ::1'
    );
};

subtest 'the mapped and cis constructors use the same number reading' => sub {
    is( show($L->new6FFFF('5', 8)),
        '0:0:0:0:0:FFFF:0:5/8', 'a call new6FFFF of 5 with a prefix length'
    );
    is($L->new6FFFF('-1'), undef, 'a call new6FFFF of -1 is undef');
    is( show($L->new6FFFF('2001:db8::1')),
        '2001:DB8:0:0:0:0:0:1/128',
        'a call new6FFFF of an IPv6 address stays as new6 gives it'
    );

    # new_cis6 warns on every call; the count is the return value
    my $cis;
    my $quiet = no_warnings { $cis = $L->new_cis6('5 8') };
    is(show($cis), '0:0:0:0:0:0:0:5/8', 'a call new_cis6 of 5 8');
    $quiet = no_warnings { $cis = $L->new_cis6('-1') };
    is($cis, undef, 'a call new_cis6 of -1 is undef');
};

subtest 'an undef mask argument defers to the mask written in the string' => sub {
    for my $case (
        [ 'new',    '192.0.2.0/24',            '192.0.2.0/24' ],
        [ 'new',    '192.0.2.0 24',            '192.0.2.0/24' ],
        [ 'new',    '192.0.2.0/255.255.255.0', '192.0.2.0/24' ],
        [ 'new',    '[2001:db8::1]/64',        '2001:DB8:0:0:0:0:0:1/64' ],
        [ 'new',    '[2001:db8::1/64]',        '2001:DB8:0:0:0:0:0:1/64' ],
        [ 'new4',   '192.0.2.0/24',            '192.0.2.0/24' ],
        [ 'new6',   '2001:db8::/32',           '2001:DB8:0:0:0:0:0:0/32' ],
        [ 'new6',   'loopback/64',             '0:0:0:0:0:0:0:1/64' ],
        [ 'new_no', '192.0.2.0/24',            '192.0.2.0/24' ],
    ) {
        my ($ctor, $text, $want) = @$case;
        is(show($L->$ctor($text)),        $want, "a call $ctor('$text') gives $want");
        is(show($L->$ctor($text, undef)), $want, "a call $ctor('$text', undef) gives $want");
    }

    # with no mask in the string, an undef mask is still a host mask
    for my $case (
        [ 'new',  '192.0.2.1', '192.0.2.1/32' ],
        [ 'new',  '10.1',      '10.0.0.1/32' ],
        [ 'new6', 'loopback',  '0:0:0:0:0:0:0:1/128' ],
        [ 'new6', '::',        '0:0:0:0:0:0:0:0/128' ],
    ) {
        my ($ctor, $text, $want) = @$case;
        is(show($L->$ctor($text, undef)), $want, "a call $ctor('$text', undef) gives $want");
    }
};

done_testing;
