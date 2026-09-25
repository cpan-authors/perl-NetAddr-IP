#!/bin/false
# ABSTRACT: Magic number constants for NetAddr::IP
# PODNAME: NetAddr::IP::Constants

use strict;
use warnings FATAL => 'all';

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

=head1 DESCRIPTION

Provides named constants for magic numbers used throughout the
NetAddr::IP family of modules.  Importing by name avoids polluting
the caller namespace with abbreviations and ensures that each
constant resolves at compile time.

All constants are C<our> variables and may be overridden by the
caller if needed, but doing so is unsupported.

=head1 CONSTANTS

=over 4

=item B<DEFAULT_NETLIMIT_EXP>

 Power-of-two exponent for the default netlimit.  The default is
 C<2**16 = 65536> networks.  Value: C<16>.

=item B<IPV4_BITS>

 IPv4 address width in bits.  Value: C<32>.
 RFC 791 s2.1.

=item B<IPV4_OFFSET>

 Offset of the IPv4-in-IPv6 mapped address in the 128-bit
 representation.  Value: C<96> (i.e. C<IPV6_BITS - IPV4_BITS>).
 RFC 4291 s2.5.5 (dual-stack, V4-mapped, V4-compatible).

=item B<IPV6_BITS>

 IPv6 address width in bits.  Value: C<128>.
 RFC 4291 s2.1.

=item B<MAX_BCD_DIGITS>

 Maximum number of BCD digits that can represent a 128-bit value.
 Value: C<40> (i.e. C<ceil(128 * log10(2))>).

=item B<MAX_NETLIMIT_EXP>

 Power-of-two exponent for the maximum netlimit.  The maximum is
 C<2**24 = 16777216> networks.  Value: C<24>.

=item B<MAX_OCTET>

 Maximum value of a single IPv4 octet.  Value: C<255> (C<0xff>).
 RFC 791 s2.1.

=item B<MAX_SHIFTLEFT>

 Maximum number of bits that can be shifted by C<shiftleft()>.
 Value: C<128> (i.e. C<IPV6_BITS>).

=item B<OCTET_BITS>

 Number of bits in a single IPv4 octet.  Value: C<8>.
 RFC 791 s2.1.

=item B<OCTET_COUNT>

 Number of octets in an IPv4 address.  Value: C<4>.
 RFC 791 s2.1.

=item B<PACKED_BCD_BYTES>

 Size of a packed BCD string holding B<MAX_BCD_DIGITS> digits.
 Value: C<20> (C<40/2>, two digits per byte).

=item B<RFC3021_THRESHOLD>

 Point-to-point network boundary.  Networks of length /127 or /31
 are treated as having exactly two usable addresses per RFC 3021.
 Value: C<127> (i.e. C<IPV6_BITS - 1>).

=item B<V4_PACKED_BYTES>

 Size of a packed IPv4 address in bytes.  Value: C<4> (C<32/8>).
 RFC 791 s2.1.

=item B<V6_PACKED_BYTES>

 Size of a packed IPv6 address in bytes.  Value: C<16> (C<128/8>).
 RFC 4291 s2.1.

=back

=head1 EXPORTS

Nothing is exported by default.  Use explicit import tags:

  use NetAddr::IP::Constants qw(:all);

or import individual constants:

  use NetAddr::IP::Constants qw($IPV6_BITS $IPV4_BITS);

=cut
