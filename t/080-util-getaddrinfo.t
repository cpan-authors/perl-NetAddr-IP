#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Mock;

use Socket qw(
  SOCK_STREAM
  inet_pton
  pack_sockaddr_in
  pack_sockaddr_in6
);

# in place before Util imports getaddrinfo, so the lookup calls this
our @calls;
our %answers;
my $socket;

BEGIN {
    $socket = Test2::Mock->new(
        class    => 'Socket',
        override => [
            getaddrinfo => sub {
                my ( $name, $service, $hints ) = @_;
                push @calls, [ $name, $service, { %{ $hints || {} } } ];
                my $made = $answers{$name};
                return 1 unless $made;
                return 0, @{$made};
            },
        ],
    );
}

use NetAddr::IP::Util qw(
  AF_INET
  AF_INET6
  havegethostbyname2
  inet_4map6
  ipv4to6
  ipv6_n2x
  naip_gethostbyname
);

my $v6  = inet_pton( AF_INET6, '2001:db8::1' );
my $v4  = inet_pton( AF_INET,  '192.0.2.1' );
my $v4b = inet_pton( AF_INET,  '198.51.100.10' );

sub result {
    my ( $family, $packed, $pack ) = @_;
    return {
        family   => $family,
        socktype => SOCK_STREAM,
        protocol => 6,
        addr     => $pack->( 0, $packed ),
    };
}

$answers{'mixed.example'} = [
    result( AF_INET6, $v6, \&pack_sockaddr_in6 ),
    result( AF_INET,  $v4, \&pack_sockaddr_in ),
    result( AF_INET6, $v6, \&pack_sockaddr_in6 ),
];
$answers{'v4.example'} = [
    result( AF_INET, $v4,  \&pack_sockaddr_in ),
    result( AF_INET, $v4,  \&pack_sockaddr_in ),
    result( AF_INET, $v4b, \&pack_sockaddr_in ),
];

ok( havegethostbyname2(), 'havegethostbyname2 is true' );

subtest 'a name with AAAA and A returns only the IPv6 addresses' => sub {
    local @calls;
    my @rv = naip_gethostbyname('mixed.example');
    is(
        \@calls,
        [ [ 'mixed.example', '', { socktype => SOCK_STREAM } ] ],
        'one getaddrinfo, empty service, SOCK_STREAM, no family and no flags'
    );
    is(
        [ @rv[ 0 .. 3 ] ],
        [ 'mixed.example', '', AF_INET6(), 16 ],
        'name, empty alias, AF_INET6, length 16'
    );
    is( [ @rv[ 4 .. $#rv ] ],
        [$v6], 'the AAAA address once, and the A address left out' );
};

subtest 'an IPv4-only answer is mapped and keeps family AF_INET' => sub {
    local @calls;
    my @rv     = naip_gethostbyname('v4.example');
    my $first  = inet_4map6( ipv4to6($v4) );
    my $second = inet_4map6( ipv4to6($v4b) );
    is(
        [ @rv[ 0 .. 3 ] ],
        [ 'v4.example', '', AF_INET(), 16 ],
        'name, empty alias, AF_INET, length 16'
    );
    is(
        [ @rv[ 4 .. $#rv ] ],
        [ $first, $second ],
        'duplicates removed, both addresses mapped'
    );
    is( ipv6_n2x($first), '0:0:0:0:0:FFFF:C000:201',
        'the mapped text of 192.0.2.1' );
};

subtest 'a name getaddrinfo cannot resolve is an empty list' => sub {
    local @calls;
    is( [ naip_gethostbyname('missing.example') ], [], 'missing.example' );
    is( $calls[0][0], 'missing.example', 'getaddrinfo was asked' );
};

subtest 'text ending in a number or 0x hex label is not looked up' => sub {
    for my $text ( '0xc0.0.2.010', '0x7f.010', '0xc0.0.2.1', '0xc0000201', '192.0.2.1.',
        '1.2.3.4.5' )
    {
        local @calls;
        is( [ naip_gethostbyname($text) ], [], "$text is an empty list" );
        is( \@calls, [], "getaddrinfo was not asked for $text" );
    }
    for my $text ( '192.0.2.1', '::ffff:192.0.2.1', 'v4.example' ) {
        local @calls;
        naip_gethostbyname($text);
        is( $calls[0][0], $text, "getaddrinfo is still asked for $text" );
    }
};

subtest 'a short IPv4 text is expanded and resolved with gethostbyname' => sub {
    local @calls;
    is( ipv6_n2x( scalar naip_gethostbyname('127.1') ),
        '0:0:0:0:0:FFFF:7F00:1', '127.1 is the mapped loopback' );
    is( $calls[0][0], '127.1', 'getaddrinfo was asked first' );
};

subtest 'an answer is unpacked in list context, as Socket before 2.005 needs' => sub {
    # before Socket 2.005, scalar context did not give the address
    my $mock = Test2::Mock->new(
        class    => 'NetAddr::IP::UtilPolluted',
        override => [
            unpack_sockaddr_in6 => sub {
                return wantarray ? Socket::unpack_sockaddr_in6(@_) : 0;
            },
        ],
    );
    my @rv = naip_gethostbyname('mixed.example');
    is( [ @rv[ 4 .. $#rv ] ], [$v6], 'the AAAA address, not what scalar context gave' );
};

done_testing;
