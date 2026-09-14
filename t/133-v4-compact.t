#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP qw( Compact );

plan skip_all => 'LIGHTERIPTESTS = yes'
    if defined $ENV{LIGHTERIPTESTS} && $ENV{LIGHTERIPTESTS} =~ /yes/i;

my @r = (
    ['10.0.0.0', '255.255.255.0'],
    ['11.0.0.0', '255.255.255.0'],
    ['12.0.0.0', '255.255.255.0'],
    ['20.0.0.0', '255.255.0.0'],
    ['30.0.0.0', '255.255.0.0'],
    ['40.0.0.0', '255.255.0.0'],
);

my @ips1;

for my $ip ('10.0.0.0', '11.0.0.0', '12.0.0.0') {
    push @ips1, NetAddr::IP->new($ip, 24)->split(32);
}

for my $ip ('20.0.0.0', '30.0.0.0', '40.0.0.0') {
    push @ips1, NetAddr::IP->new($ip, 16)->split(28);
}

my @ips2;

for my $num (0 .. 255) {
    push @ips2, NetAddr::IP->new("192.168.$num.0", 24);
}
my $ips2_compact = '192.168.0.0/16';

sub compact_ips1_check {
    my ($result_ips) = @_;
    my @mips;
    for my $ip (@{$result_ips}) {
        push @mips, grep { $ip->addr eq $_->[0] && $ip->mask eq $_->[1] } @r;
    }
    return @mips == @{$result_ips};
}

sub compact_ips2_check {
    my ($result_ips) = @_;
    return @{$result_ips} == 1 && $result_ips->[0] eq $ips2_compact;
}

subtest 'Compact(@)' => sub {
    ok(compact_ips1_check([Compact(@ips1)]), 'Compact(@) ips1');
    ok(compact_ips2_check([Compact(@ips2)]), 'Compact(@) ips2');
};

subtest '->compact(@)' => sub {
    ok(compact_ips1_check([$ips1[0]->compact(@ips1[1 .. $#ips1])]), '->compact(@) ips1');
    ok(compact_ips2_check([$ips2[0]->compact(@ips2[1 .. $#ips2])]), '->compact(@) ips2');
};

subtest 'Compact([])' => sub {
    ok(compact_ips1_check([@{Compact(\@ips1)}]), 'Compact([]) ips1');
    ok(compact_ips2_check([@{Compact(\@ips2)}]), 'Compact([]) ips2');
};

subtest '->compactref([])' => sub {
    ok(compact_ips1_check($ips1[0]->compactref([@ips1[1 .. $#ips1]])), '->compactref([]) ips1');
    ok(compact_ips2_check($ips2[0]->compactref([@ips2[1 .. $#ips2]])), '->compactref([]) ips2');
};

subtest 'duplicate IP' => sub {
    my @dup;
    for my $ip (qw(1.1.1.1 1.1.1.1 1.1.1.1 1.1.1.1)) {
        push @dup, NetAddr::IP->new($ip);
    }
    my @c = NetAddr::IP::compact(@dup);
    ok(@c == 1 && $c[0]->cidr() eq '1.1.1.1/32', 'duplicate IP compacts to single /32');
};

done_testing;
