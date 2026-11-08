#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw(dies lives);

use NetAddr::IP::UtilPP qw(addconst bcdn2bin bin2bcdn);

sub ipv6 {
    return pack('C16', @_);
}

subtest 'DESTROY is callable' => sub {
    ok(lives { NetAddr::IP::UtilPP->DESTROY; 1 }, 'DESTROY as class method');
    my $obj = bless {}, 'NetAddr::IP::UtilPP';
    ok(lives { $obj->DESTROY; 1 }, 'DESTROY as instance method');
};

subtest 'addconst list context for empty/invalid and zero constant' => sub {
    my $addr = ipv6((0) x 16);

    my @empty = addconst($addr, undef);
    is(\@empty, [ 0, $addr ], 'addconst undef returns (0, addr) in list context');

    my @zero = addconst($addr, 0);
    is(\@zero, [ 0, $addr ], 'addconst zero returns (0, addr) in list context');
};

subtest 'bcdn2bin default-length guard with undef/empty length' => sub {
    my $packed = bin2bcdn(ipv6((0) x 15, 42));

    for my $len (undef, '') {
        my $label = defined $len ? q{''} : 'undef';
        like(
            dies { bcdn2bin($packed, $len) },
            qr/Bad digit count for NetAddr::IP::Util::bcdn2bin/,
            "bcdn2bin croaks on $label length after default guard"
        );
    }
};

done_testing;
