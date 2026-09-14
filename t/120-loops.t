#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP ();

my @deltas = (0, 1, 2, 3, 255);

subtest 'octet increment' => sub {
    my $count = 1;

    for (my $ip = NetAddr::IP->new('10.0.0.1/28');
         $ip < $ip->broadcast;
         $ip ++)
    {
        my $o = $ip->addr;

        $o =~ s/^.+\.([0-9]+)$/$1/;
        is($o, $count, 'Correct octet for ' . $ip);
        ++ $count;
    }
};

my $ip = NetAddr::IP->new('10.0.0.255/24');
$ip ++;

is($ip, '10.0.0.0/24', 'Correct mask wraparound');

$ip = NetAddr::IP->new('10.0.0.0/24');

for my $v (@deltas) {
    my $target = '10.0.0.' . $v . '/24';
    is($ip + $v, '10.0.0.' . $v . '/24', "$ip + $v vs $target");
}

done_testing;
