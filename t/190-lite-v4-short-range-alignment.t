#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

my $L = 'NetAddr::IP::Lite';

# the string form of an object, or undef
sub show {
    my ($ip) = @_;
    return defined $ip ? "$ip" : undef;
}

# true when lo-hi covers exactly one aligned block of addresses
sub is_one_block {
    my ($lo, $hi) = @_;
    my $size = $hi - $lo + 1;
    return ($size & ($size - 1)) == 0 && $lo % $size == 0;
}

subtest 'a short range that is one aligned block is that subnet' => sub {
    my %want = (
        '0-255.'          => '0.0.0.0/0',
        '192-223.'        => '192.0.0.0/3',
        '192.0-3.'        => '192.0.0.0/14',
        '192.0.0-3.'      => '192.0.0.0/22',
        '192.0.2.0-255'   => '192.0.2.0/24',
        '192.0.2.4-7'     => '192.0.2.4/30',
        '192.0.2.5-5'     => '192.0.2.5/32',
        '198.51.100.8-15' => '198.51.100.8/29',
    );
    for my $range (sort keys %want) {
        is( show($L->new($range)),
            $want{$range}, "a call new of $range is that subnet"
        );
    }
};

subtest 'a short range that is not one aligned block is undef' => sub {
    for my $range (
        '1-2.',          '192.1-2.',    '192.0.1-2.',  '192.0.2.1-2',
        '192.0.2.1-14',  '192.0.2.2-5', '192.0.2.5-6', '203.0.113.9-10',
        '192.0.2.0-254', '192.0.2.4-6'
    ) {
        is($L->new($range), undef, "a call new of $range is undef");
    }
    is( $L->new_no('192.0.2.5-6'),
        undef, 'a call new_no of 192.0.2.5-6 is undef'
    );
};

subtest 'a call to new6 reads a short range the same way' => sub {
    is($L->new6('192.0.2.5-6'), undef, 'a call new6 of 192.0.2.5-6 is undef');
    is( show($L->new6('192.0.2.4-7')),
        '0:0:0:0:0:0:C000:204/126',
        'a call new6 of an aligned range stays that subnet'
    );
};

subtest 'every range in the last octet is defined exactly when it is one block' => sub {
    my @wrong;
    for my $lo (0 .. 255) {
        for my $hi ($lo .. 255) {
            my $ip = $L->new("192.0.2.$lo-$hi");
            push @wrong, "192.0.2.$lo-$hi"
                if !!$ip != !!is_one_block($lo, $hi);
        }
    }
    is(\@wrong, [], 'no range is accepted or refused against the rule');
};

subtest 'a short or range form takes only its own mask or host as a mask' => sub {
    for my $case (
        [ '192.',                  8,  '192.0.0.0/8' ],
        [ '192-195.',              6,  '192.0.0.0/6' ],
        [ '192.0.',                16, '192.0.0.0/16' ],
        [ '192.0-3.',              14, '192.0.0.0/14' ],
        [ '192.0.2.',              24, '192.0.2.0/24' ],
        [ '192.0.0-3.',            22, '192.0.0.0/22' ],
        [ '192.0.2.4-7',           30, '192.0.2.4/30' ],
        [ '192.0.2.0-192.0.2.255', 24, '192.0.2.0/24' ],
    ) {
        my ($form, $own, $want) = @$case;
        my $other = $own == 24 ? 28 : 24;
        is(show($L->new($form, $own)),   $want, "a call new('$form', $own) is $want");
        is(show($L->new($form, 'host')), $want, "a call new('$form', 'host') is $want");
        is($L->new($form, $other),       undef, "a call new('$form', $other) is undef");
        is($L->new("$form/$other"),      undef, "a call new('$form/$other') is undef");
    }
    is( $L->new('192.0.2.', '255.255.255.240'),
        undef, "a call new('192.0.2.', '255.255.255.240') is undef"
    );
    is($L->new6('192.0.2.', 24), undef, "a call new6('192.0.2.', 24) is undef");
    is( show($L->new6('192.0.2.', 120)),
        '0:0:0:0:0:0:C000:200/120',
        "a call new6('192.0.2.', 120) is ::192.0.2.0/120"
    );
};

done_testing;
