#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Util qw( inet_aton ipv4to6 ipv6_n2d mask4to6 );

my $nip = inet_aton('1.2.3.4');
my $exp = '0:0:0:0:0:0:1.2.3.4';

## check 4->6 conversion
my $nipv6 = ipv4to6($nip);
my $ipv6  = ipv6_n2d($nipv6);
is( $ipv6, $exp, 'ipv4to6 converts 1.2.3.4 correctly' );

subtest 'ipv4to6 reads one argument alike in both builds' => sub {
    is( prototype('NetAddr::IP::Util::ipv4to6'),
        '$', 'ipv4to6 has the prototype $' );

    my $arg = NetAddr::IP::Util::inet_aton('192.0.2.1');

    # compiled here, so the prototype decides how the line parses
    is( eval q{ ipv4to6 $arg ? 'yes' : 'no' },
        'yes', 'a call without brackets binds before ?:' );
    is( $@, '', 'that call does not croak' );

    # in list context this returns a name and the argument, as a lookup does
    my $answer = sub { return wantarray ? ( 'host.example', $arg ) : $arg };
    is( eval { ipv4to6( $answer->() ) },
        ipv4to6($arg),
        'an argument that returns a list is read in scalar context' );
    is( $@, '', 'that call does not croak' );
};

## check mask4->6 extension
$exp   = 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:1.2.3.4';
$nipv6 = mask4to6($nip);
$ipv6  = ipv6_n2d($nipv6);
is( $ipv6, $exp, 'mask4to6 extends 1.2.3.4 correctly' );

## check bad length for ipv4to6
$nip = pack( 'H9', 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09 );
like(
    dies { ipv4to6($nip) },
    qr/Bad arg.+ipv4to6/,
    'ipv4to6 dies on bad argument length'
);

## check bad length for mask4to6
like(
    dies { mask4to6($nip) },
    qr/Bad arg.+mask4to6/,
    'mask4to6 dies on bad argument length'
);

done_testing;
