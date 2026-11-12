#!perl -T

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Scalar::Util qw( tainted );

use NetAddr::IP::Util   ();
use NetAddr::IP::UtilPP ();

# an empty string that carries the taint of the environment
my $TAINT = substr(join('', %ENV), 0, 0);

my $V4   = pack('C4',  192, 0, 2, 1);                          # 192.0.2.1
my $V6   = pack('H32', '20010db8000000000000000000000001');    # 2001:db8::1
my $BCDN = pack('H40', '0' x 38 . '42');

# label, function, arguments, index of the string result in list context, that result in hex
my @CASES = (
    [ 'add128 of two addresses',     'add128',   [ $V6, $V6 ],      1, '40021b70000000000000000000000002' ],
    [ 'addconst of 1',               'addconst', [ $V6, 1 ],        1, '20010db8000000000000000000000002' ],
    [ 'addconst of 0',               'addconst', [ $V6, 0 ],        1, '20010db8000000000000000000000001' ],
    [ 'addconst of the empty count', 'addconst', [ $V6, '' ],       1, '20010db8000000000000000000000001' ],
    [ 'bcd2bin of 42',               'bcd2bin',  ['42'],            0, '0000000000000000000000000000002a' ],
    [ 'bcdn2bin of 1234',            'bcdn2bin', [ "\x12\x34", 4 ], 0, '000000000000000000000000000004d2' ],
    [ 'bcdn2txt of 42',              'bcdn2txt', [$BCDN],           0, '3432' ],
    [   'bin2bcd of an address', 'bin2bcd', [$V6], 0,
        '3432353430373636343131323832353932383536393033393834393531363533383236353631'
    ],
    [ 'bin2bcdn of an address',       'bin2bcdn',    [$V6],        0, '0042540766411282592856903984951653826561' ],
    [ 'comp128 of an address',        'comp128',     [$V6],        0, 'dffef247fffffffffffffffffffffffe' ],
    [ 'ipanyto6 of IPv4',             'ipanyto6',    [$V4],        0, '000000000000000000000000c0000201' ],
    [ 'ipanyto6 of IPv6',             'ipanyto6',    [$V6],        0, '20010db8000000000000000000000001' ],
    [ 'ipv4to6 of IPv4',              'ipv4to6',     [$V4],        0, '000000000000000000000000c0000201' ],
    [ 'ipv6to4 of IPv6',              'ipv6to4',     [$V6],        0, '00000001' ],
    [ 'mask4to6 of IPv4',             'mask4to6',    [$V4],        0, 'ffffffffffffffffffffffffc0000201' ],
    [ 'maskanyto6 of IPv4',           'maskanyto6',  [$V4],        0, 'ffffffffffffffffffffffffc0000201' ],
    [ 'maskanyto6 of IPv6',           'maskanyto6',  [$V6],        0, '20010db8000000000000000000000001' ],
    [ 'shiftleft by 1',               'shiftleft',   [ $V6, 1 ],   0, '40021b70000000000000000000000002' ],
    [ 'shiftleft by 0',               'shiftleft',   [ $V6, 0 ],   0, '20010db8000000000000000000000001' ],
    [ 'shiftleft by the empty count', 'shiftleft',   [ $V6, '' ],  0, '20010db8000000000000000000000001' ],
    [ 'simple_pack of 42',            'simple_pack', ['42'],       0, '0000000000000000000000000000000000000042' ],
    [ 'sub128 of two addresses',      'sub128',      [ $V6, $V6 ], 1, '00000000000000000000000000000000' ],
);

sub string_result {
    my ($function, $args, $index) = @_;
    my @result = $function->(@{$args});
    return $result[$index];
}

bail_out('this test runs under perl -T') unless ${^TAINT};
bail_out('no tainted value to test with, the environment is empty')
    unless tainted($TAINT);

# before any tainted call: the pure Perl ipv4to6, mask4to6, ipanyto6 and maskanyto6 can
# keep the taint of an earlier call in a later result
for my $package (qw( NetAddr::IP::Util NetAddr::IP::UtilPP )) {
    subtest "$package string results of untainted arguments are untainted and as expected" => sub {
        for my $case (@CASES) {
            my ($label, $name, $args, $index, $hex) = @{$case};
            my $result = string_result($package->can($name), $args, $index);
            ok(!tainted($result), "$name: $label, untainted arguments, is not tainted");
            is(unpack('H*', $result), $hex, "$name: $label, untainted arguments, has the expected value");
        }
    };
}

# the XS build runs its own code through NetAddr::IP::Util and the pure Perl code
# through NetAddr::IP::UtilPP; the pure Perl build runs the pure Perl code through both
for my $package (qw( NetAddr::IP::Util NetAddr::IP::UtilPP )) {
    subtest "$package string results carry the taint of every argument" => sub {
        for my $case (@CASES) {
            my ($label, $name, $args, $index) = @{$case};
            my $function = $package->can($name);
            my $plain    = string_result($function, $args, $index);
            for my $position (0 .. $#{$args}) {
                my @tainted = @{$args};
                $tainted[$position] .= $TAINT;
                my $result = string_result($function, \@tainted, $index);
                ok( tainted($result),
                    "$name: $label, argument $position tainted, is tainted"
                );
                is( $result, $plain,
                    "$name: $label, argument $position tainted, has the same value"
                );
            }
        }
    };
}

done_testing;
