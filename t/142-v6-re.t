#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw(lives);

use NetAddr::IP ();
use NetAddr::IP::Util qw( addconst );

my @ips = qw(
    ::0:0f00
    ::FF:1e10
    ::ffFF:2d20
    ::eFF:3c30
    ::eeFF:4b40
    ::FF:5a50
    ::FF:6960
    ::FF:7870
    ::FF:8780
    ::FF:9690
    ::FF:a5a0
    ::FF:b4b0
    ::FF:c3c0
    ::FF:d2d0
    ::FF:e1e0
    ::FF:f0f0
);
my @mask = qw( 128 126 125 124 123 122 121 120 );

if (defined($ENV{LIGHTERIPTESTS}) and $ENV{LIGHTERIPTESTS} =~ m/yes/i) {
    pop @mask;
    pop @mask;
}

my @addrs;
for my $m (@mask) {
    for my $ip (@ips) {
        push @addrs, NetAddr::IP->new($ip, $m);
    }
}

subtest 're6 regex compilation and matching' => sub {
    for my $subnet (@addrs) {
        ok($subnet->isa('NetAddr::IP'), 'isa NetAddr::IP');
        my $re = $subnet->re6;
        my $rx;

        ok(lives { $rx = qr/$re/ }, 'Compilation of the resulting regular expression');

        for (my $ip = $subnet->network;
             $ip < $subnet->broadcast && $subnet->masklen != 128;
             $ip++)
        {
            ok($ip->addr =~ m/$rx/, "Match of $ip in $subnet");
        }

        ok($subnet->broadcast->addr =~ m/$rx/, "Match of broadcast of $subnet");
        my $under = $subnet->network->copy;
        $under->{addr} = (addconst($under->{addr}, -1))[1];
        my $over = $subnet->broadcast->copy;
        $over->{addr} = (addconst($over->{addr}, 1))[1];
        ok($under !~ m/$rx/, "$under does not match");
        ok($over !~ m/$rx/, "$over does not match");
        ok(NetAddr::IP->new('::') !~ m/$rx/, ':: does not match');
    }
};

subtest 're6() returns a non-capturing group' => sub {
    my $re = NetAddr::IP->new('2001:db8::/32')->re6;
    like($re, qr/^\(\?:/, 're6() starts with (?:');
    my $rx = qr/$re/;
    ok('2001:db8:0:0:0:0:0:1' =~ /^($re)$/, 'single capture group works');
    is($1, '2001:db8:0:0:0:0:0:1', 'captured address is correct');
    ok('2001:db8:0:0:0:0:0:1 port=80' =~ /^($re)\s+port=(\d+)$/, 'two caller groups with re6');
    is($1, '2001:db8:0:0:0:0:0:1', 'first group captures address');
    is($2, '80', 'second group captures port');
};

done_testing;

