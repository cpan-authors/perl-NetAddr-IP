#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );
use Tie::Hash;

use NetAddr::IP::Util qw(
  add128
  addconst
  bcd2bin
  bcdn2bin
  bcdn2txt
  bin2bcd
  bin2bcdn
  comp128
  hasbits
  ipanyto6
  ipv4to6
  ipv6_aton
  ipv6_n2x
  ipv6to4
  isIPv4
  mask4to6
  maskanyto6
  notcontiguous
  shiftleft
  simple_pack
  sub128
);

## simple_pack – bad character input

for my $input (
    '1234/',
    '1234:',
    'a1234',
    '&1234',
    "\x{0663}\x{0663}\x{0663}\x{0663}",    # Arabic-Indic digits
    "\x{0969}\x{0969}\x{0969}\x{0969}",    # Devanagari digits
    "\x{FF13}\x{FF13}\x{FF13}\x{FF13}",    # Fullwidth digits
  )
{
    like( dies { simple_pack($input) },
        qr/Bad/, "simple_pack dies on non-ASCII digit input" );
}

## bcd2bin – bad character input

for my $input ( '1234/', '1234:', 'a1234', '&1234', ) {
    like( dies { bcd2bin($input) }, qr/Bad/, "bcd2bin dies on '$input'" );
}

## bcdn2bin – bad vector string length

like( dies { bcdn2bin('123456789012345678901') },
    qr/Bad/, 'bcdn2bin dies on bad length' );

## bcdn2bin – missing length specifier

like( dies { bcdn2bin('12345678901234567890') },
    qr/Bad/, 'bcdn2bin dies on missing length specifier' );

## bin2bcd – bad vector string length

like( dies { bin2bcd('123') }, qr/Bad/, 'bin2bcd dies on bad length' );

## bin2bcdn – bad vector string length

like( dies { bin2bcdn('123') }, qr/Bad/, 'bin2bcdn dies on bad length' );

## bcdn2txt – bad vector string length

like( dies { bcdn2txt('123456789012345678901') },
    qr/Bad/, 'bcdn2txt dies on bad length' );

## bcdn2txt – success case

my $rv  = bcdn2txt('12345678901234567890');
my $exp = '3132333435363738393031323334353637383930';
is( $rv, $exp, 'bcdn2txt returns expected value' );

## hasbits – bad vector string length

like( dies { hasbits('123') }, qr/Bad/, 'hasbits dies on bad length' );

## isIPv4 – bad vector string length

like( dies { isIPv4('12345678901234567') },
    qr/Bad/, 'isIPv4 dies on bad length' );

## add128 – bad vector string length

like( dies { add128( '123', '1234567890123456' ) },
    qr/Bad/, 'add128 dies on bad length' );

## sub128 – bad vector string length

like( dies { sub128( '1234567890123456', '12345678901234567' ) },
    qr/Bad/, 'sub128 dies on bad length' );

## comp128 – bad vector string length

like( dies { comp128('123') }, qr/Bad/, 'comp128 dies on bad length' );

## shiftleft – bad vector string length

like( dies { shiftleft('12345678901234567') },
    qr/Bad/, 'shiftleft dies on bad length' );

## shiftleft – bad shift count (negative)

like( dies { shiftleft( '1234567890123456', -1 ) },
    qr/Bad/, 'shiftleft dies on negative shift count' );

## shiftleft – bad shift count (too large)

like( dies { shiftleft( '1234567890123456', 129 ) },
    qr/Bad/, 'shiftleft dies on shift count too large' );

## bcd2bin – empty string

like( dies { bcd2bin('') }, qr/Bad/, 'bcd2bin dies on empty string' );

## simple_pack – empty string

like( dies { simple_pack('') }, qr/Bad/, 'simple_pack dies on empty string' );

## bcdn2txt – empty string

like( dies { bcdn2txt('') }, qr/Bad/, 'bcdn2txt dies on empty string' );

## bcdn2bin – empty string

like( dies { bcdn2bin( '', 40 ) }, qr/Bad/, 'bcdn2bin dies on empty string' );

## bcdn2bin – digit count larger than packed string

like( dies { bcdn2bin( "\x12", 40 ) },
    qr/Bad/, 'bcdn2bin dies on digit count larger than input' );

## bcdn2bin - over-long packed input reports its length in digits, like every other length croak

like(
    dies { bcdn2bin( "\x12" x 21, 40 ) },
    qr/Bad.*length.*42.*should be 1 to 40 digits/,
    'bcdn2bin reports 21 packed bytes as 42 digits'
);
like(
    dies { bcdn2bin( "\x12" x 41, 40 ) },
    qr/Bad.*length.*82.*should be 1 to 40 digits/,
    'bcdn2bin reports 41 packed bytes as 82 digits'
);

