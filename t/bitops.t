# This code exercises some common functions that are used in parts
# of v6 management of IP.pm. It is intended as a reference in case
# of failure

# $Id: bitops.t,v 1.1 2003/10/09 00:14:06 lem Exp $

use Test::More;
use NetAddr::IP;
use Math::BigInt;

my @bases = ();			# Base set of trivial numbers
my @convs = ();			# Numbers after conversion / de-conversion
my @minus = ();			# Bases minus one
my @plus = ();			# Bases plus one

for my $i (0 .. 127)
{
    my $I = new Math::BigInt 1;
    $I <<= $i;
    push @bases, $I;
    $I = new Math::BigInt 3;
    $I <<= $i;
    push @bases, $I;
}

pop @bases;

plan tests => scalar @bases;

				# Test conversion back and forth
				# to/from a suitable vec()

for my $i (0 .. $#bases)	# Build the actual conversion
{
    my $v = '';
    my $I = $bases[$i]->copy;

    for my $j (reverse 0 .. 15)
    {
	vec($v, $j, 8) = ($I & 0xFF);
	$I >>= 8;
    }

#    print "# ";
#    printf "%02x", $_ for map { ord $_ } split //, $v;
#    print "\n";

    push @convs, $v;
}

for my $i (0 .. $#bases)	# Test reversibility
{
    my $I = new Math::BigInt 0;
    for my $o (0 .. 15)
    {
	$I <<= 8;
	$I |= vec($convs[$i], $o, 8);
#	print "I = $I ($o)\n";
    }

    is($bases[$i], $I, "$bases[$i] == $I [$i]");
}


