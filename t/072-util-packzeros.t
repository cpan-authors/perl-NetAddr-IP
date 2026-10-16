#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util     qw( packzeros );
use NetAddr::IP::InetBase ();

my %addr = (
    'D0:00:0000:0000:000:b00:0000:000' => 'd0::b00:0:0',
    '0d0:00:0000:0000:000:0B00::'      => 'd0::b00:0:0',
    '::c3D4:e5d6:0:0:0:0'              => '0:0:c3d4:e5d6::',
    '0:0000:c3D4:e5d6:0:0:0:0'         => '0:0:c3d4:e5d6::',
    '0:0:0:0:0:0:0:0'                  => '::',
    '0:0::'                            => '::',
    '::0:000:0'                        => '::',
    '0:0::1.2.3.4'                     => '::1.2.3.4',
    '::1.2.3.4'                        => '::1.2.3.4',
    '::01b2:C3d4:0:0:0:1.2.3.4'        => '0:1b2:c3d4::1.2.3.4',
    '0:0:0:0:a1b2:c3D4::'              => '::a1b2:c3d4:0:0',
    '12:0:0:0:34:0:00:000'             => '12::34:0:0:0',
);

# loading NetAddr::IP::Util sets uppercase, so this loop runs under it
for my $input ( sort keys %addr ) {
    is( packzeros($input), $addr{$input}, "packzeros($input)" );
}

subtest 'packzeros is lowercase whatever the case setting' => sub {
    my $input = '2001:0DB8:0:0:0:0:A:B';
    NetAddr::IP::InetBase::upper();
    is( packzeros($input), '2001:db8::a:b', 'packzeros after upper()' );
    NetAddr::IP::InetBase::lower();
    is( packzeros($input), '2001:db8::a:b', 'packzeros after lower()' );
    NetAddr::IP::InetBase::upper();
    is(
        NetAddr::IP::InetBase::inet_ntop(
            NetAddr::IP::InetBase::AF_INET6(),
            NetAddr::IP::InetBase::ipv6_aton($input)
        ),
        '2001:db8::a:b',
        'inet_ntop after upper()'
    );
};

done_testing;