## bcd2bin – values that do not fit in 128 bits must die

like(
    dies { bcd2bin('340282366920938463463374607431768211456') },
    qr/larger than 128 bits/,
    'bcd2bin dies on 2**128'
);
like(
    dies { bcd2bin( '9' x 40 ) },
    qr/larger than 128 bits/,
    'bcd2bin dies on 40 nines'
);

## bcdn2bin – values that do not fit in 128 bits must die

like(
    dies {
        bcdn2bin( simple_pack('340282366920938463463374607431768211456'), 40 )
    },
    qr/larger than 128 bits/,
    'bcdn2bin dies on 2**128'
);

## simple_pack and bcd2bin - a NUL or a high-bit byte is not a digit

for my $input ( "1\x002", "5\x003\x001", "\xb1\xb2", "1\xb2" ) {
    like(
        dies { simple_pack($input) },
        qr/Bad char in string/,
        'simple_pack dies on a NUL or high-bit byte'
    );
    like(
        dies { bcd2bin($input) },
        qr/Bad char in string/,
        'bcd2bin dies on a NUL or high-bit byte'
    );
}

## shiftleft, addconst, bcdn2bin - a count or constant out of range dies on both builds

my $v = ipv6_aton('::1');

for my $count ( 4294967297, 2**40 + 3, -4294967295, 1.5, 'abc' ) {
    like(
        dies { shiftleft( $v, $count ) },
qr/^Bad arg value for NetAddr::IP::Util::shiftleft, is \Q$count\E, should be 0 thru 128/,
        "shiftleft dies on count $count"
    );
}
is( ipv6_n2x( shiftleft( $v, undef ) ),
    '0:0:0:0:0:0:0:1', 'shiftleft with an undef count returns the input' );
is( ipv6_n2x( shiftleft( $v, 128 ) ),
    '0:0:0:0:0:0:0:0', 'shiftleft accepts 128' );

for my $const ( 2**31, -( 2**31 ) - 1, 2**32, 18446744073709551615, 1.5, 'abc' )
{
    like(
        dies { addconst( $v, $const ) },
qr/^Bad arg value for NetAddr::IP::Util::addconst, is \Q$const\E, should be an integer from -2147483648 thru 2147483647/,
        "addconst dies on constant $const"
    );
}
is( ipv6_n2x( ( addconst( $v, 2147483647 ) )[1] ),
    '0:0:0:0:0:0:8000:0', 'addconst accepts 2**31 - 1' );
is(
    ipv6_n2x( ( addconst( $v, -2147483648 ) )[1] ),
    'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:8000:1',
    'addconst accepts -2**31'
);
is( ipv6_n2x( ( addconst( $v, undef ) )[1] ),
    '0:0:0:0:0:0:0:1', 'addconst with an undef constant returns the input' );
SKIP: {
    skip 'Math::BigInt not found', 1 unless eval { require Math::BigInt; 1 };
    is( ipv6_n2x( ( addconst( $v, Math::BigInt->new(5) ) )[1] ),
        '0:0:0:0:0:0:0:6', 'addconst numifies a Math::BigInt constant' );
}

# $1 and a tied scalar are read through their get magic
'5x' =~ /([0-9])/;
is( ipv6_n2x( shiftleft( $v, $1 ) ),
    '0:0:0:0:0:0:0:20', 'shiftleft reads a count held in $1' );
'5x' =~ /([0-9])/;
is( ipv6_n2x( ( addconst( $v, $1 ) )[1] ),
    '0:0:0:0:0:0:0:6', 'addconst reads a constant held in $1' );
{

    package Local::Five;
    sub TIESCALAR { return bless {}, shift }
    sub FETCH     { return 5 }
}
tie my $five, 'Local::Five';
is( ipv6_n2x( shiftleft( $v, $five ) ),
    '0:0:0:0:0:0:0:20', 'shiftleft reads a tied count' );
is( ipv6_n2x( ( addconst( $v, $five ) )[1] ),
    '0:0:0:0:0:0:0:6', 'addconst reads a tied constant' );
is(
    ipv6_n2x( ( addconst( $v, ' 7' ) )[1] ),
    '0:0:0:0:0:0:0:8',
'addconst accepts a number with leading space, as NetAddr::IP::Lite::plus passes it'
);
for my $nan ( 'nan', 'inf', '-inf' ) {
    like(
        dies { shiftleft( $v, $nan ) },
        qr/^Bad arg value for NetAddr::IP::Util::shiftleft, is \Q$nan\E,/,
        "shiftleft dies on $nan"
    );
    like(
        dies { addconst( $v, $nan ) },
        qr/^Bad arg value for NetAddr::IP::Util::addconst, is \Q$nan\E,/,
        "addconst dies on $nan"
    );
}

