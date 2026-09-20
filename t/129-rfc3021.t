#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP ();

my $ip = NetAddr::IP->new('192.0.2.8/31');
my @hosts = $ip->hostenum;

is(scalar @hosts, 2, 'unmarked /31 reports 2 hosts');

is("$hosts[0]", '192.0.2.8/32', 'first host is 192.0.2.8/32');
is("$hosts[1]", '192.0.2.9/32', 'second host is 192.0.2.9/32');

my $ip6 = NetAddr::IP->new('2001:DB8::/127');
@hosts = $ip6->hostenum;

is(scalar @hosts, 2, '/127 reports 2 hosts');
is("$hosts[0]", '2001:DB8:0:0:0:0:0:0/128', 'first host is 2001:DB8::/128');
is("$hosts[1]", '2001:DB8:0:0:0:0:0:1/128', 'second host is 2001:DB8::1/128');

@hosts = NetAddr::IP->new('192.0.2.8/30')->hostenum;
is(scalar @hosts, 2, '/30 still drops network and broadcast');
is("$hosts[0]", '192.0.2.9/32', 'first host is 192.0.2.9/32');

my @w;
{
    local $SIG{__WARN__} = sub { push @w, @_ };
    NetAddr::IP->import(qw(:rfc3021));
}
like($w[0], qr/:rfc3021.*deprecated/, ':rfc3021 import emits deprecation warning');

@hosts = $ip->hostenum;
is(scalar @hosts, 2, ':rfc3021 tag is accepted and changes nothing');
is("$hosts[1]", '192.0.2.9/32', 'second host is still 192.0.2.9/32');

done_testing;
