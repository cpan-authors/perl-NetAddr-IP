#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::InetBase qw( packzeros );

my %addr = (    # input                         expected
	'D0:00:0000:0000:000:b00:0000:000'  => 'd0::b00:0:0',
	'0d0:00:0000:0000:000:0b00::'       => 'd0::b00:0:0',
	'::c3D4:E5d6:0:0:0:0'               => '0:0:c3d4:e5d6::',
	'0:0000:c3D4:e5d6:0:0:0:0'          => '0:0:c3d4:e5d6::',
	'0:0:0:0:0:0:0:0'                   => '::',
	'0:0::'                             => '::',
	'::0:000:0'                         => '::',
	'0:0::1.2.3.4'                      => '::1.2.3.4',
	'::1.2.3.4'                         => '::1.2.3.4',
	'::01b2:c3D4:0:0:0:1.2.3.4'         => '0:1b2:c3d4::1.2.3.4',
	'0:0:0:0:a1B2:c3d4::'               => '::a1b2:c3d4:0:0',
	'12:0:0:0:34:0:00:000'              => '12::34:0:0:0',
);

for my $input ( sort keys %addr ) {
	my $rv   = packzeros($input);
	my $exp  = $addr{$input};
	is($rv, $exp, "packzeros('$input')");
}

done_testing;
