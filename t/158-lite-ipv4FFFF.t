#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Mock;

use Math::BigInt      ();
use NetAddr::IP::Lite ();
use NetAddr::IP::Util qw( ipv6_aton );

# the new6FFFF result as text, or undef
sub new6ffff_text {
    my $ip = NetAddr::IP::Lite->new6FFFF(@_);
    return defined $ip ? "$ip" : undef;
}

my $ip  = NetAddr::IP::Lite->new6FFFF('127.0.0.1');
my $exp = '0:0:0:0:0:FFFF:7F00:1/128';

is( "$ip", $exp, 'new6FFFF returns expected IPv4 mapped address' );

ok( !defined NetAddr::IP::Lite->new6FFFF(undef),
    'new6FFFF(undef) returns undef'
);
ok( !defined NetAddr::IP::Lite->new6FFFF(''), "new6FFFF('') returns undef" );
ok( !defined NetAddr::IP::Lite->new6FFFF('10.0.0.a'),
    "new6FFFF('10.0.0.a') returns undef"
);

is( new6ffff_text('-1'), undef, "the call new6FFFF('-1') is undef" );

subtest 'an IPv4 address passed to new6FFFF is mapped into ::ffff:0:0/96' => sub {
    my %mapped = (
        '192.0.2.'                => '0:0:0:0:0:FFFF:C000:200/120',
        '192.0.2.0 - 192.0.2.255' => '0:0:0:0:0:FFFF:C000:200/120',
        '192.0.2.0/24'            => '0:0:0:0:0:FFFF:C000:200/120',
        '192.0.2.1'               => '0:0:0:0:0:FFFF:C000:201/128',
        '192.0.2.8-15'            => '0:0:0:0:0:FFFF:C000:208/125',
        '3221225985'              => '0:0:0:0:0:FFFF:C000:201/128',
    );
    for my $input ( sort keys %mapped ) {
        is( new6ffff_text($input), $mapped{$input},
            "the call new6FFFF('$input') maps the IPv4 address"
        );
    }
    is( new6ffff_text( '192.0.2.1', 24 ),
        '0:0:0:0:0:FFFF:C000:201/120',
        "the call new6FFFF('192.0.2.1', 24) maps the address and its /24 mask"
    );
    is( new6ffff_text( Math::BigInt->from_hex('0xc0000201') ),
        '0:0:0:0:0:FFFF:C000:201/128',
        'the call new6FFFF(Math::BigInt 0xc0000201) maps the IPv4 address'
    );
};

subtest 'an IPv6 address passed to new6FFFF comes back as new6 gives it' => sub {
    my %as_new6 = (
        '2001:db8::/32' => '2001:DB8:0:0:0:0:0:0/32',
        '2001:db8::1'   => '2001:DB8:0:0:0:0:0:1/128',
        '4294967296'    => '0:0:0:0:0:1:0:0/128',
        '::1'           => '0:0:0:0:0:0:0:1/128',
        '::192.0.2.1'   => '0:0:0:0:0:0:C000:201/128',
        '[2001:db8::1]' => '2001:DB8:0:0:0:0:0:1/128',
        'loopback'      => '0:0:0:0:0:0:0:1/128',
    );
    for my $input ( sort keys %as_new6 ) {
        is( new6ffff_text($input), $as_new6{$input},
            "the call new6FFFF('$input') leaves the IPv6 address alone"
        );
    }
    is( new6ffff_text( 'loopback', 'ipv6' ),
        '0:0:0:0:0:0:0:1/128',
        "the call new6FFFF('loopback', 'ipv6') leaves the IPv6 loopback alone"
    );
    my $v6_number = Math::BigInt->from_hex('0x20010db8000000000000000000000001');
    is( new6ffff_text( $v6_number, 64 ),
        '2001:DB8:0:0:0:0:0:1/64',
        'the call new6FFFF(Math::BigInt of 2001:db8::1, 64) leaves the address alone'
    );
};

subtest 'an A answer passed to new6FFFF is mapped and an AAAA answer is left alone' => sub {
    my %answer = (
        'a.example'    => [ ipv6_aton('::192.0.2.1') ],
        'aaaa.example' => [ ipv6_aton('2001:db8::1'), 1 ],
    );
    my $mock = Test2::Mock->new(
        class    => 'NetAddr::IP::Lite',
        override => [
            _resolve_host => sub {
                my ($name) = @_;
                return @{ $answer{$name} || [] };
            },
        ],
    );
    is( new6ffff_text('a.example'),
        '0:0:0:0:0:FFFF:C000:201/128',
        "the call new6FFFF('a.example') maps the A answer 192.0.2.1"
    );
    is( new6ffff_text('aaaa.example'), '2001:DB8:0:0:0:0:0:1/128',
        "the call new6FFFF('aaaa.example') leaves the AAAA answer 2001:db8::1 alone"
    );
};

subtest 'packed bytes passed to new6FFFF map 4 bytes and leave 16 alone' => sub {
    local $NetAddr::IP::Lite::Accept_Binary_IP = 1;
    is( new6ffff_text( pack( 'C4', 192, 0, 2, 1 ) ),
        '0:0:0:0:0:FFFF:C000:201/128',
        'the call new6FFFF(4 packed bytes of 192.0.2.1) maps the IPv4 address'
    );
    is( new6ffff_text( ipv6_aton('2001:db8::1') ),
        '2001:DB8:0:0:0:0:0:1/128',
        'the call new6FFFF(16 packed bytes of 2001:db8::1) leaves the address alone'
    );
};

done_testing;
