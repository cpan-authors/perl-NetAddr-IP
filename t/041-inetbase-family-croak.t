#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );
use Test2::Tools::Warnings  qw( no_warnings );

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

# both functions die naming the family, and neither warns on the way
sub refused_without_warning {
    my ($af) = @_;
    my ( $ntop_error, $pton_error );
    ok(
        no_warnings {
            $ntop_error =
              dies { NetAddr::IP::InetBase::inet_ntop( $af, $v4_packed ) };
            $pton_error =
              dies { NetAddr::IP::InetBase::inet_pton( $af, $V4_TEXT ) };
        },
        "family '$af' does not warn"
    );
    like(
        $ntop_error,
        qr/\A\Q$NTOP_DIES $af, $accepted\E at /,
        "inet_ntop of family '$af' dies naming it"
    );
    like(
        $pton_error,
        qr/\A\Q$PTON_DIES $af, $accepted\E at /,
        "inet_pton of family '$af' dies naming it"
    );
    return;
}

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

subtest 'a family that is not a number is named, without a warning' => sub {
    refused_without_warning($_) for '', '0x2', 'AF_INET', 'AF_INET6';
};

subtest 'a family that is a number followed by text is refused' => sub {
    refused_without_warning($_) for "${AF_INET6}abc", "${AF_INET}abc";
};

subtest 'a padded, signed or exponent family still converts' => sub {
    my @written = (
        [ 'a decimal point',    "$AF_INET.0",    $v4_packed, $V4_TEXT ],
        [ 'a leading space',    " $AF_INET",     $v4_packed, $V4_TEXT ],
        [ 'a leading zero',     "0$AF_INET",     $v4_packed, $V4_TEXT ],
        [ 'a plus sign',        "+$AF_INET",     $v4_packed, $V4_TEXT ],
        [ 'a trailing newline', "$AF_INET\n",    $v4_packed, $V4_TEXT ],
        [ 'a trailing space',   "$AF_INET ",     $v4_packed, $V4_TEXT ],
        [ 'an exponent',        "${AF_INET6}e0", $v6_packed, $V6_TEXT ],
    );
    for my $case (@written) {
        my ( $form, $af, $packed, $text ) = @{$case};
        is( eval { NetAddr::IP::InetBase::inet_ntop( $af, $packed ) } // $@,
            $text, "inet_ntop of a family with $form" );
        is( eval { NetAddr::IP::InetBase::inet_pton( $af, $text ) } // $@,
            $packed, "inet_pton of a family with $form" );
    }
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
