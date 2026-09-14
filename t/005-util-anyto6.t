#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Util qw( inet_aton ipanyto6 ipv6_aton ipv6_n2d maskanyto6 );

my $nip = inet_aton('1.2.3.4');
my $exp = '0:0:0:0:0:0:1.2.3.4';

## check 4->6 conversion
my $nipv6 = ipanyto6($nip);
my $ipv6  = ipv6_n2d($nipv6);
is($ipv6, $exp, 'ipanyto6 converts 1.2.3.4 correctly');

## check mask4->6 extension
$exp   = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:1.2.3.4';
$nipv6 = maskanyto6($nip);
$ipv6  = ipv6_n2d($nipv6);
is($ipv6, $exp, 'maskanyto6 extends 1.2.3.4 correctly');

## check bad length for ipanyto6
$nip = pack('H9',0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09);
like(dies { ipanyto6($nip) }, qr/Bad arg.+ipanyto6/, 'ipanyto6 dies on bad argument length');

## check bad length for maskanyto6
like(dies { maskanyto6($nip) }, qr/Bad arg.+maskanyto6/, 'maskanyto6 dies on bad argument length');

## check pass of ipv6 addrs
$nip   = ipv6_aton('::1:2.3.4.5');
$exp   = '0:0:0:0:0:1:2.3.4.5';
$nipv6 = ipanyto6($nip);
$ipv6  = ipv6_n2d($nipv6);
is($ipv6, $exp, 'ipanyto6 passes ipv6 addrs correctly');

## check pass of ipv6 addrs
$nip   = ipv6_aton('FFF::1:2.3.4.5');
$exp   = 'FFF:0:0:0:0:1:2.3.4.5';
$nipv6 = maskanyto6($nip);
$ipv6  = ipv6_n2d($nipv6);
is($ipv6, $exp, 'maskanyto6 passes ipv6 addrs correctly');

done_testing;
