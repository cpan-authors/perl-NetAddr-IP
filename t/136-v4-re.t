#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( lives );

use NetAddr::IP ();

my @ips = qw(
    198.51.100.13
    198.51.100.0/24
    198.51.100.0/27
);

subtest 'basic validation and iteration' => sub {
    for my $input (@ips) {
        my $subnet = NetAddr::IP->new($input);
        isa_ok($subnet, 'NetAddr::IP');
        my $re = $subnet->re;
        my $rx;

        ok(lives { $rx = qr/$re/ }, "Compilation of the resulting regular expression for $input");

        for (my $ip = $subnet->network; $ip < $subnet->broadcast && $subnet->masklen != 32; $ip++) {
            like($ip->addr, qr/$rx/, "Match of $ip in $subnet");
        }

        like($subnet->broadcast->addr, qr/$rx/, "Match of broadcast of $subnet");
        unlike(NetAddr::IP->new('default'), qr/$rx/, '0/0 does not match');
    }
};

subtest 're returns a regex whose octet alternation is order independent' => sub {
    # a /25 last octet range spans 1, 12 and 127 in TEST-NET-1 (192.0.2.0/25),
    # so one alternative is a prefix of another and only backtracking can save the longer match
    my $re = NetAddr::IP->new('192.0.2.0/25')->re;
    my $rx = qr/$re/;

    for my $in (qw(192.0.2.0 192.0.2.1 192.0.2.9 192.0.2.12 192.0.2.19
                   192.0.2.100 192.0.2.126 192.0.2.127)) {
        like($in, $rx, "re of 192.0.2.0/25 matches in subnet address $in");
    }
    for my $out (qw(192.0.2.128 192.0.2.129 192.0.2.200 192.0.2.255
                    192.0.3.1 198.51.100.1 203.0.113.1)) {
        unlike($out, $rx, "re of 192.0.2.0/25 rejects out of subnet address $out");
    }
};

subtest 're guards reject an address embedded in a longer dotted string' => sub {
    my $re24 = NetAddr::IP->new('203.0.113.0/24')->re;
    my $rx24 = qr/$re24/;

    like('203.0.113.3',             $rx24, 'plain in subnet address matches');
    like('host 203.0.113.3 is up',  $rx24, 'address surrounded by words matches');
    like('x203.0.113.3x',           $rx24, 'address surrounded by letters matches');
    like('203.0.113.3-rc1',         $rx24, 'address followed by a dash matches');
    like('it ends at 203.0.113.3.', $rx24, 'address ending a sentence matches');
    like('203.0.113.3:8080',        $rx24, 'address followed by a port matches');

    unlike('203.0.113.3.4',      $rx24, 'five octet string 203.0.113.3.4 is rejected');
    unlike('203.0.113.3.5',      $rx24, 'five octet string 203.0.113.3.5 is rejected');
    unlike('1.203.0.113.3',      $rx24, 'leading extra octet 1.203.0.113.3 is rejected');
    unlike('99.203.0.113.3',     $rx24, 'leading extra octet 99.203.0.113.3 is rejected');
    unlike('203.0.113.300',      $rx24, 'out of range octet 203.0.113.300 is rejected');
    unlike('0203.000.113.003',   $rx24, 'octal style leading zeros are rejected');

    my $re168 = NetAddr::IP->new('198.51.100.0/24')->re;
    my $rx168 = qr/$re168/;
    unlike('1.198.51.100.1', $rx168, 'leading extra octet 1.198.51.100.1 is rejected');
    unlike('198.51.100.1.5', $rx168, 'trailing extra octet 198.51.100.1.5 is rejected');
};

subtest 're handles mask length 0, 31 and 32' => sub {
    my $re0 = NetAddr::IP->new('0.0.0.0/0')->re;
    my $rx0 = qr/$re0/;
    like('192.0.2.4',       $rx0, 'default route regex matches any TEST-NET-1 address');
    like('198.51.100.255',  $rx0, 'default route regex matches any TEST-NET-2 address');
    like('203.0.113.123',   $rx0, 'default route regex matches any TEST-NET-3 address');
    unlike('256.1.1.1',     $rx0, 'default route regex rejects an out of range octet');
    unlike('1.192.0.2.3',   $rx0, 'default route regex rejects a five octet string (leading)');
    unlike('192.0.2.3.4',   $rx0, 'default route regex rejects a five octet string (trailing)');

    my $re31 = NetAddr::IP->new('192.0.2.0/31')->re;
    my $rx31 = qr/$re31/;
    like('192.0.2.0',  $rx31, 'slash 31 regex matches the lower address');
    like('192.0.2.1',  $rx31, 'slash 31 regex matches the upper address');
    unlike('192.0.2.2', $rx31, 'slash 31 regex rejects the next address');

    my $re32 = NetAddr::IP->new('203.0.113.4/32')->re;
    my $rx32 = qr/$re32/;
    like('203.0.113.4',    $rx32, 'slash 32 regex matches its own address');
    unlike('203.0.113.4.5', $rx32, 'slash 32 regex is not found inside five octet string');
};

done_testing;