# the digit count is a number on both builds, in any form looks_like_number accepts
my $packed_bcd = pack( 'H*', '12345678' );
is(
    bcdn2bin( $packed_bcd, ' 7' ),
    bcdn2bin( $packed_bcd, 7 ),
    'bcdn2bin reads a digit count with leading space'
);
is(
    bcdn2bin( $packed_bcd, '5e0' ),
    bcdn2bin( $packed_bcd, 5 ),
    'bcdn2bin reads a digit count in exponent form'
);
like(
    dies { bcdn2bin( $packed_bcd, 'nan' ) },
qr/^Bad digit count for NetAddr::IP::Util::bcdn2bin, is nan, should be 1 to 8 digits/,
    'bcdn2bin dies on a digit count of nan'
);

like(
    dies { bcdn2bin( simple_pack('123456789'), 4294967299 ) },
qr/^Bad digit count for NetAddr::IP::Util::bcdn2bin, is 4294967299, should be 1 to 40 digits/,
    'bcdn2bin dies on a digit count that a C int would wrap'
);

## objects as counts and constants - numified through their overloading

{

    package Local::Numify;
    use overload q{0+} => sub { return ${ $_[0] } };
}
{

    package Local::Text;
    use overload q{""} => sub { return ${ $_[0] } }, fallback => 1;
}
my $numify_five = bless \do { my $n = 5 },     'Local::Numify';
my $text_abc    = bless \do { my $s = 'abc' }, 'Local::Text';
is( ipv6_n2x( shiftleft( $v, $numify_five ) ),
    '0:0:0:0:0:0:0:20', 'shiftleft reads an object that overloads 0+' );
like(
    dies { shiftleft( $v, $text_abc ) },
    qr/^Bad arg value for NetAddr::IP::Util::shiftleft, is abc,/,
    'shiftleft dies on an object that numifies to text'
);
like(
    dies { addconst( $v, $text_abc ) },
    qr/^Bad arg value for NetAddr::IP::Util::addconst, is abc,/,
    'addconst dies on an object that numifies to text'
);

## the count is read before the address it may modify

our $moving = ipv6_aton('2001:db8::1');
{

    package Local::Moves;
    use overload
      q{0+} => sub {
        $main::moving = 'x' x 4096;
        $main::moving = main::ipv6_aton('2001:db8::1');
        return 1;
      },
      fallback => 1;
}
is( ipv6_n2x( shiftleft( $moving, bless {}, 'Local::Moves' ) ),
    '4002:1B70:0:0:0:0:0:2',
    'shiftleft reads the address after the count reallocates it' );

our %holder = ( address => ipv6_aton('2001:db8::1') );
{

    package Local::Deletes;
    use overload
      q{0+}    => sub { delete $main::holder{address}; return 1 },
      fallback => 1;
}
is(
    ipv6_n2x( shiftleft( $holder{address}, bless {}, 'Local::Deletes' ) ),
    '4002:1B70:0:0:0:0:0:2',
    'shiftleft keeps the address alive while the count deletes it'
);

## fractional digit counts and argument order

like(
    dies { bcdn2bin( pack( 'H*', '12345678' ), 1.5 ) },
qr/^Bad digit count for NetAddr::IP::Util::bcdn2bin, is 1.5, should be 1 to 8 digits/,
    'bcdn2bin dies on a fractional digit count'
);
like(
    dies { addconst( 'short', 'abc' ) },
qr/^Bad arg length for NetAddr::IP::Util::addconst, length is 40, should be 128/,
    'addconst reports a bad address before a bad constant'
);

## packed strings upgraded to UTF-8 are the same bytes to every binary function

my $packed   = ipv6_aton('2001:db8::ffff:c000:201');
my $upgraded = $packed;
utf8::upgrade($upgraded);
my $four    = pack( 'C4', 192, 0, 2, 1 );
my $four_up = $four;
utf8::upgrade($four_up);

is( hasbits($upgraded), hasbits($packed),
    'hasbits reads an upgraded packed address' );
is( comp128($upgraded), comp128($packed),
    'comp128 reads an upgraded packed address' );
is( ipv6to4($upgraded), ipv6to4($packed),
    'ipv6to4 reads an upgraded packed address' );
is( bin2bcd($upgraded), bin2bcd($packed),
    'bin2bcd reads an upgraded packed address' );
is(
    ( add128( $upgraded, $packed ) )[1],
    ( add128( $packed,   $packed ) )[1],
    'add128 reads an upgraded packed address'
);
is( ipv4to6($four_up), ipv4to6($four),
    'ipv4to6 reads an upgraded packed IPv4 address' );

## packed arguments held in $1, substr or a tied value are read through their get magic

