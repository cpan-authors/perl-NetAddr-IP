#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Mock;

use Socket qw(
  AF_INET
  AF_INET6
  SOCK_STREAM
  inet_pton
  pack_sockaddr_in
  pack_sockaddr_in6
);

# installed before Lite loads Util, which imports getaddrinfo at that point
our @gai;
our @ghbn;
our %answers;
our %a_of;
my ( $core, $socket );

BEGIN {
    $core = Test2::Mock->new(
        class => 'CORE::GLOBAL',
        add   => [
            gethostbyname => sub {
                my ($name) = @_;
                push @ghbn, $name;
                return CORE::gethostbyname($name) if $name =~ /\A[0-9.]+\z/;
                my $addr = $a_of{$name};
                return unless defined $addr;
                return wantarray ? ( $name, '', 2, 4, $addr ) : $addr;
            },
        ],
    );
    $socket = Test2::Mock->new(
        class    => 'Socket',
        override => [
            getaddrinfo => sub {
                my ( $name, $service, $hints ) = @_;
                push @gai, [ $name, $service, { %{ $hints || {} } } ];
                my $made = $answers{$name};
                return 1 unless $made;
                return 0, @{$made};
            },
        ],
    );
}

use NetAddr::IP::Lite ();

my $v6       = inet_pton( AF_INET6, '2001:db8::1' );
my $v4       = inet_pton( AF_INET,  '192.0.2.1' );
my $v4b      = inet_pton( AF_INET,  '198.51.100.10' );
my $mapped   = inet_pton( AF_INET6, '::ffff:192.0.2.1' );
my $mapped_b = inet_pton( AF_INET6, '::ffff:198.51.100.10' );

sub result {
    my ( $family, $packed, $pack ) = @_;
    return {
        family   => $family,
        socktype => SOCK_STREAM,
        protocol => 6,
        addr     => $pack->( 0, $packed ),
    };
}

$answers{'v4.example'} = [
    result( AF_INET, $v4,  \&pack_sockaddr_in ),
    result( AF_INET, $v4b, \&pack_sockaddr_in ),
];
$answers{'v6.example'}   = [ result( AF_INET6, $v6, \&pack_sockaddr_in6 ), ];
$answers{'both.example'} = [
    result( AF_INET6, $v6, \&pack_sockaddr_in6 ),
    result( AF_INET,  $v4, \&pack_sockaddr_in ),
];
$answers{'mapped.example'} = [
    result( AF_INET6, $mapped, \&pack_sockaddr_in6 ),
    result( AF_INET,  $v4,     \&pack_sockaddr_in ),
];
$answers{'mapped-only.example'} =
  [ result( AF_INET6, $mapped_b, \&pack_sockaddr_in6 ), ];
$answers{'loop6.example'} =
  [ result( AF_INET6, inet_pton( AF_INET6, '::1' ), \&pack_sockaddr_in6 ) ];
$answers{'compat6.example'} =
  [ result( AF_INET6, inet_pton( AF_INET6, '::c000:201' ), \&pack_sockaddr_in6 ) ];
$a_of{'v4.example'}     = $v4;
$a_of{'both.example'}   = $v4;
$a_of{'mapped.example'} = $v4;

sub resolved {
    my ( $method, $name, $cidr, $version ) = @_;
    local @gai;
    local @ghbn;
    my $ip  = NetAddr::IP::Lite->$method($name);
    my $got = defined $ip ? $ip->cidr : undef;
    is( $got,         $cidr,    "$method($name)" );
    is( $ip->version, $version, "$method($name) version" ) if defined $ip;
    is(
        \@gai,
        [ [ $name, '', { socktype => SOCK_STREAM } ] ],
        "$method($name) is one getaddrinfo, no family"
    );
    is( \@ghbn, [], "$method($name) does not call gethostbyname" );
}

subtest 'one getaddrinfo, and the address stays the same' => sub {
    resolved( 'new',  'v4.example',         '192.0.2.1/32',             4 );
    resolved( 'new6', 'v4.example',         '0:0:0:0:0:0:C000:201/128', 6 );
    resolved( 'new',  'v6.example',         '2001:DB8:0:0:0:0:0:1/128', 6 );
    resolved( 'new6', 'v6.example',         '2001:DB8:0:0:0:0:0:1/128', 6 );
    resolved( 'new',  'both.example',       '192.0.2.1/32',             4 );
    resolved( 'new6', 'both.example',       '2001:DB8:0:0:0:0:0:1/128', 6 );
    resolved( 'new',  'missing.example',    undef,                      undef );
    resolved( 'new6', 'missing.example',    undef,                      undef );
    resolved( 'new',  'mapped.example',     '192.0.2.1/32',             4 );
    resolved( 'new6', 'mapped.example',     '0:0:0:0:0:0:C000:201/128', 6 );
    resolved( 'new', 'mapped-only.example', '0:0:0:0:0:FFFF:C633:640A/128', 6 );
    resolved( 'new6', 'mapped-only.example',
        '0:0:0:0:0:FFFF:C633:640A/128', 6 );
};

subtest 'an AAAA answer inside ::/96 stays IPv6' => sub {
    resolved( 'new',  'loop6.example',   '0:0:0:0:0:0:0:1/128',      6 );
    resolved( 'new6', 'loop6.example',   '0:0:0:0:0:0:0:1/128',      6 );
    resolved( 'new',  'compat6.example', '0:0:0:0:0:0:C000:201/128', 6 );
    resolved( 'new6', 'compat6.example', '0:0:0:0:0:0:C000:201/128', 6 );
};

subtest 'a short IPv4 text is not looked up' => sub {
    local @gai;
    local @ghbn;
    is( NetAddr::IP::Lite->new('127.1')->cidr, '127.0.0.1/32', 'new(127.1)' );
    is( NetAddr::IP::Lite->new6('127.1')->cidr,
        '0:0:0:0:0:0:7F00:1/128', 'new6(127.1)' );
    is( \@gai,  [], 'no getaddrinfo' );
    is( \@ghbn, [], 'no gethostbyname' );
};

subtest 'text ending in a number or 0x hex label is not looked up' => sub {
    for my $text ( '0xc0.0.2.010', '0x7f.010', '0xc0.0.2.1' ) {
        for my $method (qw( new new6 )) {
            local @gai;
            local @ghbn;
            is( NetAddr::IP::Lite->$method($text), undef, "$method($text)" );
            is( \@gai,  [], "$method($text) does not call getaddrinfo" );
            is( \@ghbn, [], "$method($text) does not call gethostbyname" );
        }
    }
};

subtest 'NoFQDN does not ask the resolver' => sub {
    local $NetAddr::IP::Lite::NoFQDN = 1;
    local @gai;
    local @ghbn;
    is( NetAddr::IP::Lite->new('v4.example'),    undef, 'new under NoFQDN' );
    is( NetAddr::IP::Lite->new6('both.example'), undef, 'new6 under NoFQDN' );
    is( \@gai,                                   [],    'no getaddrinfo' );
    is( \@ghbn,                                  [],    'no gethostbyname' );
};

subtest 'an all-zero answer is no answer' => sub {
    local $answers{'zero.example'} =
      [ result( AF_INET, inet_pton( AF_INET, '0.0.0.0' ), \&pack_sockaddr_in ) ];
    resolved( 'new',  'zero.example', undef, undef );
    resolved( 'new6', 'zero.example', undef, undef );
};

done_testing;
