#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::InetBase qw(
  AF_INET
  fillIPv4
  inet_any2n
  inet_aton
  inet_ntoa
  inet_pton
  ipv6_aton
  isAnyIPv4
);

sub packed_hex {
    my ($packed) = @_;
    return defined $packed ? unpack( 'H*', $packed ) : undef;
}

subtest 'fillIPv4 rejects undefined and out-of-range octets' => sub {
    is( fillIPv4(undef), undef, 'fillIPv4 of undef' );
    for my $text (
        '1.256.3.4', '1.2.256.4', '1.2.3.256', '256.256.256.256',
        '256.0.2.1',
      )
    {
        is( fillIPv4($text), undef, "fillIPv4 of '$text'" );
    }
};

subtest 'inet_aton falls through to resolver for a non-literal name' => sub {
    is( inet_aton('host.invalid'),
        undef, 'non-literal host name returns undef when unresolved' );
};

subtest 'inet_pton accepts an undefined text as no IPv4 address' => sub {
    is( inet_pton( AF_INET, undef ), undef, 'inet_pton(AF_INET, undef)' );
};

subtest 'ipv6_aton dotted tail overflow and too many fields' => sub {
    is( ipv6_aton('::ffff:192.0.2.256'),
        undef, 'dotted quad tail octet above 255' );
    is( ipv6_aton('1:2:3:4:5:6:7:8:9'), undef, 'too many IPv6 fields' );
    is( ipv6_aton('::1:2:3:4:5:6:7:8'),
        undef, 'compressed form still has too many fields' );
};

subtest 'inet_any2n treats undefined as the all-zero address' => sub {
    is(
        packed_hex( inet_any2n(undef) ),
        '00000000000000000000000000000000',
        'inet_any2n of undef is ::'
    );
};

subtest 'inet_ntoa croaks on undefined with its length name' => sub {
    like(
        dies { inet_ntoa(undef) },
qr/\ABad arg length for NetAddr::IP::InetBase::inet_ntoa, length is undefined should be 4 bytes at /,
        'inet_ntoa of undef names length as undefined'
    );
};

subtest 'InetBase DESTROY and isAnyIPv4 non-reference call path' => sub {
    ok( lives { NetAddr::IP::InetBase->DESTROY; 1 }, 'DESTROY is callable' );
    my $v4 = "\0" x 12 . pack( 'C4', 192, 0, 2, 1 );
    is( isAnyIPv4($v4), 1,
        'isAnyIPv4 accepts a 16-byte IPv4-compatible address' );
};

done_testing;