my $mask        = ipv6_aton('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00');
my %packed_call = (
    add128        => [ sub { [ add128( $_[0], $_[1] ) ] }, $packed, $packed ],
    addconst      => [ sub { [ addconst( $_[0], 1 ) ] },   $packed ],
    bcd2bin       => [ sub { [ bcd2bin( $_[0] ) ] },       '12345' ],
    bcdn2bin      => [ sub { [ bcdn2bin( $_[0], 5 ) ] },   $packed_bcd ],
    bcdn2txt      => [ sub { [ bcdn2txt( $_[0] ) ] },      bin2bcdn($packed) ],
    bin2bcd       => [ sub { [ bin2bcd( $_[0] ) ] },       $packed ],
    bin2bcdn      => [ sub { [ bin2bcdn( $_[0] ) ] },      $packed ],
    comp128       => [ sub { [ comp128( $_[0] ) ] },       $packed ],
    hasbits       => [ sub { [ hasbits( $_[0] ) ] },       $packed ],
    ipanyto6      => [ sub { [ ipanyto6( $_[0] ) ] },      $four ],
    ipv4to6       => [ sub { [ ipv4to6( $_[0] ) ] },       $four ],
    ipv6to4       => [ sub { [ ipv6to4( $_[0] ) ] },       $packed ],
    mask4to6      => [ sub { [ mask4to6( $_[0] ) ] },      $four ],
    maskanyto6    => [ sub { [ maskanyto6( $_[0] ) ] },    $four ],
    notcontiguous => [ sub { [ notcontiguous( $_[0] ) ] }, $mask ],
    shiftleft     => [ sub { [ shiftleft( $_[0], 1 ) ] },  $packed ],
    simple_pack   => [ sub { [ simple_pack( $_[0] ) ] },   '12345' ],
    sub128        => [ sub { [ sub128( $_[0], $_[1] ) ] }, $packed, $packed ],
);

# each form passes up to two magic values; a call that takes one ignores the second
my %magic_form = (
    'regex capture' => sub {
        my ( $code, @args ) = @_;
        my $text    = join q{}, map { "<$_>" } @args;
        my $pattern = join q{}, map { '<(.{' . length($_) . '})>' } @args;
        $text =~ /\A$pattern\z/s or die "no match\n";
        return $code->( $1, $2 );
    },
    'substr' => sub {
        my ( $code, @args ) = @_;
        my ( $first, $second ) = map { "<$_>" } @args, q{};
        return $code->(
            substr( $first,  1, length $args[0] ),
            substr( $second, 1, length( $args[1] // q{} ) )
        );
    },
    'substr of an upgraded string' => sub {
        my ( $code, @args ) = @_;
        my ( $first, $second ) = map { "<$_>" } @args, q{};
        utf8::upgrade($first);
        utf8::upgrade($second);
        return $code->(
            substr( $first,  1, length $args[0] ),
            substr( $second, 1, length( $args[1] // q{} ) )
        );
    },
    'tied hash element' => sub {
        my ( $code, @args ) = @_;
        tie my %hash, 'Tie::StdHash';
        @hash{ 0 .. $#args } = @args;
        return $code->( $hash{0}, $hash{1} );
    },
);

for my $name ( sort keys %packed_call ) {
    my ( $code, @args ) = @{ $packed_call{$name} };
    my $plain = $code->(@args);
    for my $form ( sort keys %magic_form ) {
        is( $magic_form{$form}->( $code, @args ),
            $plain, "$name reads a packed argument from a $form" );
    }
}

{

    package Local::CountsFetch;

    sub TIESCALAR {
        my ( $class, $value ) = @_;
        return bless { fetches => 0, value => $value }, $class;
    }
    sub FETCH { my ($self) = @_; $self->{fetches}++; return $self->{value} }
    sub STORE { return }
}

for my $name ( sort keys %packed_call ) {
    my ( $code, @args ) = @{ $packed_call{$name} };
    tie my $first,  'Local::CountsFetch', $args[0];
    tie my $second, 'Local::CountsFetch', $args[1];
    is( $code->( $first, $second ),
        $code->(@args), "$name reads a tied packed argument" );
    my @fetches = map { tied($_)->{fetches} } $first,
      ( @args > 1 ? $second : () );

    is(
        \@fetches,
        [ (1) x @args ],
        "$name fetches each tied packed argument once"
    );
}

tie my $tied_undef, 'Local::CountsFetch', undef;
like(
    dies { hasbits($tied_undef) },
qr/^Bad arg length for NetAddr::IP::Util::hasbits, length is undefined, should be 128/,
    'hasbits reports a tied undef as undefined'
);
like(
    dies { add128( $packed, $tied_undef ) },
qr/^Bad arg length for NetAddr::IP::Util::add128, length is undefined, should be 128/,
    'add128 reports a tied undef second argument as undefined'
);

done_testing;
