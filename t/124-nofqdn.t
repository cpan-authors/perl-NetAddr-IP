#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Require::Internet ();

use NetAddr::IP ();

my $ip = NetAddr::IP->new('arin.net');
ok(defined $ip, 'resolved arin.net');
like("$ip", qr/^\d+\.\d+\.\d+\.\d+\/\d+$/, 'arin.net resolves to an IP address');

done_testing;
