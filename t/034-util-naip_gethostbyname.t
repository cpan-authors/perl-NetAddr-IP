#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Require::Internet;

use NetAddr::IP ();
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

# GH#32: new6() must prefer AAAA over A when both exist
SKIP: {
    skip 'gethostbyname2 not available', 1
        unless havegethostbyname2();

    my $dual = NetAddr::IP->new6('google-public-dns-a.google.com');
    skip 'DNS resolution unavailable', 1
        unless defined $dual;

    is($dual->version, 6, 'new6(dual-stack hostname) returns IPv6');
}

# GH#64: new6() on an IPv4-only literal returns the compatible form
my $lit = NetAddr::IP->new6('192.0.2.123');
is("$lit", '0:0:0:0:0:0:C000:27B/128', 'new6(literal IPv4) returns compatible form');

done_testing;
