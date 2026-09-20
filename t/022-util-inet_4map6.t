#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( inet_4map6 inet_aton ipv6_aton ipv6_n2d );

my @stuff = qw(
	192.0.2.1
	192.0.2.4
	::3.4.5.6
	::FFFF:4.5.6.7
	::1:5.4.3.2
	::FEFF:4.3.2.1
);

my $p4 = '0:0:0:0:0:FFFF:';
my $p6 = '0:0:0:0:0:';

for my $idx (0 .. $#stuff) {
	my $pass = 1;
	my $result;
	my $bstr;
	$pass = 0 if $idx > 3;
	if ($stuff[$idx] =~ m/:/) {
		$bstr = ipv6_aton($stuff[$idx]);
		my $prefix = ($stuff[$idx] =~ m/^::F/)
			? $p6 : $p4;
		($result = $stuff[$idx]) =~ s/::/$prefix/;
	}
	else {
		$bstr = inet_aton($stuff[$idx]);
		$result = $p4 . $stuff[$idx];
	}
	my $rv = inet_4map6($bstr);
	if ($pass && ! $rv) {
		fail('failed to return valid address');
	}
	elsif ($pass) {
		$rv = ipv6_n2d($rv);
		is($rv, $result, "mapped address for $stuff[$idx]");
	}
	else {
		ok(! $rv, "no valid mapping for $stuff[$idx]");
	}
}

done_testing;
