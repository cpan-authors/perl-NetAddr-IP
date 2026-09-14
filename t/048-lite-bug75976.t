#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

my $ud = undef;
my @bugtest = (
	0	=> '0.0.0.0/32', '0:0:0:0:0:0:0:0/128',
	$ud	=> '0.0.0.0/0',  '0:0:0:0:0:0:0:0/0',
	""	=> 'undef',      'undef',
);

for (my $i = 0; $i <= $#bugtest; $i += 3) {
	my $ip6  = sprintf('%s', NetAddr::IP::Lite->new6($bugtest[$i]) || 'undef');
	my $ip   = sprintf('%s', NetAddr::IP::Lite->new($bugtest[$i])  || 'undef');
	my $expip  = $bugtest[$i + 1];
	my $expip6 = $bugtest[$i + 2];

    my $text = $bugtest[$i] // 'undef';
	is($ip,  $expip,  "new($text)");
	is($ip6, $expip6, "new6($text)");
}

done_testing;
