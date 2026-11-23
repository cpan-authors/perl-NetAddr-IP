#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw( dies );

use NetAddr::IP::Util qw( inet_4map6 inet_aton ipv6_aton ipv6_n2d );

my @stuff = qw(
    192.0.2.1
    192.0.2.4
    ::3.4.5.6
    ::FFFF:4.5.6.7
    ::1:5.4.3.2
    ::FEFF:4.3.2.1
);

my $p4 = '0:0:0:0:0:FFFF:';
my $p6 = '0:0:0:0:0:';

for my $idx (0 .. $#stuff) {
    my $pass = 1;
    my $result;
    my $bstr;
    $pass = 0 if $idx > 3;
    if ($stuff[$idx] =~ m/:/) {
        $bstr = ipv6_aton($stuff[$idx]);
        my $prefix = ($stuff[$idx] =~ m/^::F/) ? $p6 : $p4;
        ($result = $stuff[$idx]) =~ s/::/$prefix/;
    }
    else {
        $bstr   = inet_aton($stuff[$idx]);
        $result = $p4 . $stuff[$idx];
    }
    my $rv = inet_4map6($bstr);
    if ($pass && !$rv) {
        fail('failed to return valid address');
    }
    elsif ($pass) {
        $rv = ipv6_n2d($rv);
        is($rv, $result, "mapped address for $stuff[$idx]");
    }
    else {
        ok(!$rv, "no valid mapping for $stuff[$idx]");
    }
}

{

    package Local::Text;    # an object whose text is fixed, counting how often it is read

    use overload q{""} => sub { $_[0]{calls}++; $_[0]{text} }, fallback => 1;

    sub new {
        my ($class, $text) = @_;
        return bless { calls => 0, text => $text }, $class;
    }
}

# an object reblessed into class '0', whose name ref() reports as false, reads the same way
overload::OVERLOAD('0', q{""} => overload::Method('Local::Text', q{""}), fallback => 1);

subtest 'an object is read once, and maps as its text does' => sub {
    for my $text (inet_aton('192.0.2.1'), ipv6_aton('::ffff:192.0.2.1')) {
        my $bytes = length $text;
        for my $class (qw( 0 Local::Text )) {
            my $object = bless Local::Text->new($text), $class;
            is( inet_4map6($object), inet_4map6($text),
                "inet_4map6 of an object of class $class holding $bytes bytes returns what its text gives"
            );
            is($object->{calls}, 1, "inet_4map6 reads an object of class $class holding $bytes bytes once");
        }
    }
    like(
        dies { inet_4map6(Local::Text->new("\x{100}" x 16)) },
        qr/\AWide character in NetAddr::IP::InetBase::isAnyIPv4 at /,
        'inet_4map6 of an object holding 16 wide characters croaks as the string does'
    );
};

done_testing;
