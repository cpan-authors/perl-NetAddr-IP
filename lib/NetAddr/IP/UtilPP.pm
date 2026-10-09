#!/bin/false
# ABSTRACT: Pure perl implementations of IPv4 and IPv6 address utilities
# PODNAME: NetAddr::IP::UtilPP

use strict;
use warnings;

package NetAddr::IP::UtilPP;
# VERSION

use parent 'Exporter';
use Carp qw( croak );
use Scalar::Util qw( looks_like_number );
use NetAddr::IP::Constants qw(
    $IPV4_BITS
    $IPV6_BITS
    $MAX_BCD_DIGITS
    $MAX_SHIFTLEFT
    $OCTET_BITS
    $PACKED_BCD_BYTES
    $V4_PACKED_BYTES
    $V6_PACKED_BYTES
);

our @EXPORT_OK = qw(
    hasbits
    shiftleft
    addconst
    add128
    sub128
    notcontiguous
    ipv4to6
    mask4to6
    ipanyto6
    maskanyto6
    ipv6to4
    bin2bcd
    bcd2bin
    comp128
    bin2bcdn
    bcdn2txt
    bcdn2bin
    simple_pack
);
our %EXPORT_TAGS = (
    all    => [@EXPORT_OK],
);

sub DESTROY {};

sub _callersub {
    (my $sub = (caller(2))[3]) =~ s/UtilPP::/Util::/;    # callers use NetAddr::IP::Util
    return $sub;
}

1;

=head1 SYNOPSIS

  use NetAddr::IP::UtilPP qw(
    hasbits shiftleft addconst add128 sub128 notcontiguous
    ipv4to6 mask4to6 ipanyto6 maskanyto6 ipv6to4
    bin2bcd bcd2bin
  );
  use NetAddr::IP::InetBase qw(inet_aton ipv6_aton);

  # inputs for the calls below
  $netaddr    = inet_aton('192.0.2.1');
  $bits128    = ipv6_aton('2001:db8::1');
  $bits1281   = ipv6_aton('2001:db8::2');
  $bits1282   = ipv6_aton('2001:db8::1');
  $mask128    = ipv6_aton('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00');
  $signed_32bit = 1;
  $n          = 8;

  # the family test and the shift
  $rv         = hasbits($bits128);        # true if any bit is set
  $bitsXn     = shiftleft($bits128, $n);  # 8 bits left; no $n returns the input

  # arithmetic, carry in scalar context and (carry, result) in list
  $carry      = addconst($bits128, $signed_32bit);
  ($carry, $bits128) = addconst($bits128, $signed_32bit);
  $carry      = add128($bits1281, $bits1282);
  ($carry, $bits128) = add128($bits1281, $bits1282);
  $carry      = sub128($bits1281, $bits1282);
  ($spurious, $cidr) = notcontiguous($mask128);

  # widening and narrowing
  $ipv6naddr  = ipv4to6($netaddr);        # ::d.d.d.d
  $ipv6naddr  = ipanyto6($netaddr);       # either family in, 128 bits out
  $netaddr    = ipv6to4($ipv6naddr);      # low 32 bits

  # decimal text
  $bcdtext    = bin2bcd($bits128);
  $bits128    = bcd2bin($bcdtext);

=head1 DESCRIPTION

B<NetAddr::IP::UtilPP> is the pure Perl implementation of the functions in
B<NetAddr::IP::Util> that touch 128 bit strings.  In a pure Perl build,
B<NetAddr::IP::Util> loads it in place of its XS code, and C<mode()> from
B<NetAddr::IP::Util> then reports C<Pure Perl>:

  mode()   'CC XS' or 'Pure Perl'

Both implementations croak on a wrong-length argument with the same
message, naming the function and both lengths in bits:

  Bad arg length for NetAddr::IP::Util::hasbits, length is 40,
  should be 128

The message names the function in B<NetAddr::IP::Util>, the module
callers normally load, even when this module is called directly.  Each
entry below says what its function does with a bad argument.

=head1 FUNCTIONS

These implement the same operations as NetAddr::IP::Util.

=head2 Family test and shift

=over 4

=item $rv = hasbits($bits128);

This function returns true if there are one's present in the 128 bit string
and false if all the bits are zero.

  # i.e.
  if (hasbits($bits128)) {
      &do_something;
  }

  # or
  if (hasbits($bits128 & $mask128)) {
      &do_something;
  }

