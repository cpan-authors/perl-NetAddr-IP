#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Mock;

use Socket ();

# in place before Util imports getaddrinfo, so a call to it is seen here
our @calls;
my $socket;

BEGIN {
    $socket = Test2::Mock->new(
        class    => 'Socket',
        override => [ getaddrinfo => sub { push @calls, $_[0]; return 1 } ],
    );
}

use NetAddr::IP::Util qw(
  :noSock6
  havegethostbyname2
  ipv6_n2x
  naip_gethostbyname
);

ok( !havegethostbyname2(), ':noSock6 makes havegethostbyname2 false' );

# the address as text, or undef when there is none
sub looked_up {
    my $addr = naip_gethostbyname( $_[0] );
    return defined $addr ? ipv6_n2x($addr) : undef;
}

subtest 'under :noSock6 a name goes to gethostbyname, never to getaddrinfo' => sub {
    local @calls;
    is( looked_up('localhost'), '0:0:0:0:0:FFFF:7F00:1',
        'localhost is the mapped IPv4 loopback' );
    is( looked_up('127.1'), '0:0:0:0:0:FFFF:7F00:1',
        '127.1 is the mapped IPv4 loopback' );
    is( \@calls, [], 'getaddrinfo was not asked' );
};

done_testing;
