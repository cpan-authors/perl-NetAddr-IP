#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( bcdn2txt bin2bcd bin2bcdn ipv6_aton );

sub val {
    my $bcd = shift;
    my $rv  = unpack( 'H*', $bcd );
    $rv =~ s/^0+([0-9])/$1/g;
    return $rv;
}

my %num2 = (
    '::'                 => '0',
    '::8000:0'           => '2147483648',
    '::8000:0:0'         => '140737488355328',
    '::8000:0:0:0'       => '9223372036854775808',
    '::8000:0:0:0:0'     => '604462909807314587353088',
    '::8000:0:0:0:0:0'   => '39614081257132168796771975168',
    '::8000:0:0:0:0:0:0' => '2596148429267413814265248164610048',
    '8000:0:0:0:0:0:0:0' => '170141183460469231731687303715884105728',
);

subtest 'bin2bcdn string unpack via val' => sub {
    for my $input ( sort { $a cmp $b } keys %num2 ) {
        my $bstr = ipv6_aton($input);
        my $bcd  = bin2bcdn($bstr);
        my $got  = val($bcd);
        is( $got, $num2{$input}, "bin2bcdn($input) via val" );
    }
};

subtest 'bin2bcdn reads one argument alike in both builds' => sub {
    is( prototype('NetAddr::IP::Util::bin2bcdn'),
        '$', 'bin2bcdn has the prototype $' );

    my $arg = NetAddr::IP::Util::ipv6_aton('2001:db8::1');

    # compiled here, so the prototype decides how the line parses
    is( eval q{ bin2bcdn $arg ? 'yes' : 'no' },
        'yes', 'a call without brackets binds before ?:' );
    is( $@, '', 'that call does not croak' );

    # in list context this returns a name and the argument, as a lookup does
    my $answer = sub { return wantarray ? ( 'host.example', $arg ) : $arg };
    is( eval { bin2bcdn( $answer->() ) },
        bin2bcdn($arg),
        'an argument that returns a list is read in scalar context' );
    is( $@, '', 'that call does not croak' );
};

subtest 'bin2bcdn string unpack via bcdn2txt' => sub {
    for my $input ( sort { $a cmp $b } keys %num2 ) {
        my $bstr = ipv6_aton($input);
        my $bcd  = bin2bcdn($bstr);
        my $got  = bcdn2txt($bcd);
        is( $got, $num2{$input}, "bin2bcdn($input) via bcdn2txt" );
    }
};

subtest 'bcdn2txt reads one argument alike in both builds' => sub {
    is( prototype('NetAddr::IP::Util::bcdn2txt'),
        '$', 'bcdn2txt has the prototype $' );

    my $arg = NetAddr::IP::Util::bin2bcdn(
        NetAddr::IP::Util::ipv6_aton('2001:db8::1') );

    # compiled here, so the prototype decides how the line parses
    is( eval q{ bcdn2txt $arg ? 'yes' : 'no' },
        'yes', 'a call without brackets binds before ?:' );
    is( $@, '', 'that call does not croak' );

    # in list context this returns a name and the argument, as a lookup does
    my $answer = sub { return wantarray ? ( 'host.example', $arg ) : $arg };
    is( eval { bcdn2txt( $answer->() ) },
        bcdn2txt($arg),
        'an argument that returns a list is read in scalar context' );
    is( $@, '', 'that call does not croak' );
};

subtest 'bin2bcd' => sub {
    for my $input ( sort { $a cmp $b } keys %num2 ) {
        my $bstr = ipv6_aton($input);
        my $bcd  = bin2bcd($bstr);
        is( $bcd, $num2{$input}, "bin2bcd($input)" );
    }
};

subtest 'bin2bcd reads one argument alike in both builds' => sub {
    is( prototype('NetAddr::IP::Util::bin2bcd'),
        '$', 'bin2bcd has the prototype $' );

    my $arg = NetAddr::IP::Util::ipv6_aton('2001:db8::1');

    # compiled here, so the prototype decides how the line parses
    is( eval q{ bin2bcd $arg ? 'yes' : 'no' },
        'yes', 'a call without brackets binds before ?:' );
    is( $@, '', 'that call does not croak' );

    # in list context this returns a name and the argument, as a lookup does
    my $answer = sub { return wantarray ? ( 'host.example', $arg ) : $arg };
    is( eval { bin2bcd( $answer->() ) },
        bin2bcd($arg),
        'an argument that returns a list is read in scalar context' );
    is( $@, '', 'that call does not croak' );
};

done_testing;
