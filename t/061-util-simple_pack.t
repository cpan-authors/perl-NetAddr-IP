#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Util qw( simple_pack );

my @num2 = qw(
  0
  2147483648
  140737488355328
  9223372036854775808
  604462909807314587353088
  39614081257132168796771975168
  2596148429267413814265248164610048
  170141183460469231731687303715884105728
);

for my $num (@num2) {
    my $pkd = simple_pack($num);
    my $rv  = unpack( 'H40', $pkd );
    $rv =~ s/^0+([0-9])/$1/g;
    is( $rv, $num, "simple_pack($num)" );
}

subtest 'simple_pack reads its first argument alike in both builds' => sub {
    is( prototype('NetAddr::IP::Util::simple_pack'),
        '$;@', 'simple_pack has the prototype $;@' );

    my $arg = '12345';

    # in list context this returns a name and the argument, as a lookup does
    my $answer = sub { return wantarray ? ( 'host.example', $arg ) : $arg };
    is( eval { simple_pack( $answer->() ) },
        simple_pack($arg),
        'a first argument that returns a list is read in scalar context' );
    is( $@, '', 'that call does not croak' );
};

done_testing;
