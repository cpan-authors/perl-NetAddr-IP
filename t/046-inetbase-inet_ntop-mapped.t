#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

# load with Socket6 hidden, so this compares the module's own inet_ntop
# with core Socket. On the code this replaces, the hidden-Socket6 result
# for a mapped address is hex, and Socket's is the platform form.
BEGIN {
    local @INC = (
        sub {
            my ( undef, $file ) = @_;
            die "Socket6 hidden\n" if $file eq 'Socket6.pm';
            return;
        },
        @INC
    );
    require NetAddr::IP::InetBase;
}

use NetAddr::IP::InetBase qw( AF_INET AF_INET6 inet_ntop inet_pton );
use Socket                ();

my $mapped = pack 'H*', '00000000000000000000ffffc0000201';   # ::ffff:192.0.2.1
my $compat = pack 'H*', '000000000000000000000000c0000201';   # ::192.0.2.1

is(
    inet_ntop( AF_INET6, $mapped ),
    Socket::inet_ntop( AF_INET6, $mapped ),
    'inet_ntop of ::ffff:192.0.2.1 matches Socket'
);

is(
    inet_ntop( AF_INET6, $compat ),
    Socket::inet_ntop( AF_INET6, $compat ),
    'inet_ntop of ::192.0.2.1 matches Socket'
);

my $v4 = inet_pton( AF_INET, '192.0.2.1' );
is( length($v4), 4, 'inet_pton(AF_INET, 192.0.2.1) is 4 bytes' );
is( $v4, pack( 'H*', 'c0000201' ),
    'inet_pton(AF_INET, 192.0.2.1) is c0000201' );

done_testing;
