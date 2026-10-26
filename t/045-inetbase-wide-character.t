#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

# an upgraded argument is downgraded before Socket's inet_ntop reads it
use NetAddr::IP::InetBase qw(
  :lower
  inet_n2ad
  inet_n2dx
  inet_ntoa
  ipv6_n2d
  ipv6_n2x
  ipv6_ntoa
  isAnyIPv4
  isIPv4
  isNewIPv4
);

my $THIS_FILE = __FILE__;
my $V4_TEXT   = '192.0.2.1';
my $V6_TEXT   = '2001:db8::1';
my $V6_TEXT_D = '2001:db8:0:0:0:0:0.0.0.1';
my $V6_TEXT_X = '2001:db8:0:0:0:0:0:1';
my $WIDE      = "\x{100}";    # one character above 0xFF, two bytes in UTF-8
my $WIDE_DIES = 'Wide character in NetAddr::IP::InetBase::%s';

# each holds a byte above 0x7F, so its upgraded copy is longer internally
my $v4_compat = pack 'H*', '000000000000000000000000c0000201';    # ::192.0.2.1
my $v4_mapped = pack 'H*', '00000000000000000000ffffc0000201';
my $v4_packed = pack 'H*', 'c0000201';                            # 192.0.2.1
my $v6_packed = pack 'H*', '20010db8000000000000000000000001';    # 2001:db8::1

# name, function, the right argument and what it returns
my @functions = (
    [ 'inet_ntoa', \&inet_ntoa, $v4_packed, $V4_TEXT ],
    [ 'ipv6_n2d',  \&ipv6_n2d,  $v6_packed, $V6_TEXT_D ],
    [ 'ipv6_n2x',  \&ipv6_n2x,  $v6_packed, $V6_TEXT_X ],
    [ 'ipv6_ntoa', \&ipv6_ntoa, $v6_packed, $V6_TEXT ],
    [ 'isAnyIPv4', \&isAnyIPv4, $v4_mapped, 1 ],
    [ 'isIPv4',    \&isIPv4,    $v4_compat, 1 ],
    [ 'isNewIPv4', \&isNewIPv4, $v4_mapped, 1 ],
);

# the message, then this file and the line of the call, with or without the
# full stop that Carp 1.20 on perl 5.14 leaves off
sub said_at {
    my ( $says, $line ) = @_;
    return qr/\A\Q$says\E at \Q$THIS_FILE\E line $line\b/;
}

subtest 'a wide string as many characters long as the bytes expected croaks' =>
  sub {
    for my $function (@functions) {
        my ( $name, $code, $right ) = @{$function};
        my $chars = length $right;
        my $wide  = $WIDE x $chars;
        my ( $line, $err ) = ( __LINE__, dies { $code->($wide) } );
        like(
            $err,
            said_at( sprintf( $WIDE_DIES, $name ), $line ),
            "$name of $chars wide characters croaks naming $name"
        );
    }
  };

subtest 'a wide string of the wrong length croaks as wide, not as a length' =>
  sub {
    for my $function (@functions) {
        my ( $name, $code ) = @{$function};
        my ( $line, $err )  = ( __LINE__, dies { $code->( $WIDE x 3 ) } );
        like(
            $err,
            said_at( sprintf( $WIDE_DIES, $name ), $line ),
            "$name of 3 wide characters croaks naming $name"
        );
    }
  };

subtest 'a wide string in a nested call names the function that measures it' =>
  sub {
    my ( $line, $err ) = ( __LINE__, dies { inet_n2dx( $WIDE x 16 ) } );
    like(
        $err,
        said_at( sprintf( $WIDE_DIES, 'isAnyIPv4' ), $line ),
        'inet_n2dx of 16 wide characters croaks naming isAnyIPv4'
    );

    ( $line, $err ) = ( __LINE__, dies { inet_n2ad( $WIDE x 16 ) } );
    like(
        $err,
        said_at( sprintf( $WIDE_DIES, 'ipv6_n2d' ), $line ),
        'inet_n2ad of 16 wide characters croaks naming ipv6_n2d'
    );
  };

subtest 'an upgraded string is read as the bytes it holds' => sub {
    for my $function (@functions) {
        my ( $name, $code, $right, $returns ) = @{$function};
        my $upgraded = $right;
        utf8::upgrade($upgraded);
        ok(
            utf8::is_utf8($upgraded) && length($upgraded) == length($right),
            "the $name argument is upgraded and keeps its length"
        ) or bail_out('utf8::upgrade left the argument as bytes');
        my $got = eval { $code->($upgraded) } // "died: $@";
        is( $got, $returns,
            "$name of an upgraded argument returns what the bytes give" );
        ok( utf8::is_utf8($upgraded),
            "$name leaves the caller's upgraded argument upgraded" );
    }
};

subtest 'a string that was never upgraded still converts' => sub {
    for my $function (@functions) {
        my ( $name, $code, $right, $returns ) = @{$function};
        ok( !utf8::is_utf8($right), "the $name argument is bytes" );
        my $got = eval { $code->($right) } // "died: $@";
        is( $got, $returns, "$name of the plain bytes" );
    }
};

done_testing;
