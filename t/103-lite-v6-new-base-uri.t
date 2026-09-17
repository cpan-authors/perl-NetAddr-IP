#!/usr/bin/env perl

use Test2::V1 -ipP;

use NetAddr::IP::Lite ();

subtest 'nth on v6 URI addresses' => sub {
    my @addr = (
        ['[::]',                 3,   '0:0:0:0:0:0:0:0/128',        0],
        ['[::1]',                3,   '0:0:0:0:0:0:0:1/128',        0],
        ['[F34::123/40]',        2,   'F34:0:0:0:0:0:0:3/40',       1],
        ['[DEAD:BEEF::1/40]',    2,   'DEAD:BEEF:0:0:0:0:0:3/40',   1],
        ['[1000::2/40]',         0,   '1000:0:0:0:0:0:0:1/40',      1],
        ['[1000::2000/40]',      0,   '1000:0:0:0:0:0:0:1/40',      1],
        ['[DEAD::CAFE/40]',      0,   'DEAD:0:0:0:0:0:0:1/40',      1],
        ['[DEAD:BEEF::1/40]',    3,   'DEAD:BEEF:0:0:0:0:0:4/40',   1],
        ['[DEAD:BEEF::1/40]',    4,   'DEAD:BEEF:0:0:0:0:0:5/40',   1],
        ['[DEAD:BEEF::1/40]',    5,   'DEAD:BEEF:0:0:0:0:0:6/40',   1],
        ['[DEAD:BEEF::1/40]',    6,   'DEAD:BEEF:0:0:0:0:0:7/40',   1],
        ['[DEAD:BEEF::1/40]',    7,   'DEAD:BEEF:0:0:0:0:0:8/40',   1],
        ['[DEAD:BEEF::1/40]',    8,   'DEAD:BEEF:0:0:0:0:0:9/40',   1],
        ['[DEAD:BEEF::1/40]',    254, 'DEAD:BEEF:0:0:0:0:0:FF/40',  1],
        ['[DEAD:BEEF::1/40]',    255, 'DEAD:BEEF:0:0:0:0:0:100/40', 1],
        ['[DEAD:BEEF::1/40]',    256, 'DEAD:BEEF:0:0:0:0:0:101/40', 1],
        ['[DEAD:BEEF::1/40]',    65535, 'DEAD:BEEF:0:0:0:0:1:0/40', 1],
        ['[DEAD:BEEF::1/40]',    65536, 'DEAD:BEEF:0:0:0:0:1:1/40', 1],
        ['[2001:620:0:4::/64]',  0,   '2001:620:0:4:0:0:0:1/64',    1],
        ['[3FFE:2000:0:4::/64]', 0,   '3FFE:2000:0:4:0:0:0:1/64',   1],
        ['[2001:620:600::1]',    0,   '2001:620:600:0:0:0:0:1/128', 1],
        ['[2001:620:600:0:1::1]', 0,  '2001:620:600:0:1:0:0:1/128', 1],
    );

    for my $entry (@addr) {
        my ($input, $index, $expected, $should_pass) = @{$entry};
        my $ip = NetAddr::IP::Lite->new($input);
        (my $base = $input) =~ s{/[0-9]+}{};
        isa_ok($ip, ['NetAddr::IP::Lite'], "$base ");
        is($ip->bits, 128, 'bits == 128');
        is($ip->version, 6, 'version == 6');
        if ($should_pass) {
            is(uc $ip->nth($index), $expected, "nth $base, $index");
        }
        else {
            ok(!$ip->nth($index), "nth $base, undef");
        }
    }
};

subtest 'contains' => sub {
    my $test = NetAddr::IP::Lite->new('f34::1');
    isa_ok($test, 'NetAddr::IP::Lite');
    ok($test->network->contains($test), '->contains /128');

    $test = NetAddr::IP::Lite->new('f35::1/40');
    isa_ok($test, 'NetAddr::IP::Lite');
    ok($test->network->contains($test), '->contains /40');
};

subtest 'URI bracket notation [addr]/mask' => sub {
    my %cases = (
        '[::1]/64'              => '0:0:0:0:0:0:0:1/64',
        '::1/64'                => '0:0:0:0:0:0:0:1/64',
        '[::1/64]'              => '0:0:0:0:0:0:0:1/64',
        '[::1]'                 => '0:0:0:0:0:0:0:1/128',
        '[2001:db8::1]/48'      => '2001:DB8:0:0:0:0:0:1/48',
        '[2001:db8::1/48]'      => '2001:DB8:0:0:0:0:0:1/48',
        '[2001:db8::1] 48'      => '2001:DB8:0:0:0:0:0:1/48',
        '[DEAD::CAFE]/32'       => 'DEAD:0:0:0:0:0:0:CAFE/32',
    );
    for my $input (sort keys %cases) {
        my $ip = NetAddr::IP::Lite->new($input);
        isa_ok($ip, ['NetAddr::IP::Lite'], "$input parses");
        is("$ip", $cases{$input}, "$input => $cases{$input}");
    }
};

done_testing;
