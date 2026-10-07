#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Warnings qw(warning);

# answer host name lookups here so no query leaves the machine; names of
# digits and dots are numeric and still go to the real call
our @looked_up;
our $answer;

BEGIN {
    *CORE::GLOBAL::gethostbyname = sub {
        my ($name) = @_;
        return CORE::gethostbyname($name) if $name =~ /\A[0-9.]+\z/;
        push @looked_up, $name;
        return
          wantarray ? ( $answer ? ( $name, '', 2, 4, $answer ) : () ) : $answer;
    };
}

# one A lookup per name, whether or not Socket6 is installed
use NetAddr::IP::Util qw(:noSock6);
use NetAddr::IP::Lite ();

like(
    warning { NetAddr::IP::Lite::import(':aton') },
    qr/:aton is deprecated/,
    ':aton is deprecated and warns on import'
) or BAIL_OUT(':aton did not import');

# documentation addresses never spell text, so these use the bytes themselves
subtest 'new under :aton reads packed bytes that spell text as text' => sub {
    my %text = (
        '0x1f'             => '0.0.0.31/32',
        '1 23'             => '1.0.0.0/23',
        '1.23'             => '1.0.0.23/32',
        '1234'             => '0.0.4.210/32',
        '198.51.100.10/24' => '198.51.100.10/24',
        '::1f'             => '0:0:0:0:0:0:0:1F/128',
        'a bc'             => undef,
    );
    for my $bytes ( sort keys %text ) {
        my $ip = NetAddr::IP::Lite->new($bytes);
        is( defined $ip ? $ip->cidr : undef,
            $text{$bytes}, "->new('$bytes') is read as text, not packed" );
    }
    is( NetAddr::IP::Lite->new_from_aton('1 23')->cidr,
        '49.32.50.51/32', '->new_from_aton reads the same bytes as packed' );
};

subtest 'new under :aton returns undef for a packed colon byte' => sub {
    my %colon = (
        '192.0.2.58'   => pack( 'C4', 192,    0, 2, 58 ),
        '2001:db8::3a' => pack( 'n8', 0x2001, 0x0db8, 0, 0, 0, 0, 0, 0x3a ),
    );
    for my $addr ( sort keys %colon ) {
        is( NetAddr::IP::Lite->new( $colon{$addr} ),
            undef, "->new(packed $addr) is undef" );
    }
    is(
        NetAddr::IP::Lite->new_from_aton( $colon{'192.0.2.58'} )->cidr,
        '192.0.2.58/32',
        '->new_from_aton(packed 192.0.2.58) is the address'
    );
};

subtest 'new under :aton looks up packed bytes that spell a host name' => sub {
    local @looked_up;
    local $answer;
    is(
        NetAddr::IP::Lite->new('mail')->cidr,
        '109.97.105.108/32',
        '->new(packed 109.97.105.108) is packed when no host answers'
    );
    is( \@looked_up, ['mail'],
        'the bytes were looked up as a host name first' );

    @looked_up = ();
    $answer    = pack( 'C4', 192, 0, 2, 1 );
    is(
        NetAddr::IP::Lite->new('mail')->cidr,
        '192.0.2.1/32',
        '->new(packed 109.97.105.108) is the answer when a host answers'
    );

    @looked_up = ();
    is( NetAddr::IP::Lite->new_from_aton('mail')->cidr,
        '109.97.105.108/32', '->new_from_aton reads the same bytes as packed' );
    is( \@looked_up, [], '->new_from_aton makes no lookup' );
};

done_testing;
