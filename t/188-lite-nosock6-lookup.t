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

use NetAddr::IP::Util qw(
  :noSock6
  havegethostbyname2
  ipv6_n2x
  naip_gethostbyname
);
use NetAddr::IP::Lite ();

my $v4 = inet_pton( AF_INET,  '192.0.2.1' );
my $v6 = inet_pton( AF_INET6, '2001:db8::1' );

sub result {
    my ( $family, $packed, $pack ) = @_;
    return {
        family   => $family,
        socktype => SOCK_STREAM,
        protocol => 6,
        addr     => $pack->( 0, $packed ),
    };
}

$answers{'v4.example'} = [ result( AF_INET,  $v4, \&pack_sockaddr_in ) ];
$answers{'v6.example'} = [ result( AF_INET6, $v6, \&pack_sockaddr_in6 ) ];
$a_of{'v4.example'}    = $v4;

ok( !havegethostbyname2(), 'havegethostbyname2 is false' );

sub looked_up {
    my ( $method, $name, $cidr, $version ) = @_;
    local @gai;
    local @ghbn;
    my $ip  = NetAddr::IP::Lite->$method($name);
    my $got = defined $ip ? $ip->cidr : undef;
    is( $got,         $cidr,    "$method($name)" );
    is( $ip->version, $version, "$method($name) version" ) if defined $ip;
    is( \@gai,        [],       "$method($name) does not call getaddrinfo" );
    is( \@ghbn,       [$name],  "$method($name) is one gethostbyname" );
}

subtest 'a host name stays on gethostbyname' => sub {
    looked_up( 'new',  'v4.example', '192.0.2.1/32',             4 );
    looked_up( 'new6', 'v4.example', '0:0:0:0:0:0:C000:201/128', 6 );
    looked_up( 'new',  'v6.example', undef,                      undef );
    looked_up( 'new6', 'v6.example', undef,                      undef );
};

subtest 'text ending in a number or 0x hex label is not looked up' => sub {
    for my $method (qw( new new6 )) {
        local @gai;
        local @ghbn;
        is( NetAddr::IP::Lite->$method('0xc0.0.2.010'), undef, "$method(0xc0.0.2.010)" );
        is( \@ghbn, [], "$method(0xc0.0.2.010) does not call gethostbyname" );
    }
};

subtest 'a short IPv4 text is not looked up' => sub {
    local @gai;
    local @ghbn;
    is( ipv6_n2x( scalar naip_gethostbyname('127.1') ),
        '0:0:0:0:0:FFFF:7F00:1', 'naip_gethostbyname packs 127.1' );
    is( NetAddr::IP::Lite->new('127.1')->cidr, '127.0.0.1/32', 'new(127.1)' );
    is( \@gai,                                 [], 'no getaddrinfo' );
    is( \@ghbn,                                [], 'no gethostbyname' );
};

subtest 'an all-zero answer is no answer' => sub {
    local $a_of{'zero.example'} = inet_pton( AF_INET, '0.0.0.0' );
    looked_up( 'new',  'zero.example', undef, undef );
    looked_up( 'new6', 'zero.example', undef, undef );
};

done_testing;
