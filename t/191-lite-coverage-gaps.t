#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw(lives);

use NetAddr::IP::Lite;

subtest 'DESTROY and mask keyword fallback paths' => sub {
    ok(lives { NetAddr::IP::Lite->DESTROY; 1 }, 'DESTROY is callable');

    my $host = NetAddr::IP::Lite->new('192.0.2.1', 'host');
    ok(defined $host, 'IPv4 host mask keyword parses');
    is($host->cidr, '192.0.2.1/32', 'host mask is /32');

    my $v6host = NetAddr::IP::Lite->new('2001:db8::1', 'host');
    ok(defined $v6host, 'IPv6 host mask keyword parses');
    is(lc($v6host->cidr), '2001:db8:0:0:0:0:0:1/128', 'host mask is /128');
};

subtest 'constructor failure and :noctal parsing paths' => sub {
    is( NetAddr::IP::Lite->new('999999999999999999999999999999999999999999'),
        undef, 'oversize bcd literal returns undef'
    );

    my $noctal = NetAddr::IP::Lite->new_no('010.0.0.1');
    ok(defined $noctal, 'new_no parses octal-looking dotted quad as decimal');
    is($noctal->cidr, '10.0.0.1/32', 'leading zeros suppressed by :noctal path');

    my $badmask = NetAddr::IP::Lite->new('192.0.2.1', '999999999999999999999999999999999999999999');
    is($badmask, undef, 'oversize numeric mask returns undef');
};

done_testing;
