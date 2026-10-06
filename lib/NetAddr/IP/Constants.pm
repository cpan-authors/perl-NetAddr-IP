#!/bin/false
# ABSTRACT: Magic number constants for NetAddr::IP
# PODNAME: NetAddr::IP::Constants

use strict;
use warnings;

package NetAddr::IP::Constants;
# VERSION

use Exporter qw(import);

our @EXPORT_OK = qw(
    $DEFAULT_NETLIMIT_EXP
    $IPV4_BITS
    $IPV4_OFFSET
    $IPV6_BITS
    $MAX_BCD_DIGITS
    $MAX_NETLIMIT_EXP
    $MAX_OCTET
    $MAX_SHIFTLEFT
    $OCTET_BITS
    $OCTET_COUNT
    $PACKED_BCD_BYTES
    $RFC3021_THRESHOLD
    $V4_PACKED_BYTES
    $V6_PACKED_BYTES
);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

our $DEFAULT_NETLIMIT_EXP = 16;                        # 2**16 = 65536
our $IPV4_BITS            = 32;                        # RFC 791
our $IPV6_BITS            = 128;                       # RFC 4291
our $MAX_BCD_DIGITS       = 40;                        # 128 bit BCD digits
our $MAX_NETLIMIT_EXP     = 24;                        # 2**24 = 16M
our $MAX_OCTET            = 255;                       # RFC 791
our $OCTET_BITS           = 8;                         # RFC 791
our $OCTET_COUNT          = 4;                         # RFC 791
our $PACKED_BCD_BYTES     = 20;                        # 40/2
our $V4_PACKED_BYTES      = 4;                         # 32/8
our $V6_PACKED_BYTES      = 16;                        # 128/8
our $IPV4_OFFSET          = $IPV6_BITS - $IPV4_BITS;   # 96, RFC 4291 s2.5.5
our $MAX_SHIFTLEFT        = $IPV6_BITS;                # 128
our $RFC3021_THRESHOLD    = $IPV6_BITS - 1;            # 127, RFC 3021

1;

__END__
=head1 SYNOPSIS

  use NetAddr::IP::Constants qw($IPV6_BITS $IPV4_BITS $IPV4_OFFSET);

  print "$IPV6_BITS\n";                      # 128
  print "$IPV4_BITS\n";                      # 32
  print "$IPV4_OFFSET\n";                    # 96

  print "$NetAddr::IP::Constants::IPV6_BITS\n";   # 128, same variable

=head1 DESCRIPTION

Provides named constants for the magic numbers used throughout the
NetAddr::IP family of modules.  Importing by name avoids polluting the
caller's namespace with abbreviations.

These are C<our> package variables and are read at runtime, not resolved
at compile time, so importing one does not freeze its value.  Assigning
to an imported name changes what that name returns for the rest of the
program:

  use NetAddr::IP::Constants qw($IPV6_BITS);
  print "$IPV6_BITS\n";                      # 128
  $IPV6_BITS = 999;
  print "$IPV6_BITS\n";                      # 999

The import is an alias, not a copy, so an assignment to the imported
name writes through to the module's own variable, which is what the
rest of the distribution reads:

  print "$NetAddr::IP::Constants::IPV6_BITS\n";   # 999

Which is why reassigning an imported constant changes the library's own
behaviour, not just the caller's view of it.

A variable of the same name already declared in the importing package is
not overwritten by the import, because C<Exporter> only installs the
alias when the name is free.  NetAddr::IP::InetBase, NetAddr::IP::Util
and NetAddr::IP::UtilPP each import these constants and always read their
own copy, so a caller's reassignment changes nothing inside the library.
Overriding a constant is therefore reachable but unsupported, and can
only be relied on to affect code that reads the imported name.

=head1 CONSTANTS

=head2 IPv4 address geometry, RFC 791

=over 4

=item B<$IPV4_BITS>

IPv4 address width in bits.  Value: C<32>.  RFC 791 s2.1.

=item B<$MAX_OCTET>

Maximum value of a single IPv4 octet.  Value: C<255> (C<0xff>).  RFC 791
s2.1.

=item B<$OCTET_BITS>

Number of bits in a single IPv4 octet.  Value: C<8>.  RFC 791 s2.1.

=item B<$OCTET_COUNT>

Number of octets in an IPv4 address.  Value: C<4>.  RFC 791 s2.1.

=item B<$V4_PACKED_BYTES>

Size of a packed IPv4 address in bytes.  Value: C<4> (C<32/8>).  RFC 791
s2.1.

=back

=head2 IPv6 address geometry, RFC 4291

=over 4

=item B<$IPV6_BITS>

IPv6 address width in bits.  Value: C<128>.  RFC 4291 s2.1.

=item B<$V6_PACKED_BYTES>

Size of a packed IPv6 address in bytes.  Value: C<16> (C<128/8>).  RFC
4291 s2.1.

=item B<$IPV4_OFFSET>

Offset of the IPv4-in-IPv6 representation in the 128 bit form, that is
C<$IPV6_BITS - $IPV4_BITS>.  Value: C<96>.

RFC 4291 s2.5.5.1 defines the IPv4-compatible prefix C<::/96>, which is
deprecated, and s2.5.5.2 the IPv4-mapped prefix C<::ffff:0:0/96>.  Both
place the 32 bit IPv4 address at this offset, which is why the same
offset serves both.

=back

=head2 Point-to-point networks, RFC 3021

=over 4

=item B<$RFC3021_THRESHOLD>

Networks of length /127 or /31 are treated as having two usable
addresses, per RFC 3021.  Value: C<127> (i.e. C<$IPV6_BITS - 1>).

=back

=head2 Netlimit exponents

=over 4

=item B<$DEFAULT_NETLIMIT_EXP>

Power-of-two exponent for the default netlimit, C<2**16 = 65536>
networks.  Value: C<16>.

=item B<$MAX_NETLIMIT_EXP>

Power-of-two exponent for the maximum netlimit, C<2**24 = 16777216>
networks.  Value: C<24>.

=item B<$MAX_SHIFTLEFT>

Maximum number of bits C<shiftleft()> can shift.  Value: C<128>, that is
C<$IPV6_BITS>.

=back

=head2 Binary coded decimal

=over 4

=item B<$MAX_BCD_DIGITS>

Width of a packed BCD string, in hex nibbles.  Value: C<40>.

The width follows from the value range rather than from the digit count
alone.  The largest 128 bit value needs 39 decimal digits, and BCD holds
one digit per nibble, but a packed string has to be a whole number of
bytes, so 39 nibbles round up to 40, which is 20 bytes.  C<bin2bcd()>
returns 39 digits unpadded, and C<simple_pack()> is what pads to 40
before C<pack("H40")>.

=item B<$PACKED_BCD_BYTES>

Size of a packed BCD string in bytes.  Value: C<20> (C<$MAX_BCD_DIGITS/2>,
two digits per byte).

=back

=head1 EXPORTS

Nothing is exported by default.  Use explicit import tags:

  use NetAddr::IP::Constants qw(:all);

or import individual constants:

  use NetAddr::IP::Constants qw($IPV6_BITS $IPV4_BITS);

=cut
