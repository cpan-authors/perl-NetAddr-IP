#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

# load with Socket6 hidden, so inet_ntop and inet_pton are this module's own
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

my $BAD_FAMILY = 4_278_190_080;    # 0xFF000000, which is no address family
my $NTOP_DIES =
  'Unsupported address family for NetAddr::IP::InetBase::inet_ntop, af is';
my $PTON_DIES = 'Bad address family for NetAddr::IP::InetBase::inet_pton, got';
my $V4_TEXT   = '192.0.2.1';
my $V6_TEXT   = '2001:db8::1';

my $AF_INET  = NetAddr::IP::InetBase::AF_INET();
my $AF_INET6 = NetAddr::IP::InetBase::AF_INET6();
my $accepted = sprintf 'should be AF_INET (%d) or AF_INET6 (%d)', $AF_INET,
  $AF_INET6;
my $v4_packed = pack 'H*', 'c0000201';
my $v6_packed = pack 'H*', '20010db8000000000000000000000001';

ok(
    \&NetAddr::IP::InetBase::inet_ntop == \&NetAddr::IP::InetBase::_inet_ntop
      && \&NetAddr::IP::InetBase::inet_pton ==
      \&NetAddr::IP::InetBase::_inet_pton,
    'inet_ntop and inet_pton are bound to InetBase with Socket6 hidden'
) or bail_out('Socket6 was not hidden, so the errors below are not ours');

subtest 'a family that is neither AF_INET nor AF_INET6 is named with both' =>
  sub {
    like(
        dies { NetAddr::IP::InetBase::inet_ntop( $BAD_FAMILY, $v4_packed ) },
        qr/\A\Q$NTOP_DIES 4278190080, $accepted\E at /,
        'inet_ntop of family 0xFF000000 names the family and the two accepted'
    );
    like(
        dies { NetAddr::IP::InetBase::inet_pton( $BAD_FAMILY, $V4_TEXT ) },
        qr/\A\Q$PTON_DIES 4278190080, $accepted\E at /,
        'inet_pton of family 0xFF000000 names the family and the two accepted'
    );
  };

subtest 'an undefined family is named as undefined, without a warning' => sub {
    like(
        dies { NetAddr::IP::InetBase::inet_ntop( undef, $v4_packed ) },
        qr/\A\Q$NTOP_DIES undefined, $accepted\E at /,
        'inet_ntop of an undefined family says undefined'
    );
    like(
        dies { NetAddr::IP::InetBase::inet_pton( undef, $V4_TEXT ) },
        qr/\A\Q$PTON_DIES undefined, $accepted\E at /,
        'inet_pton of an undefined family says undefined'
    );
};

subtest 'AF_INET and AF_INET6 still convert' => sub {
    is( NetAddr::IP::InetBase::inet_ntop( $AF_INET, $v4_packed ),
        $V4_TEXT, 'inet_ntop of AF_INET' );
    is( NetAddr::IP::InetBase::inet_ntop( $AF_INET6, $v6_packed ),
        $V6_TEXT, 'inet_ntop of AF_INET6' );
    is( NetAddr::IP::InetBase::inet_pton( $AF_INET, $V4_TEXT ),
        $v4_packed, 'inet_pton of AF_INET' );
    is( NetAddr::IP::InetBase::inet_pton( $AF_INET6, $V6_TEXT ),
        $v6_packed, 'inet_pton of AF_INET6' );
};

done_testing;