This allows the implementation of logical functions of the form of:

  if ($bits128 & $mask128) {
      ...

  input:    128 bit IPv6 string
  returns:  true if any bits are present

Croaks if the argument is not 16 bytes.

=cut

sub _deadlen {
    my ($len, $should) = @_;
    $should = $IPV6_BITS
        unless $should;
    my $sub = _callersub();
    my $bits = defined $len
        ? $len * $OCTET_BITS
        : 'undefined';
    croak "Bad arg length for $sub, length is $bits, should be $should";
}

sub hasbits {
    my ($bits128) = @_;
    _deadlen(length($bits128))
        if !defined($bits128) || length($bits128) != $V6_PACKED_BYTES;
    return 1 if vec($bits128, 0, $IPV4_BITS);
    return 1 if vec($bits128, 1, $IPV4_BITS);
    return 1 if vec($bits128, 2, $IPV4_BITS);
    return 1 if vec($bits128, 3, $IPV4_BITS);
    return 0;
}

#=item $rv = isIPv4($bits128);
#
#This function returns true if there are no on bits present in the IPv6
#portion of the 128 bit string and false otherwise.
#
#=cut
#
#sub xisIPv4 {
#  _deadlen(length($_[0]))
#    if length($_[0]) != 16;
#  return 0 if vec($_[0],0,32);
#  return 0 if vec($_[0],1,32);
#  return 0 if vec($_[0],2,32);
#  return 1;
#}

=item $bitsXn = shiftleft($bits128, $n);

  input:    128 bit string variable, number of shifts [optional]
  returns:  bits X n shifts

  NOTE: input bits are returned if $n is not specified

A negative C<$n>, or one above C<$MAX_SHIFTLEFT> of 128, croaks, and so
does a C<$bits128> that is not 16 bytes.

=cut

# multiply x 2
# returns true if the result overflowed 128 bits
#
sub _128x2 {
    my $inp = shift;
    my $carry = ($$inp[0] & 0x80000000) ? 1 : 0;    # bit shifted out the top
    $$inp[0] = ($$inp[0] << 1 & 0xffffffff) + (($$inp[1] & 0x80000000) ? 1:0);
    $$inp[1] = ($$inp[1] << 1 & 0xffffffff) + (($$inp[2] & 0x80000000) ? 1:0);
    $$inp[2] = ($$inp[2] << 1 & 0xffffffff) + (($$inp[3] & 0x80000000) ? 1:0);
    $$inp[3] = $$inp[3]  << 1 & 0xffffffff;
    return $carry;
}

# multiply x 10, returns true if the result overflowed 128 bits
#
sub _128x10 {
    my $a128p    = shift;
    my $overflow = _128x2($a128p);       # x2
    my @x2 = @$a128p;                    # save the x2 value
    $overflow |= _128x2($a128p);
    $overflow |= _128x2($a128p);         # x8
    $overflow |= _sa128($a128p,\@x2, 0);  # add for x10
    return $overflow;
}

# a count or constant as a plain scalar: an object goes through its numeric
# conversion, as the XS reads it, or else its text
sub _plain_number {
    my ($n) = @_;
    return $n unless ref $n;
    return looks_like_number($n) ? sprintf('%.17g', $n) : "$n";
}

sub shiftleft {
    my $bits = $_[0];
    _deadlen(length($bits))
        if !defined($bits) || length($bits) != $V6_PACKED_BYTES;
    my $given = $_[1];
    my $shifts = _plain_number($given);
    return $bits unless defined $shifts && $shifts ne '';
    # an integer count from 0 to 128; undef or the empty string returns the input
    croak "Bad arg value for NetAddr::IP::Util::shiftleft, is $given, should be 0 thru $MAX_SHIFTLEFT"
        unless looks_like_number($shifts)
        && $shifts >= 0
        && $shifts <= $MAX_SHIFTLEFT
        && $shifts == int($shifts);
    return $bits if $shifts == 0;
    my @uint32t = unpack('N4', $bits);
    _128x2(\@uint32t) for 1 .. $shifts;
    return pack('N4', @uint32t);
}

sub slowadd128 {
    my @ua = unpack('N4', $_[0]);
    my @ub = unpack('N4', $_[1]);
    my $carry = _sa128(\@ua, \@ub, $_[2]);
    return ($carry, pack('N4', @ua))
        if wantarray;
    return $carry;
}

sub _sa128 {
    my ($uap, $ubp, $carry) = @_;
    if (($$uap[3] += $$ubp[3] + $carry) > 0xffffffff) {
        $$uap[3] -= 4294967296;    # 0x1_00000000
        $carry = 1;
    }
    else {
        $carry = 0;
    }

    if (($$uap[2] += $$ubp[2] + $carry) > 0xffffffff) {
        $$uap[2] -= 4294967296;
        $carry = 1;
    }
    else {
        $carry = 0;
    }

    if (($$uap[1] += $$ubp[1] + $carry) > 0xffffffff) {
        $$uap[1] -= 4294967296;
        $carry = 1;
    }
    else {
        $carry = 0;
    }

    if (($$uap[0] += $$ubp[0] + $carry) > 0xffffffff) {
        $$uap[0] -= 4294967296;
        $carry = 1;
    }
    else {
        $carry = 0;
    }
    return $carry;
}

=back

=head2 Arithmetic

=over 4

=item addconst($ipv6naddr, $signed_32con);

Add a signed constant to a 128 bit string variable.

  input:    128 bit IPv6 string, signed 32 bit integer
  returns:  scalar  carry
            array   (carry, result)

Croaks if C<$ipv6naddr> is not 16 bytes.

=cut

sub addconst {
    my ($a128, $given) = @_;
    my $const = _plain_number($given);
    _deadlen(length($a128))
        if !defined($a128) || length($a128) != $V6_PACKED_BYTES;
    unless (defined $const && $const ne '') {
        return (wantarray) ? (0, $a128) : 0;
    }
    # an integer in the signed 32 bit range, the rule the XS applies
    croak "Bad arg value for NetAddr::IP::Util::addconst, is $given, should be an integer from -2147483648 thru 2147483647"
        unless looks_like_number($const)
        && $const >= -2_147_483_648
        && $const <= 2_147_483_647
        && $const == int($const);
    return (wantarray) ? (0, $a128) : 0 if $const == 0;
    my $sign = ($const < 0) ? 0xffffffff : 0;
    my $b128 = pack('N4', $sign, $sign, $sign, $const);
    @_ = ($a128, $b128, 0);
    goto &slowadd128;
}

=item add128($ipv6naddr1, $ipv6naddr2);

Add two 128 bit string variables.

  input:    128 bit string var1, 128 bit string var2
  returns:  scalar  carry
            array   (carry, result)

Croaks if either argument is not 16 bytes.

=cut

sub add128 {
    my ($a128, $b128) = @_;
    _deadlen(length($a128))
        if !defined($a128) || length($a128) != $V6_PACKED_BYTES;
    _deadlen(length($b128))
        if !defined($b128) || length($b128) != $V6_PACKED_BYTES;
    @_ = ($a128, $b128, 0);
    goto &slowadd128;
}

=item sub128($ipv6naddr1, $ipv6naddr2);

Subtract two 128 bit string variables.

  input:    128 bit string var1, 128 bit string var2
  returns:  scalar  carry
            array   (carry, result)

Note: The carry from this operation is the result of adding the one's
complement of ARG2 +1 to the ARG1. It is logically B<NOT borrow>.

  i.e.  if ARG1 >= ARG2 then carry = 1
  or    if ARG1  < ARG2 then carry = 0

Croaks if either argument is not 16 bytes.

=cut

sub sub128 {
    my ($a128, $b128) = @_;
    _deadlen(length($a128))
        if !defined($a128) || length($a128) != $V6_PACKED_BYTES;
    _deadlen(length($b128))
        if !defined($b128) || length($b128) != $V6_PACKED_BYTES;
    @_ = ($a128, ~$b128, 1);
    goto &slowadd128;
}

=item ($spurious, $cidr) = notcontiguous($mask128);

This function counts the bit positions remaining in the mask when the
rightmost '0's are removed.

  input:  128 bit netmask
  returns true if there are spurious zero bits remaining in the mask
          false if the mask is contiguous one's, 128 bit cidr

Croaks if the argument is not 16 bytes.

=cut

sub notcontiguous {
    my ($mask128) = @_;
    _deadlen(length($mask128))
        if !defined($mask128) || length($mask128) != $V6_PACKED_BYTES;
    my @ua = unpack('N4', ~$mask128);
    my $count;
    for ($count = $IPV6_BITS;$count > 0; $count--) {
        last unless $ua[3] & 1;
        $ua[3] >>= 1;
        $ua[3] |= 0x80000000 if $ua[2] & 1;
        $ua[2] >>= 1;
        $ua[2] |= 0x80000000 if $ua[1] & 1;
        $ua[1] >>= 1;
        $ua[1] |= 0x80000000 if $ua[0] & 1;
        $ua[0] >>= 1;
    }

    # 1 or 0, as the XS returns
    my $spurious = ($ua[0] | $ua[1] | $ua[2] | $ua[3]) ? 1 : 0;
    return $spurious
        unless wantarray;
    return ($spurious, $count);
}

=back

=head2 Widening and narrowing

=over 4

=item $ipv6naddr = ipv4to6($netaddr);

Convert an ipv4 network address into an ipv6 network address.

  input:    32 bit network address
  returns:  128 bit network address

Croaks if the argument is not 4 bytes.
=cut

sub ipv4to6 {
    my ($netaddr) = @_;
    _deadlen(length($netaddr), $IPV4_BITS)
        if !defined($netaddr) || length($netaddr) != $V4_PACKED_BYTES;
    return pack('L3a4', 0, 0, 0, $netaddr);
}

=item $ipv6naddr = mask4to6($netaddr);

Convert an ipv4 network address into an ipv6 network mask.

  input:    32 bit network/mask address
  returns:  128 bit network/mask address

NOTE: returns the high 96 bits as one's

Croaks if the argument is not 4 bytes.

=cut

sub mask4to6 {
    my ($netaddr) = @_;
    _deadlen(length($netaddr), $IPV4_BITS)
        if !defined($netaddr) || length($netaddr) != $V4_PACKED_BYTES;
    return pack('L3a4', 0xffffffff, 0xffffffff, 0xffffffff, $netaddr);
}

=item $ipv6naddr = ipanyto6($netaddr);

Similar to ipv4to6 except that this function takes either an IPv4 or IPv6
input and always returns a 128 bit IPv6 network address.

  input:    32 or 128 bit network address
  returns:  128 bit network address

Croaks if the argument is neither 4 nor 16 bytes.
=cut

sub ipanyto6 {
    my $naddr = shift;
    return _deadlen(undef, "$IPV4_BITS or $IPV6_BITS")
        unless defined $naddr;
    my $len   = length($naddr);
    return $naddr
        if $len == $V6_PACKED_BYTES;
    return pack('L3a4', 0, 0, 0, $naddr)
        if $len == $V4_PACKED_BYTES;
    return _deadlen($len, "$IPV4_BITS or $IPV6_BITS");
}

=item $ipv6naddr = maskanyto6($netaddr);

Similar to mask4to6 except that this function takes either an IPv4 or IPv6
netmask and always returns a 128 bit IPv6 netmask.

  input:    32 or 128 bit network mask
  returns:  128 bit network mask

Croaks if the argument is neither 4 nor 16 bytes.
=cut

sub maskanyto6 {
    my $naddr = shift;
    return _deadlen(undef, "$IPV4_BITS or $IPV6_BITS")
        unless defined $naddr;
    my $len   = length($naddr);
    return $naddr
        if $len == $V6_PACKED_BYTES;
    return pack('L3a4', 0xffffffff, 0xffffffff, 0xffffffff, $naddr)
        if $len == $V4_PACKED_BYTES;
    return _deadlen($len, "$IPV4_BITS or $IPV6_BITS");
}

=item $netaddr = ipv6to4($ipv6naddr);

Truncate the upper 96 bits of a 128 bit address and return the lower
32 bits. Returns an IPv4 address as returned by inet_aton.

  input:    128 bit network address
  returns:  32 bit inet_aton network address

Croaks if the argument is not 16 bytes.

=cut

sub ipv6to4 {
    my $naddr = shift;
    _deadlen(length($naddr))
        if !defined($naddr) || length($naddr) != $V6_PACKED_BYTES;
    @_ = unpack('L3H8', $naddr);
    return pack('H8', @{_}[3..10]);
}

=back

=head2 Decimal strings

=over 4

=item $bcdtext = bin2bcd($bits128);

Convert a 128 bit binary string into binary coded decimal text digits.

  input:    128 bit string variable
  returns:  string of bcd text digits

Croaks if the argument is not 16 bytes.

=cut

sub bin2bcd {
    my ($bits128) = @_;
    _deadlen(length($bits128))
        if !defined($bits128) || length($bits128) != $V6_PACKED_BYTES;
    unpack("H$MAX_BCD_DIGITS", _bin2bcdn($bits128)) =~ /^0*(.+)/;
    return $1;
}

=item $bits128 = bcd2bin($bcdtxt);

Convert a bcd text string to 128 bit string variable

  input:    string of bcd text digits
  returns:  128 bit string variable

Croaks if the string is empty, is longer than 40 digits, holds a
character other than 0 to 9, or is a number too large for 128 bits.

=cut

sub bcd2bin {
    my ($bcd) = @_;
    _bcdcheck($bcd);
    @_ = ($bcd, 'NetAddr::IP::Util::bcd2bin');
    goto &_bcd2bin;
}


#=item $onescomp = comp128($bits128);
#
#This function is for testing, it is more efficient to use perl " ~ "
#on the bit string directly. This interface to the B<C> routine is published for
#module testing purposes because it is used internally in the B<sub128> routine. The
#function is very fast, but calling if from perl directly is very slow. It is almost
#33% faster to use B<sub128> than to do a 1's comp with perl and then call
#B<add128>. In the PurePerl version, it is a call to
#
#  sub {return ~ $_[0]};
#
#=cut

sub comp128 {
    my ($bits128) = @_;
    _deadlen(length($bits128))
        if !defined($bits128) || length($bits128) != $V6_PACKED_BYTES;
    return ~$bits128;
}

#=item $bcdpacked = bin2bcdn($bits128);
#
#Convert a 128 bit binary string into binary coded decimal digits.
#This function is for testing only.
#
#  input:    128 bit string variable
#  returns:    string of packed decimal digits
#
#  i.e.    text = unpack("H*", $bcd);
#
#=cut

sub bin2bcdn {
    my ($bits128) = @_;
    _deadlen(length($bits128))
        if !defined($bits128) || length($bits128) != $V6_PACKED_BYTES;
    return _bin2bcdn($bits128);
}

sub _bin2bcdn {
    my ($b128) = @_;
    my @binary = unpack('N4', $b128);
    my @nbcd = (0, 0, 0, 0, 0);        # 5 - 32 bit registers
    my ($add3, $msk8, $bcd8, $carry, $tmp);
    my $j = 0;
    my $k = -1;
    my $binmsk = 0;
    foreach(0..127) {
        unless ($binmsk) {
            $binmsk = 0x80000000;
            $k++;
        }
        $carry = $binary[$k] & $binmsk;
        $binmsk >>= 1;
        next unless $carry || $j;      # skip leading zeros
        foreach(4, 3, 2, 1, 0) {
            $bcd8 = $nbcd[$_];
            $add3 = 3;
            $msk8 = 8;
            $j = 0;
            while ($j < 8) {
                $tmp = $bcd8 + $add3;
                if ($tmp & $msk8) {
                    $bcd8 = $tmp;
                }
                $add3 <<= 4;
                $msk8 <<= 4;
                $j++;
            }
            $tmp = $bcd8 & 0x80000000; # propagate carry
            $bcd8 <<= 1;               # x2
            if ($carry) {
                $bcd8 += 1;
            }
            $nbcd[$_] = $bcd8;
            $carry = $tmp;
        }
    }
    return pack('N5', @nbcd);
}

#=item $bcdtext = bcdn2txt($bcdpacked);
#
#Convert a packed bcd string into text digits, suppress the leading zeros.
#This function is for testing only.
#
#  input:    string of packed decimal digits
#        consisting of exactly 40 digits
#  returns:    hexdecimal digits
#
#Similar to unpack("H*", $bcd);
#
#=cut

sub bcdn2txt {
    my ($bcdn) = @_;
    if (!defined($bcdn) || length($bcdn) != $PACKED_BCD_BYTES) {
        my $digits = defined $bcdn
            ? 2 * length($bcdn)
            : 'undefined';
        croak 'Bad arg length for NetAddr::IP::Util::bcdn2txt, length is '
            . $digits
            . ", should be $MAX_BCD_DIGITS digits"
    }
    (unpack("H$MAX_BCD_DIGITS", $bcdn)) =~ /^0*(.+)/;
    return $1;
}

#=item $bits128 = bcdn2bin($bcdpacked,$ndigits);
#
# Convert a packed bcd string into a 128 bit string variable
#
# input:    packed bcd string
#        number of digits in string
# returns:    128 bit string variable
#

=item $bits128 = bcdn2bin($bcdpacked,$ndigits);

Convert a packed bcd string into a 128 bit string variable

  input:    packed bcd string
        number of digits in string
  returns:    128 bit string variable

=cut

sub bcdn2bin {
    croak q|Bad usage, should have NetAddr::IP::Util::bcdn2bin('packedbcd','length')|
        if @_ < 2;
    my ($bcd, $given) = @_;
    my $dc = _plain_number($given);
    $dc = 0 unless defined $dc && $dc ne '';
    my $digits = defined $bcd
        ? 2 * length($bcd)
        : 'undefined';
    croak "Bad arg length for NetAddr::IP::Util::bcdn2bin, length is $digits, should be 1 to $MAX_BCD_DIGITS digits"
        if !defined($bcd) || length($bcd) > $PACKED_BCD_BYTES;
    # an integer count, made plain because it goes into an unpack template
    croak "Bad digit count for NetAddr::IP::Util::bcdn2bin, is $dc, should be 1 to $digits digits"
        unless looks_like_number($dc) && $dc >= 1 && $dc < $digits + 1 && $dc == int($dc);
    $dc = int($dc);
    return _bcd2bin(unpack("H$dc", $bcd), 'NetAddr::IP::Util::bcdn2bin');
}

sub _bcd2bin {
    my $caller = $_[1] // 'NetAddr::IP::Util::_bcd2bin';
    my @bcd = split('', $_[0]);
    my @hbits = (0, 0, 0, 0);
    my @digit = (0, 0, 0, 0);
    my $found = 0;
    my $overflow = 0;
    foreach(@bcd) {
        my $bcd = $_ & 0xf;        # just the nibble
        unless ($found) {
            next unless $bcd;        # skip leading zeros
            $found = 1;
            $hbits[3] = $bcd;        # set the first digit, no x10 necessary
            next;
        }
        $overflow |= _128x10(\@hbits);
        $digit[3] = $bcd;
        $overflow |= _sa128(\@hbits,\@digit, 0);
    }
    if ($overflow) {
        croak "Bad arg value for $caller, number is larger than 128 bits";
    }
    return pack('N4', @hbits);
}

#=item $bcdpacked = simple_pack($bcdtext);
#
#Convert a numeric string into a packed bcd string, left fill with zeros
#This function is for testing only.
#
#  input:    string of decimal digits
#  returns:    string of packed decimal digits
#
#Similar to pack("H*", $bcdtext);
#
sub _bcdcheck {
    my ($bcd) = @_;
    my $len = defined $bcd
        ? length($bcd)
        : 'undefined';
    croak sprintf("Bad arg length for %s, length is %s, should be 1 to $MAX_BCD_DIGITS digits", _callersub(), $len)
        if !defined($bcd) || length($bcd) > $MAX_BCD_DIGITS || length($bcd) < 1;
    croak sprintf("Bad char in string for %s, character is '%s', allowed are 0-9", _callersub(), $1)
        if $bcd =~ /([^0-9])/;
}

sub simple_pack {
    my ($bcd) = @_;
    _bcdcheck($bcd);
    while (length($bcd) < $MAX_BCD_DIGITS) {
        $bcd = '0'. $bcd;
    }
    return pack("H$MAX_BCD_DIGITS", $bcd);
}

=back

=head1 EXPORT_OK

The functions this module can export, all of them also exported by
B<NetAddr::IP::Util>.  The C<:all> tag imports every one.  The first
thirteen are documented above; the last five are helpers for the test
suite, exported so that this module and the XS build can be compared
against each other, and not stable API.

    hasbits
    shiftleft
    addconst
    add128
    sub128
    notcontiguous
    ipv4to6
    mask4to6
    ipanyto6
    maskanyto6
    ipv6to4
    bin2bcd
    bcd2bin
    comp128
    bin2bcdn
    bcdn2txt
    bcdn2bin
    simple_pack

Where C<bin2bcd> returns text digits, C<simple_pack> turns text digits
into a packed string, padding to C<$MAX_BCD_DIGITS> first.  The inverse
of the packing is C<bcdn2txt>, and C<bcdn2bin> turns a packed string back
to 128 bits.  The last helper, C<comp128>, is published only for testing,
because Perl's C<~> is faster than calling into the XS routine for a
one's complement.

=head1 ADDITIONAL LICENSE

This file is also available to redistribute it and/or modify it under
the terms of the "Artistic License" which comes with this distribution,
in the file named "Artistic".

=head1 SEE ALSO

L<NetAddr::IP::Util>, L<NetAddr::IP>, L<NetAddr::IP::Lite>

=cut

1;
