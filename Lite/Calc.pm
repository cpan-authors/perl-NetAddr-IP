package NetAddr::IP::Calc;

use diagnostics;
use strict;
use vars qw($VERSION);

$VERSION = '1.997';

# Package to store unsigned big integers in decimal and do math with them

# Internally the numbers are stored in an array with at least 1 element, no
# leading zero parts (except the first) and in base 1eX where X is determined
# automatically at loading time to be the maximum possible value

# todo:
# - fully remove funky $# stuff in div() (maybe - that code scares me...)

# USE_MUL: due to problems on certain os (os390, posix-bc) "* 1e-5" is used
# instead of "/ 1e5" at some places, (marked with USE_MUL). Other platforms
# BS2000, some Crays need USE_DIV instead.
# The BEGIN block is used to determine which of the two variants gives the
# correct result.

# Beware of things like:
# $i = $i * $y + $car; $car = int($i / $BASE); $i = $i % $BASE;
# This works on x86, but fails on ARM (SA1100, iPAQ) due to whoknows what
# reasons. So, use this instead (slower, but correct):
# $i = $i * $y + $car; $car = int($i / $BASE); $i -= $BASE * $car;

##############################################################################
# global constants, flags and accessory

# announce that we are compatible with MBI v1.83 and up
sub api_version () { 2; }
 
# constants for easier life
my ($BASE,$BASE_LEN,$RBASE);

sub _base_len 
  {
  # Set/get the BASE_LEN and assorted other, connected values.
  # Used only by the testsuite, the set variant is used only by the BEGIN
  # block below:
  shift;

  my ($b, $int) = @_;
  if (defined $b)
    {
    if ($] >= 5.008 && $int && $b > 7)
      {
      $BASE_LEN = $b;
      $BASE = int("1e".$BASE_LEN);
      return $BASE_LEN;
      }

    # find whether we can use mul or div in mul()/div()
    $BASE_LEN = $b+1;
    my $caught = 0;
    while (--$BASE_LEN > 5)
      {
      $BASE = int("1e".$BASE_LEN);
      $RBASE = abs('1e-'.$BASE_LEN);			# see USE_MUL
      $caught = 0;
      $caught += 1 if (int($BASE * $RBASE) != 1);	# should be 1
      $caught += 2 if (int($BASE / $BASE) != 1);	# should be 1
      last if $caught != 3;
      }
    }
  return $BASE_LEN;
  }

sub _new
  {
  # (ref to string) return ref to num_array
  # Convert a number from string format (without sign) to internal base
  # 1ex format. Assumes normalized value as input.
  my $il = length($_[1])-1;

  # < BASE_LEN due len-1 above
  return [ int($_[1]) ] if $il < $BASE_LEN;	# shortcut for short numbers

  # this leaves '00000' instead of int 0 and will be corrected after any op
  [ reverse(unpack("a" . ($il % $BASE_LEN+1) 
    . ("a$BASE_LEN" x ($il / $BASE_LEN)), $_[1])) ];
  }                                                                             

BEGIN
  {
  # from Daniel Pfeiffer: determine largest group of digits that is precisely
  # multipliable with itself plus carry
  # Test now changed to expect the proper pattern, not a result off by 1 or 2
  my ($e, $num) = 3;	# lowest value we will use is 3+1-1 = 3
  do 
    {
    $num = ('9' x ++$e) + 0;
    $num *= $num + 1.0;
    } while ("$num" =~ /9{$e}0{$e}/);	# must be a certain pattern
  $e--; 				# last test failed, so retract one step
  # the limits below brush the problems with the test above under the rug:
  # the test should be able to find the proper $e automatically
  $e = 5 if $^O =~ /^uts/;	# UTS get's some special treatment
  $e = 5 if $^O =~ /^unicos/;	# unicos is also problematic (6 seems to work
				# there, but we play safe)

  my $int = 0;
  if ($e > 7)
    {
    use integer;
    my $e1 = 7;
    $num = 7;
    do 
      {
      $num = ('9' x ++$e1) + 0;
      $num *= $num + 1;
      } while ("$num" =~ /9{$e1}0{$e1}/);	# must be a certain pattern
    $e1--; 					# last test failed, so retract one step
    if ($e1 > 7)
      { 
      $int = 1; $e = $e1; 
      }
    }
 
  __PACKAGE__->_base_len($e,$int);	# set and store
  }

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself. 

=head1 AUTHORS

=over 4

=item *

Original math code by Mark Biggar, rewritten by Tels L<http://bloodgate.com/>
in late 2000.

=item *

Separated from BigInt and shaped API with the help of John Peacock.

=item *

Fixed, speed-up, streamlined and enhanced by Tels 2001 - 2007.

=item *

API documentation corrected and extended by Peter John Acklam,
E<lt>pjacklam@online.noE<gt>

=item *

Shortened to base length check only for use with NetAddr::IP by
Michael Robinton e<lt>michael@bizsystems.comE<gt>

=back

=cut

1;
