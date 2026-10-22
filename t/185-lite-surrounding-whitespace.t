#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Warnings qw( warning );

use NetAddr::IP::Lite ();

sub shown {
    my ($text) = @_;
    $text =~ s/\n/\\n/g;
    $text =~ s/\r/\\r/g;
    $text =~ s/\t/\\t/g;
    return $text;
}

sub made {
    my ( $method, @args ) = @_;
    my $ip = NetAddr::IP::Lite->$method(@args);
    return defined $ip ? "$ip" : undef;
}

subtest 'an address with surrounding whitespace converts' => sub {
    my %cidr = (
        "\t2001:db8::1 "            => '2001:DB8:0:0:0:0:0:1/128',
        "192.0.2.0 255.255.255.0\n" => '192.0.2.0/24',
        "192.0.2.0-192.0.2.7\n"     => '192.0.2.0/29',
        "192.0.2.0/24\r\n"          => '192.0.2.0/24',
        "192.0.2.1\n"               => '192.0.2.1/32',
        "::ffff:192.0.2.1\n"        => '0:0:0:0:0:FFFF:C000:201/128',
        "[2001:db8::1]/64\n"        => '2001:DB8:0:0:0:0:0:1/64',
    );
    for my $text ( sort keys %cidr ) {
        my $name = shown($text);
        is( made( 'new', $text ), $cidr{$text}, "->new('$name')" );
    }
};

subtest 'a separate mask with surrounding whitespace converts' => sub {
    my @cases = (
        [ 'new', '192.0.2.0',  " 24",               '192.0.2.0/24' ],
        [ 'new', '192.0.2.0',  "24\n",              '192.0.2.0/24' ],
        [ 'new', '192.0.2.0',  "255.255.255.0\r\n", '192.0.2.0/24' ],
        [ 'new', '2001:db8::', "32\n",              '2001:DB8:0:0:0:0:0:0/32' ],
        [ 'new6', '192.0.2.0', "24\n", '0:0:0:0:0:0:C000:200/120' ],
    );
    for my $case (@cases) {
        my ( $method, $addr, $mask, $cidr ) = @{$case};
        my $name = shown($mask);
        is( made( $method, $addr, $mask ),
            $cidr, "->$method('$addr', '$name')" );
    }
    is( made( 'new', '192.0.2.0', '  ' ),
        undef, "->new('192.0.2.0', '  ') is undef, as with an empty mask" );
};

subtest 'an IPv4 tail with a leading zero in an octet is not an address' =>
  sub {
    for my $text ( '::192.0.2.010', '::ffff:192.0.02.1', '::ffff:192.0.2.010' )
    {
        for my $method (qw( new new6 new_no )) {
            is( made( $method, $text ), undef, "->$method('$text')" );
        }
    }
    is( made( 'new', '::ffff:192.0.2.10' ),
        '0:0:0:0:0:FFFF:C000:20A/128', "->new('::ffff:192.0.2.10')" );
    is( made( 'new_no', '192.0.2.010' ),
        '192.0.2.10/32', "->new_no('192.0.2.010') still reads decimal" );
  };

subtest 'an IPv4 address with a leading zero in any part is not an address'
  => sub {
    for my $text (
        '00',          '010',            '010/8',
        '010.0.2.1',   '010.1',          '192.0.02.1',
        '192.0.2.01',  '192.0.2.010',    '192.0.2.010/24',
        '192.000.002.010',
      )
    {
        for my $method (qw( new new6 )) {
            is( made( $method, $text ), undef, "->$method('$text')" );
        }
    }
    is( made( 'new', '192.0.2.010', '24' ),
        undef, "->new('192.0.2.010', '24')" );
    is( made( 'new', '192.0.2.0', '255.255.255.000' ),
        undef, "->new('192.0.2.0', '255.255.255.000')" );
    my %cidr = (
        '0'             => '0.0.0.0/32',
        '0.0.0.0'       => '0.0.0.0/32',
        '0001:db8::1'   => '1:DB8:0:0:0:0:0:1/128',
        '10.1'          => '10.0.0.1/32',
        '192.0.2.0/024' => '192.0.2.0/24',
    );
    for my $text ( sort keys %cidr ) {
        is( made( 'new', $text ), $cidr{$text}, "->new('$text')" );
    }
    my %decimal = (
        '010'             => '0.0.0.10/32',
        '192.000.002.010' => '192.0.2.10/32',
    );
    for my $text ( sort keys %decimal ) {
        is( made( 'new_no', $text ),
            $decimal{$text}, "->new_no('$text') reads decimal" );
    }
  };

# :aton is process-wide, so it goes last
like(
    warning { NetAddr::IP::Lite::import(':aton') },
    qr/:aton is deprecated/,
    ':aton is deprecated and warns on import'
) or bail_out(':aton did not import');

subtest 'under :aton only a string of four or sixteen bytes keeps its ends' =>
  sub {
    is( made( 'new', "192.0.2.1\n" ),
        '192.0.2.1/32', "->new('192.0.2.1\\n'), ten bytes, is stripped" );
    is( made( 'new', "::ffff:192.0.2.1\n" ),
        '0:0:0:0:0:FFFF:C000:201/128',
        "->new('::ffff:192.0.2.1\\n'), seventeen bytes, is stripped" );
    my %packed = (
        '192.0.2.10, ending in a newline' =>
          [ pack( 'C4', 192, 0, 2, 10 ), '192.0.2.10/32' ],
        '192.0.2.32, ending in a space' =>
          [ pack( 'C4', 192, 0, 2, 32 ), '192.0.2.32/32' ],
        '2001:db8::a, ending in a newline' => [
            pack( 'n8', 0x2001, 0x0db8, 0, 0, 0, 0, 0, 0x0a ),
            '2001:DB8:0:0:0:0:0:A/128'
        ],
    );
    for my $addr ( sort keys %packed ) {
        my ( $bytes, $cidr ) = @{ $packed{$addr} };
        is( made( 'new', $bytes ), $cidr, "->new(packed $addr)" );
    }
  };

done_testing;
