#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Util qw( inet_aton ipv4to6 ipv6_n2d mask4to6 );

my $nip  = inet_aton('1.2.3.4');
my $exp  = '0:0:0:0:0:0:1.2.3.4';

## check 4->6 conversion
my $nipv6 = ipv4to6($nip);
my $ipv6  = ipv6_n2d($nipv6);
is($ipv6, $exp, 'ipv4to6 converts 1.2.3.4 correctly');

## check mask4->6 extension
$exp   = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:1.2.3.4';
$nipv6 = mask4to6($nip);
$ipv6  = ipv6_n2d($nipv6);
is($ipv6, $exp, 'mask4to6 extends 1.2.3.4 correctly');

## check bad length for ipv4to6
$nip = pack('H9',0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09);
like(dies { ipv4to6($nip) }, qr/Bad arg.+ipv4to6/, 'ipv4to6 dies on bad argument length');

## check bad length for mask4to6
like(dies { mask4to6($nip) }, qr/Bad arg.+mask4to6/, 'mask4to6 dies on bad argument length');

done_testing;
