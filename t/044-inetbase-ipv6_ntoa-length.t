#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

# load with Socket6 as installed, so ipv6_ntoa is checked whichever
# inet_ntop is bound
use NetAddr::IP::InetBase qw( ipv6_ntoa );

my $NTOA_DIES =
  'Bad arg length for NetAddr::IP::InetBase::ipv6_ntoa, length is';
my $THIS_FILE = __FILE__;
my $V6_TEXT   = '2001:db8::1';

my $v4_packed = pack 'H*', 'c0000201';                            # 192.0.2.1
my $v6_packed = pack 'H*', '20010db8000000000000000000000001';    # 2001:db8::1

note 'inet_ntop is bound to ',
  \&NetAddr::IP::InetBase::inet_ntop == \&NetAddr::IP::InetBase::_inet_ntop
  ? 'NetAddr::IP::InetBase'
  : 'Socket6';

subtest 'a defined argument that is not 16 bytes is measured by ipv6_ntoa' =>
  sub {
    my @wrong = (
        [ 'an empty string',       q{},                         0 ],
        [ 'three bytes',           substr( $v6_packed, 0, 3 ),  3 ],
        [ 'a packed IPv4 address', $v4_packed,                  4 ],
        [ 'fifteen bytes',         substr( $v6_packed, 0, 15 ), 15 ],
        [ 'seventeen bytes',       $v6_packed . "\0",           17 ],
    );
    for my $case (@wrong) {
        my ( $what, $packed, $bytes ) = @{$case};
        my ( $line, $err ) = ( __LINE__, dies { ipv6_ntoa($packed) } );
        like(
            $err,
qr/\A\Q$NTOA_DIES $bytes should be 16 bytes at $THIS_FILE\E line $line\b/,
            "ipv6_ntoa of $what measures $bytes bytes at the line of its call"
        );
    }
  };

subtest 'an undefined argument is named as undefined' => sub {
    my ( $line, $err ) = ( __LINE__, dies { ipv6_ntoa(undef) } );
    like(
        $err,
qr/\A\Q$NTOA_DIES undefined should be 16 bytes at $THIS_FILE\E line $line\b/,
        'ipv6_ntoa of undef says undefined at the line of its call'
    );
};

subtest 'sixteen bytes still convert' => sub {
    is( ipv6_ntoa($v6_packed), $V6_TEXT, 'ipv6_ntoa of 2001:db8::1' );
};

done_testing;
