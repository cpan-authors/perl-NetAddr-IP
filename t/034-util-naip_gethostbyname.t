#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw(
    havegethostbyname2
    inet_ntoa
    ipv6_n2x
    naip_gethostbyname
);

my $exp  = '0:0:0:0:0:FFFF:7F00:1';
my $host = '127.1';
my $got  = ipv6_n2x(scalar naip_gethostbyname($host));
is($got, $exp, 'naip_gethostbyname resolves 127.1');

$exp  = '0:0:0:0:0:0:0:1';
$host = $exp;

if (havegethostbyname2()) {
    $got = ipv6_n2x(scalar naip_gethostbyname($host));
    is($got, $exp, 'naip_gethostbyname resolves IPv6 loopback');
}
else {
    note('gethostbyname2 missing from Socket6')
        if eval { require Socket6 };
    $got = scalar naip_gethostbyname($host);
    if ($got) {
        $got = eval { inet_ntoa($got) }
            || eval { ipv6_n2x($got) };
    }
    ok(!$got, 'naip_gethostbyname returns undef when gethostbyname2 unavailable');
}

done_testing;
