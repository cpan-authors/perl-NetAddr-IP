#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use Math::BigInt      ();
use NetAddr::IP       ();
use NetAddr::IP::Lite ();

# the order operators on two operands, or the error they die with
sub order {
    my ($left, $right) = @_;
    my $got = eval {
        +{  '<'   => $left < $right,
            '<='  => $left <= $right,
            '<=>' => $left <=> $right,
            '>'   => $left > $right,
            '>='  => $left >= $right,
        };
    };
    return $got // $@;
}

# cmp and the four operators perl builds from it, or the error they die with
sub text_order {
    my ($left, $right) = @_;
    my $got = eval {
        +{  cmp => $left cmp $right,
            ge  => $left ge $right,
            gt  => $left gt $right,
            le  => $left le $right,
            lt  => $left lt $right,
        };
    };
    return $got // $@;
}

my %gt = (
    '255.255.255.255/32 vs 0.0.0.0/0'                 => [ '255.255.255.255/32',                      '0.0.0.0/0' ],
    'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff vs ::/0' => [ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', '::/0' ],
    '10.0.1.0/16 vs 10.0.0.1/24'                      => [ '10.0.1.0/16',                             '10.0.0.1/24' ],
    '10.0.0.1/24 vs 10.0.0.0/24'                      => [ '10.0.0.1/24',                             '10.0.0.0/24' ],
    'deaf:beef::1/64 vs dead:beef::/64'               => [ 'deaf:beef::1/64', 'dead:beef::/64' ],
);

my %ngt = (
    '0.0.0.0/0 vs 255.255.255.255/32'                 => [ '0.0.0.0/0',   '255.255.255.255/32' ],
    '::/0 vs ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' => [ '::/0',        'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' ],
    '10.0.0.0/24 vs 10.0.0.0/24'                      => [ '10.0.0.0/24', '10.0.0.0/24' ],
    'dead:beef::/60 vs dead:beef::/60'                => [ 'dead:beef::/60', 'dead:beef::/60' ],
);

my %cmp = (
    '0.0.0.0/0 vs 255.255.255.255/32'                 => [ '0.0.0.0/0', '255.255.255.255/32',                      -1 ],
    '::/0 vs ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' => [ '::/0',      'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', -1 ],
    '10.0.0.0/16 vs 10.0.0.0/8'                       => [ '10.0.0.0/16',        '10.0.0.0/8',                     1 ],
    'dead:beef::/60 vs dead:beef::/40'                => [ 'dead:beef::/60',     'dead:beef::/40',                 1 ],
    '10.0.0.0/24 vs 10.0.0.0/8'                       => [ '10.0.0.0/24',        '10.0.0.0/8',                     1 ],
    '255.255.255.255/32 vs 0.0.0.0/0'                 => [ '255.255.255.255/32', '0.0.0.0/0',                      1 ],
    'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff vs ::/0' => [ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff', '::/0',      1 ],
    '142.52.5.87 vs 142.52.2.88'                      => [ '142.52.5.87', '142.52.2.88',                           1 ],
    '10.0.0.0/24 vs 10.0.0.0/24'                      => [ '10.0.0.0/24', '10.0.0.0/24',                           0 ],
    'default vs default'                              => [ 'default',     'default',                               0 ],
    'broadcast vs broadcast'                          => [ 'broadcast',   'broadcast',                             0 ],
    'loopback vs loopback'                            => [ 'loopback',    'loopback',                              0 ],
);

subtest 'greater than' => sub {
    for my $name (sort keys %gt) {
        my ($a_val, $b_val) = @{ $gt{$name} };
        my $a_ip = NetAddr::IP::Lite->new($a_val);
        my $b_ip = NetAddr::IP::Lite->new($b_val);

        ok($a_ip > $b_ip, "$a_ip > $b_ip");
    }
};

subtest 'not greater than' => sub {
    for my $name (sort keys %ngt) {
        my ($a_val, $b_val) = @{ $ngt{$name} };
        my $a_ip = NetAddr::IP::Lite->new($a_val);
        my $b_ip = NetAddr::IP::Lite->new($b_val);

        ok(!($a_ip > $b_ip), "$a_ip !> $b_ip");
    }
};

subtest 'spaceship and cmp' => sub {
    for my $name (sort keys %cmp) {
        my ($a_val, $b_val, $expected) = @{ $cmp{$name} };
        my $a_ip = NetAddr::IP::Lite->new($a_val);
        my $b_ip = NetAddr::IP::Lite->new($b_val);

        is($a_ip <=> $b_ip, $expected, "$a_ip <=> $b_ip is $expected");
        is($a_ip cmp $b_ip, $expected, "$a_ip cmp $b_ip is $expected");
    }
};

subtest 'IPv4 orders before IPv6 holding the same 128 bits' => sub {
    my %same_bits = (
        'a host'          => [ '192.0.2.4',    '::192.0.2.4' ],
        'a subnet'        => [ '192.0.2.4/24', '::192.0.2.4/120' ],
        'the /0 boundary' => [ '192.0.2.4/0',  '::192.0.2.4/96' ],
    );
    for my $name (sort keys %same_bits) {
        my ($v4, $v6) =
            map { NetAddr::IP::Lite->new($_) } @{ $same_bits{$name} };
        is( order($v4, $v6),
            { '<' => 1, '<=' => 1, '<=>' => -1, '>' => 0, '>=' => 0 },
            "$name in IPv4 orders before $v6"
        );
        is( order($v6, $v4),
            { '<' => 0, '<=' => 0, '<=>' => 1, '>' => 1, '>=' => 1 },
            "$name in IPv6 orders after $v4"
        );
        is( text_order($v4, $v6),
            { cmp => -1, ge => '', gt => '', le => 1, lt => 1 },
            "$name in IPv4 sorts before $v6 under cmp"
        );
        is( [ map { "$_" } sort $v6, $v4 ],
            [ "$v4",                 "$v6" ],
            "sort puts $name in IPv4 first"
        );
    }
};

subtest 'spaceship gives 0 only for ==, cmp gives 0 only for eq' => sub {
    my @ips = (
        NetAddr::IP::Lite->new('192.0.2.4'),
        NetAddr::IP::Lite->new('192.0.2.4/32'),
        NetAddr::IP->new('192.0.2.4'),
        NetAddr::IP::Lite->new('::192.0.2.4'),
        NetAddr::IP::Lite->new('::ffff:192.0.2.4'),
        NetAddr::IP::Lite->new('192.0.2.4/24'),
        NetAddr::IP::Lite->new('::192.0.2.4/120'),
    );
    my @disagree;
    for my $left (@ips) {
        for my $right (@ips) {
            push @disagree, "$left <=> $right"
                if (($left <=> $right) == 0 ? 1 : 0) != ($left == $right ? 1 : 0);
            push @disagree, "$left cmp $right"
                if (($left cmp $right) == 0 ? 1 : 0) != ($left eq $right ? 1 : 0);
        }
    }
    is(\@disagree, [], 'no pair of addresses disagrees');
};

subtest 'an operand that is not an object is unordered' => sub {
    my $ip         = NetAddr::IP::Lite->new('192.0.2.1');
    my %not_object = (
        'a class name'                => 'NetAddr::IP::Lite',
        'a number'                    => 5,
        'an empty string'             => '',
        'text that is not an address' => 'x',
        'the address as text'         => '192.0.2.1/32',
        'undef'                       => undef,
    );
    my %unordered = ('<' => 0, '<=' => 0, '<=>' => undef, '>' => 0, '>=' => 0);
    for my $name (sort keys %not_object) {
        is( order($ip, $not_object{$name}),
            \%unordered, "the address against $name is unordered"
        );
        is( order($not_object{$name}, $ip),
            \%unordered, "$name against the address is unordered"
        );
    }

    # Math::BigInt answers for itself when it is the left operand
    is( order($ip, Math::BigInt->new(5)),
        \%unordered, 'the address against a Math::BigInt is unordered'
    );

    my $full = NetAddr::IP->new('192.0.2.1');
    is($full <=> $ip, 0, 'an IP object and a Lite object compare by address');
    is( order($full, 'x'),
        \%unordered, 'an IP object against text is unordered'
    );

    my $undef_operand;
    my $lived = eval { my $less = $ip < $undef_operand; 1 };
    is($lived,             1,  'ordering against an undef variable lives');
    is(ref $undef_operand, '', 'that undef variable stays undef');
};

subtest 'cmp against text compares the CIDR text, as eq does' => sub {
    my $ip    = NetAddr::IP::Lite->new('192.0.2.1');
    my %equal = (cmp => 0, ge => 1, gt => '', le => 1, lt => '');
    is( text_order($ip, '192.0.2.1/32'),
        \%equal, 'the address against its CIDR text is equal'
    );
    is( text_order('192.0.2.1/32', $ip),
        \%equal, 'its CIDR text against the address is equal'
    );
    is( text_order($ip, 'x'),
        { cmp => -1, ge => '', gt => '', le => 1, lt => 1 },
        'the address sorts before x, as 192.0.2.1/32 does'
    );
    is( text_order('x', $ip),
        { cmp => 1, ge => 1, gt => 1, le => '', lt => '' },
        'x sorts after the address, as it does after 192.0.2.1/32'
    );
};

done_testing;
