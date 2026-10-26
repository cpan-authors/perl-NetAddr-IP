#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use Socket ();
use NetAddr::IP::InetBase qw(
  inet_n2ad
  inet_n2dx
  inet_ntoa
  inet_ntop
  inet_pton
  ipv6_n2d
  ipv6_n2x
  ipv6_ntoa
  isAnyIPv4
  isIPv4
  isNewIPv4
);

my $BAD_FAMILY = 4_278_190_080;    # 0xFF000000, which is no address family
my $LONG       = 'x' x 17;         # one byte more than an IPv6 address
my $SHORT      = 'abc';            # three bytes, too short for either family
my $TWO        = 'ab';             # two bytes, too short for IPv4
my $V4_TEXT    = '192.0.2.1';

my $AF_INET   = NetAddr::IP::InetBase::AF_INET();
my $AF_INET6  = NetAddr::IP::InetBase::AF_INET6();
my $THIS_FILE = __FILE__;

my $bits_says =
  'Bad arg length for NetAddr::IP::InetBase::%s, length is %s, should be 128';
my $n2d_says =
  q{Bad arg length for 'ipv6_n2d', length is %s should be 16 bytes};
my $n2x_says =
  q{Bad arg length for 'ipv6_n2x', length is %s should be 16 bytes};
my $ntoa_says =
'Bad arg length for NetAddr::IP::InetBase::inet_ntoa, length is %d should be 4 bytes';
# Socket's own sentence, taken from a call in this process. The probe buffer
# is 16 bytes, so an old Socket does not read past it. The location is
# stripped; the calls below must report this file and their own line.
sub socket_message {
    my ($err) = @_;
    $err =~ s/ at .*//s;
    return $err;
}

my $ntop_says =
  socket_message( dies { Socket::inet_ntop( $BAD_FAMILY, 'x' x 16 ) } );
my $pton_says =
  socket_message( dies { Socket::inet_pton( $BAD_FAMILY, $V4_TEXT ) } );
my $v6ntoa_says =
'Bad arg length for NetAddr::IP::InetBase::ipv6_ntoa, length is %s should be 16 bytes';

# the message, then this file and the line of the call, with or without the
# full stop that Carp 1.20 on perl 5.14 leaves off
sub said_at {
    my ( $says, $line ) = @_;
    return qr/\A\Q$says\E at \Q$THIS_FILE\E line $line\b/;
}

subtest 'an error from the function called names the line that called it' =>
  sub {
    my ( $err, $line );

    ( $line, $err ) = ( __LINE__, dies { inet_ntoa($TWO) } );
    like(
        $err,
        said_at( sprintf( $ntoa_says, 2 ), $line ),
        'inet_ntoa of 2 bytes names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { inet_ntop( $BAD_FAMILY, $SHORT ) } );
    like(
        $err,
        said_at( $ntop_says, $line ),
        'inet_ntop of family 0xFF000000 names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { inet_pton( $BAD_FAMILY, $V4_TEXT ) } );
    like(
        $err,
        said_at( $pton_says, $line ),
        'inet_pton of family 0xFF000000 names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { inet_ntop( $AF_INET6, $SHORT ) } );
    like(
        $err,
        said_at(
'Bad arg length for NetAddr::IP::InetBase::inet_ntop, length is 3 should be 16 bytes',
            $line
        ),
        'inet_ntop AF_INET6 of 3 bytes names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { ipv6_n2d($SHORT) } );
    like(
        $err,
        said_at( sprintf( $n2d_says, 3 ), $line ),
        'ipv6_n2d of 3 bytes names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { ipv6_n2x($SHORT) } );
    like(
        $err,
        said_at( sprintf( $n2x_says, 3 ), $line ),
        'ipv6_n2x of 3 bytes names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { ipv6_ntoa($SHORT) } );
    like(
        $err,
        said_at( sprintf( $v6ntoa_says, 3 ), $line ),
        'ipv6_ntoa of 3 bytes names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { isIPv4($SHORT) } );
    like(
        $err,
        said_at( sprintf( $bits_says, 'isIPv4', 24 ), $line ),
        'isIPv4 of 3 bytes names the line of its call'
    );
  };

subtest
  'an error from a nested InetBase call names the line of the outer call' =>
  sub {
    my ( $err, $line );

    ( $line, $err ) = ( __LINE__, dies { inet_n2ad($SHORT) } );
    like(
        $err,
        said_at( sprintf( $n2d_says, 3 ), $line ),
        'inet_n2ad of 3 bytes, failing in ipv6_n2d, names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { inet_n2dx($SHORT) } );
    like(
        $err,
        said_at( sprintf( $bits_says, 'isAnyIPv4', 24 ), $line ),
        'inet_n2dx of 3 bytes, failing in isIPv4, names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { inet_ntop( $AF_INET, $SHORT ) } );
    like(
        $err,
        said_at( sprintf( $ntoa_says, 3 ), $line ),
'inet_ntop AF_INET of 3 bytes, failing in inet_ntoa, names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { isAnyIPv4($SHORT) } );
    like(
        $err,
        said_at( sprintf( $bits_says, 'isAnyIPv4', 24 ), $line ),
        'isAnyIPv4 of 3 bytes, failing in isIPv4, names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { isNewIPv4($LONG) } );
    like(
        $err,
        said_at( sprintf( $bits_says, 'isNewIPv4', 136 ), $line ),
        'isNewIPv4 of 17 bytes, failing in isIPv4, names the line of its call'
    );
  };

subtest 'an undefined argument names the line of the call' => sub {
    my ( $err, $line );

    ( $line, $err ) = ( __LINE__, dies { inet_n2ad(undef) } );
    like(
        $err,
        said_at( sprintf( $n2d_says, 'undefined' ), $line ),
        'inet_n2ad of undef, failing in ipv6_n2d, names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { inet_n2dx(undef) } );
    like(
        $err,
        said_at( sprintf( $bits_says, 'isAnyIPv4', 'undefined' ), $line ),
        'inet_n2dx of undef, failing in isIPv4, names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { ipv6_n2d(undef) } );
    like(
        $err,
        said_at( sprintf( $n2d_says, 'undefined' ), $line ),
        'ipv6_n2d of undef names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { ipv6_n2x(undef) } );
    like(
        $err,
        said_at( sprintf( $n2x_says, 'undefined' ), $line ),
        'ipv6_n2x of undef names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { ipv6_ntoa(undef) } );
    like(
        $err,
        said_at( sprintf( $v6ntoa_says, 'undefined' ), $line ),
        'ipv6_ntoa of undef names the line of its call'
    );

    ( $line, $err ) = ( __LINE__, dies { isIPv4(undef) } );
    like(
        $err,
        said_at( sprintf( $bits_says, 'isIPv4', 'undefined' ), $line ),
        'isIPv4 of undef names the line of its call'
    );
};

done_testing;
