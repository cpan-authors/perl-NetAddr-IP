#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Util qw( inet_any2n inet_ntoa ipv6_n2d ipv6to4 );

## test 2	check that we have an ipv6 netaddr
my $nip = inet_any2n('1.2.3.4');
my $exp = '0:0:0:0:0:0:1.2.3.4';

my $ipv6 = ipv6_n2d($nip);
is($ipv6, $exp, 'ipv6_n2d converts to expected address');

## test 3	check conversion back to ipv4
$exp = '1.2.3.4';
is(inet_ntoa(ipv6to4($nip)), $exp, 'ipv6to4 converts back to ipv4');

## test 4	check bad length
my $bad = pack("H9", 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09);
like(dies { ipv6to4($bad) }, qr/Bad arg.+ipv6to4/, 'ipv6to4 rejects bad argument length');

done_testing;
