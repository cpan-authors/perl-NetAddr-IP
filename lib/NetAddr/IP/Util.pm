#!/bin/false
# ABSTRACT: Native C and pure perl implementations of IPv4 and IPv6 address utilities
# PODNAME: NetAddr::IP::Util

use strict;
use warnings;

package NetAddr::IP::Util;
# VERSION

use parent qw(Exporter DynaLoader);
use DynaLoader ();


our @EXPORT_OK = qw(
        inet_aton
        inet_ntoa
        ipv6_aton
        ipv6_ntoa
        ipv6_n2x
        ipv6_n2d
        inet_any2n
        hasbits
        isIPv4
        isNewIPv4
        isAnyIPv4
        inet_n2dx
        inet_n2ad
        inet_pton
        inet_ntop
        inet_4map6
        shiftleft
        addconst
        add128
        sub128
        notcontiguous
        bin2bcd
        bcd2bin
        mode
        ipv4to6
        mask4to6
        ipanyto6
        maskanyto6
        ipv6to4
        bin2bcdn
        bcdn2txt
        bcdn2bin
        simple_pack
        comp128
        packzeros
        AF_INET
        AF_INET6
        naip_gethostbyname
        havegethostbyname2
);
our %EXPORT_TAGS = (
        all     => [@EXPORT_OK],
        inet    => [qw(
                inet_aton
                inet_ntoa
                ipv6_aton
                ipv6_ntoa
                ipv6_n2x
                ipv6_n2d
                inet_any2n
                inet_n2dx
                inet_n2ad
                inet_pton
                inet_ntop
                inet_4map6
                ipv4to6
                mask4to6
                ipanyto6
                maskanyto6
                ipv6to4
                packzeros
                naip_gethostbyname
        )],
        math    => [qw(
                shiftleft
                hasbits
                isIPv4
                isNewIPv4
                isAnyIPv4
                addconst
                add128
                sub128
                notcontiguous
                bin2bcd
                bcd2bin
        )],
        ipv4    => [qw(
                inet_aton
                inet_ntoa
        )],
        ipv6    => [qw(
                ipv6_aton
                ipv6_ntoa
                ipv6_n2x
                ipv6_n2d
                inet_any2n
                inet_n2dx
                inet_n2ad
                inet_pton
                inet_ntop
                inet_4map6
                ipv4to6
                mask4to6
                ipanyto6
                maskanyto6
                ipv6to4
                packzeros
                naip_gethostbyname
        )],
);
our $Mode;

use NetAddr::IP::Constants qw($V4_PACKED_BYTES $V6_PACKED_BYTES);
use NetAddr::IP::Util_IS ();
use NetAddr::IP::InetBase qw(
        :upper
        AF_INET
        AF_INET6
        inet_any2n
        inet_aton
        inet_n2ad
        inet_n2dx
        inet_ntoa
        inet_ntop
        inet_pton
        ipv6_aton
        ipv6_n2d
        ipv6_n2x
        ipv6_ntoa
        isAnyIPv4
        isIPv4
        isNewIPv4
        packzeros
);

*NetAddr::IP::Util::upper = \&NetAddr::IP::InetBase::upper;
*NetAddr::IP::Util::lower = \&NetAddr::IP::InetBase::lower;

my $xs_ok;
if (NetAddr::IP::Util_IS->not_pure) {
    my $xs_err;
    eval {        ## attempt to load 'C' version of utilities
        local $SIG{__DIE__};
        __PACKAGE__->bootstrap;
    };
    $xs_err = $@;
    $xs_ok  = ! $xs_err;
    warn "XS bootstrap failed with: $xs_err\n" if $xs_err;
}
if (NetAddr::IP::Util_IS->pure || ! $xs_ok) {    ## load the pure perl version if 'C' lib missing
    require NetAddr::IP::UtilPP;
    import NetAddr::IP::UtilPP qw( :all );
    $Mode = 'Pure Perl';
}
else {
    $Mode = 'CC XS';
}

# if Socket lib is broken in some way, check for overange values
#
#my $overange = yinet_aton('256.1') ? 1:0;
#my $overange = gethostbyname('256.1') ? 1:0;

sub mode() { $Mode };

my $_newV4compat = pack('N4', 0, 0, 0xffff, 0);

sub inet_4map6 {
    my $naddr = shift;
    if (length($naddr) == $V4_PACKED_BYTES) {
        $naddr = ipv4to6($naddr);
    }
    elsif (length($naddr) == $V6_PACKED_BYTES) {
        ;    # is OK
        return undef unless isAnyIPv4($naddr);
    }
    else {
        return undef;
    }
    $naddr |= $_newV4compat;
    return $naddr;
}

sub DESTROY {};

my $havegethostbyname2 = 0;

my $mygethostbyname;

my $_Sock6ok = 1;        # for testing gethostbyname

sub havegethostbyname2 {
    return $_Sock6ok
        ? $havegethostbyname2
        : 0;
}

sub import {
    if (grep { $_ eq ':noSock6' } @_) {
        $_Sock6ok = 0;
        @_ = grep { $_ ne ':noSock6' } @_;
    }
    NetAddr::IP::Util->export_to_level(1, @_);
}

package NetAddr::IP::UtilPolluted;

# Socket pollutes the name space with all of its symbols. Since
# we don't want them all, confine them to this name space.

use strict;
use Socket qw(
        AF_INET
        AF_INET6
        INADDR_LOOPBACK
        inet_aton
        inet_ntoa
        inet_ntop
        inet_pton
);

my $_v4zero = pack('L', 0);
my $_zero = pack('L4', 0, 0, 0, 0);

# invoke replacement subroutine for Perl's "gethostbyname"
# if Socket6 is available.
#
# NOTE: in certain BSD implementations, Perl's gethostbyname is broken
# we will use our own InetBase::inet_aton instead

sub _end_gethostbyname {
    #  my ($name, $aliases, $addrtype, $length, @addrs) = @_;
    my @rv = @_;
    # first ip address = rv[4]
    my $tip = $rv[4];
    unless ($tip && $tip ne $_v4zero && $tip ne $_zero) {
        @rv = ();
    }
    # length = rv[3]
    elsif ($rv[3] && $rv[3] == $NetAddr::IP::Util::V4_PACKED_BYTES) {
        foreach (4..$#rv) {
            $rv[$_] = NetAddr::IP::Util::inet_4map6(NetAddr::IP::Util::ipv4to6($rv[$_]));
        }
        $rv[3] = $NetAddr::IP::Util::V6_PACKED_BYTES;    # unconditionally set length to 16
    }
    elsif ($rv[3] == $NetAddr::IP::Util::V6_PACKED_BYTES) {
        ;    # is ok
    }
    else {
        @rv = ();
    }
    return @rv;
}

unless ( eval { local $SIG{__DIE__}; require Socket6 }) {
    $mygethostbyname = sub {
        # SEE NOTE above about broken BSD
        my @tip = gethostbyname(NetAddr::IP::InetBase::fillIPv4($_[0]));
        return &_end_gethostbyname(@tip);
    };
}
else {
    import Socket6 qw( gethostbyname2 getipnodebyname );
    my $try = eval { local $SIG{__DIE__}; my @try = gethostbyname2('127.0.0.1',NetAddr::IP::Util::AF_INET()); $try[4] };
    if (! $@ && $try && $try eq INADDR_LOOPBACK()) {
        *_ghbn2 = \&Socket6::gethostbyname2;
        $havegethostbyname2 = 1;
    }
    else {
        *_ghbn2 = sub { return () };    # use failure branch below
    }

    $mygethostbyname = sub {
        my @tip;
        unless ($_Sock6ok && (@tip = _ghbn2($_[0],NetAddr::IP::Util::AF_INET6())) && @tip > 1) {
            # SEE NOTE above about broken BSD
            @tip = gethostbyname(NetAddr::IP::InetBase::fillIPv4($_[0]));
        }
        return &_end_gethostbyname(@tip);
    };
}

package NetAddr::IP::Util;

sub naip_gethostbyname {
    my @rv = &$mygethostbyname($_[0]);
    return wantarray
        ? @rv
        : $rv[4];
}

1;

=head1 SYNOPSIS

  use NetAddr::IP::Util qw(
    inet_aton inet_ntoa ipv6_aton ipv6_ntoa ipv6_n2x ipv6_n2d
    inet_any2n inet_n2dx inet_n2ad inet_pton inet_ntop inet_4map6
    packzeros ipv4to6 mask4to6 ipanyto6 maskanyto6 ipv6to4
    hasbits isIPv4 isNewIPv4 isAnyIPv4
    shiftleft addconst add128 sub128 notcontiguous
    bin2bcd bcd2bin mode
    AF_INET AF_INET6 naip_gethostbyname
  );

  # text to packed, and back
$netaddr    = inet_aton('192.0.2.1');           # 4 bytes
  $dotquad    = inet_ntoa($netaddr);              # '192.0.2.1'
  $ipv6naddr  = ipv6_aton('2001:db8::1');         # 16 bytes
  $ipv6_text  = ipv6_ntoa($ipv6naddr);            # '2001:db8::1'
  $bits128    = inet_any2n('192.0.2.1');          # 0:0:0:0:0:0:C000:201
  $hex_text   = ipv6_n2x($ipv6naddr);             # '2001:DB8:0:0:0:0:0:1'
  $dec_text   = ipv6_n2d($ipv6naddr);             # '2001:DB8:0:0:0:0:0.0.0.1'
  $hex_text   = packzeros('0:0:0:0:0:ffff:c000:201');
                                                  # '::FFFF:C000:201'

  # the family tests
  $rv         = hasbits($bits128);                # true if any bit is set
  $rv         = isIPv4($bits128);                 # ::d.d.d.d, deprecated
  $rv         = isNewIPv4($bits128);              # ::ffff:d.d.d.d
  $rv         = isAnyIPv4($bits128);              # either of the above

  # widening and narrowing
  $ipv6naddr  = ipv4to6($netaddr);                # 0:0:0:0:0:0:C000:201
  $ipv6naddr  = inet_4map6($netaddr);             # 0:0:0:0:0:FFFF:C000:201
  $netaddr    = ipv6to4($ipv6naddr);              # low 32 bits

  # 128 bit arithmetic, carry in scalar context
  $signed_32bit = 1;
  $bits1281   = ipv6_aton('2001:db8::2');
  $bits1282   = ipv6_aton('2001:db8::1');
  $mask128    = ipv6_aton('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00');
  $carry      = addconst($bits128, $signed_32bit);
  ($carry, $bits128) = addconst($bits128, $signed_32bit);
  $carry      = sub128($bits1281, $bits1282);
  ($spurious, $cidr) = notcontiguous($mask128);

  $modetext   = mode;                             # 'CC XS' or 'Pure Perl'

=head1 DESCRIPTION

B<NetAddr::IP::Util> converts IPv4 and IPv6 addresses to and from 128
bit binary strings, and does arithmetic on those strings.  A 128 bit
string here means 16 bytes, whatever the family: an IPv4 address is
carried in the low 32 bits with the rest zero.  That is what lets one
set of functions take either family.

  use NetAddr::IP::Util qw(inet_any2n ipv6_n2x);

  my $v4 = inet_any2n('192.0.2.1');
  my $v6 = inet_any2n('2001:db8::1');
  print length($v4), "\n";      # 16, not 4
  print ipv6_n2x($v4), "\n";    # 0:0:0:0:0:0:C000:201

The strings behave like C<vec> strings under the bit operators:

  and   &
  or    |
  xor   ^
        ~    compliment

so masks and tests are written as arithmetic on them, which is what the
family tests below and C<netbroad> in L</EXAMPLES> do.

The functions come in two implementations.  The XS build compiles them
with Perl's XS extensions; C<-noxs> selects the pure Perl build, and
C<mode()> reports which one is loaded:

  print mode();      # 'CC XS' or 'Pure Perl'

The two agree on every input tried, including every error message.

The IPv6 functions accept every text form in RFC 4291 s2.2:

  x:x:x:x:x:x:x:x
  x:x:x:x:x:x:x:d.d.d.d
  ::x:x:x
  ::x:d.d.d.d
  ::ffff:d.d.d.d

and produce text following RFC 5952 s4.  Which case they produce depends
on the process-wide setting described under L<NetAddr::IP::InetBase>,
except for C<ipv6_ntoa> and C<inet_ntop>, which are always lowercase.

=head1 FUNCTIONS

=head2 Text to binary

=over 4

=item $netaddr = inet_aton($dotquad);

Convert a dot-quad IP address into an IPv4 packed network address.

  input:    IP address i.e. 192.5.16.32
  returns:  packed network address

=item $bits128 = ipv6_aton($ipv6_text);

Takes an IPv6 address in any of the RFC 4291 s2.2 text forms and returns
a 128 bit binary RDATA string.  Returns undef if the text is not a valid
address.

  input:    ipv6 text
  returns:  128 bit RDATA string, or undef

=item $ipv6naddr = inet_any2n($dotquad or $ipv6_text);

This function converts a text IPv4 or IPv6 address in text format in any
standard notation into a 128 bit IPv6 string address. It prefixes any
dot-quad address (if found) with '::' and passes it to B<ipv6_aton>.

  input:    dot-quad or RFC 4291 s2.2 address
  returns:  128 bit IPv6 string

=item $netaddr = inet_pton($AF_family,$hex_text);

This function takes an IP address in IPv4 or IPv6 text format and converts it into
binary format. The type of IP address conversion is controlled by the FAMILY
argument.

=back

=head2 Binary to text

=over 4

=item $dotquad = inet_ntoa($netaddr);

Convert a packed IPv4 network address to a dot-quad IP address.

  input:    packed network address
  returns:  IP address i.e. 10.4.12.123

=item $ipv6_text = ipv6_ntoa($ipv6naddr);

Convert a 128 bit binary IPv6 address to the compressed RFC 5952 s4
text representation, which is lowercase whatever the case setting.

  input:    128 bit RDATA string
  returns:  ipv6 text

NOTE: for an address with an IPv4 address in the low 32 bits the output
depends on whether Socket6 is installed.  See the entry for C<inet_ntop>.

=item $hex_text = ipv6_n2x($bits128);

Takes an IPv6 RDATA string and returns an 8 segment IPv6 hex address

  input:    128 bit RDATA string
  returns:  x:x:x:x:x:x:x:x

=item $dec_text = ipv6_n2d($bits128);

Takes an IPv6 RDATA string and returns a mixed hex - decimal IPv6 address
with the 6 uppermost chunks in hex and the lower 32 bits in dot-quad
representation.

  input:    128 bit RDATA string
  returns:  x:x:x:x:x:x:d.d.d.d

=item $dotquad or $hex_text = inet_n2dx($ipv6naddr);

This function B<does the right thing> and returns the text for either a
dot-quad IPv4 or a hex notation IPv6 address.

  input:    128 bit IPv6 string
  returns:  ddd.ddd.ddd.ddd
        or  x:x:x:x:x:x:x:x

=item $dotquad or $dec_text = inet_n2ad($ipv6naddr);

This function B<does the right thing> and returns the text for either a
dot-quad IPv4 or a hex::decimal notation IPv6 address.

  input:    128 bit IPv6 string
  returns:  ddd.ddd.ddd.ddd
        or  x:x:x:x:x:x:ddd.ddd.ddd.ddd

=item $hex_text = inet_ntop($AF_family,$netaddr);

This function takes and IP address in binary format and converts it into
text format. The type of IP address conversion is controlled by the FAMILY
argument.

NOTE: inet_ntop ALWAYS returns lowercase characters.

=item $hex_text = packzeros($hex_text);

Shortens an eight-group IPv6 hex address by substituting B<::> for the
longest run of zero groups, per RFC 5952 s4.2.1.  Where two runs are
equally long the first is shortened, s4.2.3, and a run of one zero group
is never shortened at all, s4.2.2.  Case follows the current setting,
which is uppercase by default here.

  print packzeros('0:0:0:0:0:ffff:c000:201');   # ::FFFF:C000:201
  print packzeros('2001:db8:0:1:1:1:1:1');      # 2001:DB8:0:1:1:1:1:1
  print packzeros('2001:db8:0:0:1:0:0:1');      # 2001:DB8::1:0:0:1
  print packzeros('2001:db8:0:1:1:0:0:1');      # 2001:DB8:0:1:1::1
  print packzeros('2001:0db8:0:1:2:3:4:5');     # 2001:DB8:0:1:2:3:4:5
  print packzeros('2001:db8:0:0:1:0:0:1:1');   # 2001::1:0:0:1:1

=back

=head2 Case

=over 4

=item NetAddr::IP::Util::lower();

Return IPv6 strings in lowercase.

=item NetAddr::IP::Util::upper();

Return IPv6 strings in uppercase.  This is the default.

=back

=head2 Family tests

=over 4

=item $rv = isIPv4($bits128);

This function returns true if there are no on bits present in the IPv6
portion of the 128 bit string and false otherwise.

  i.e.    the address must be of the form - ::d.d.d.d

Note: this is an old and deprecated ipV4 compatible ipV6 address

=item $rv = isNewIPv4($bits128);

This function returns true if the 128 bit string is an IPv4-mapped
address, of the form

  ::ffff:d.d.d.d

which is the RFC 4291 s2.5.5.2 prefix C<::ffff:0:0/96>.

=item $rv = isAnyIPv4($bits128);

This function returns true if the 128 bit string has an IPv4 address in
the low 32 bits, of either form

  ::d.d.d.d    or    ::ffff:d.d.d.d

which is the union of the RFC 4291 s2.5.5.1 compatible prefix and the
s2.5.5.2 mapped prefix.

=item $rv = hasbits($bits128);

This function returns true if there are one's present in the 128 bit string
and false if all the bits are zero.

  i.e.    if (hasbits($bits128)) {
      &do_something;
    }

  or    if (hasbits($bits128 & $mask128)) {
      &do_something;
    }

This allows the implementation of logical functions of the form of:

    if ($bits128 & $mask128) {
        ...

  input:    128 bit IPv6 string
  returns:  true if any bits are present

=back

=head2 Widening and narrowing

=over 4

=item $ipv6naddr = ipv4to6($netaddr);

Convert an ipv4 network address into an IPv6 network address.

  input:    32 bit network address
  returns:  128 bit network address

=item $ipv6naddr = mask4to6($netaddr);

Convert an ipv4 network address/mask into an ipv6 network mask.

  input:    32 bit network/mask address
  returns:  128 bit network/mask address

NOTE: returns the high 96 bits as one's

=item $ipv6naddr = ipanyto6($netaddr);

Similar to ipv4to6 except that this function takes either an IPv4 or IPv6
input and always returns a 128 bit IPv6 network address.

  input:    32 or 128 bit network address
  returns:  128 bit network address

=item $ipv6naddr = maskanyto6($netaddr);

Similar to mask4to6 except that this function takes either an IPv4 or IPv6
netmask and always returns a 128 bit IPv6 netmask.

  input:    32 or 128 bit network mask
  returns:  128 bit network mask

=item $netaddr = ipv6to4($ipv6naddr);

Truncate the upper 96 bits of a 128 bit address and return the lower
32 bits. Returns an IPv4 address as returned by inet_aton.

  input:    128 bit network address
  returns:  32 bit inet_aton network address

=item $ipv6naddr = inet_4map6($netaddr or $ipv6naddr);

Return an IPv4-mapped IPv6 address: the first 80 bits zero, the next 16
bits one, and the low 32 bits the IPv4 address.  RFC 4291 s2.5.5.2.

  input:    4 byte packed IPv4
        or  16 byte packed IPv6 already in one of the two
            IPv4-embedded spaces
  returns:  16 byte packed IPv6
        or  undef

  my $mapped = inet_4map6(inet_aton('192.0.2.1'));
  print ipv6_n2x($mapped);     # 0:0:0:0:0:FFFF:C000:201

An IPv6 input must already be in one of the two IPv4-embedded spaces.
i.e.

  ::ffff:d.d.d.d    or    ::d.d.d.d

=back

=head2 Arithmetic

=over 4

=item $bitsXn = shiftleft($bits128,$n);

Shift a 128 bit string left by C<$n> bits.  Bits shifted past the top are
discarded.

  input:    128 bit string,
        number of shifts [optional]
  returns:  128 bit string, shifted left by n

With no C<$n>, or with C<$n> of 0, the input is returned unchanged, on
both the XS and the pure Perl build:

  my $bits128 = ipv6_aton('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff');
  print ipv6_n2x(shiftleft($bits128));     # FFFF:...:FFFF unchanged
  print ipv6_n2x(shiftleft($bits128, 8));  # FFFF:...:FF00, top 8 gone

C<$n> above C<$MAX_SHIFTLEFT> of 128 croaks.

=item addconst($ipv6naddr,$signed_32con);

Add a signed constant to a 128 bit string variable.

  input:    128 bit IPv6 string,
        signed 32 bit integer
  returns:  scalar    carry
        array    (carry, result)

=item add128($ipv6naddr1,$ipv6naddr2);

Add two 128 bit string variables.

  input:    128 bit string var1,
        128 bit string var2
  returns:  scalar    carry
        array    (carry, result)

=item sub128($ipv6naddr1,$ipv6naddr2);

Subtract two 128 bit string variables.

  input:    128 bit string var1,
        128 bit string var2
  returns:  scalar    carry
        array    (carry, result)

Note: The carry from this operation is the result of adding the one's
complement of ARG2 +1 to the ARG1. It is logically
B<NOT borrow>.

  i.e.  if ARG1 >= ARG2 then carry = 1
    or  if ARG1  < ARG2 then carry = 0

=item ($spurious,$cidr) = notcontiguous($mask128);

This function counts the bit positions remaining in the mask when the
rightmost '0's are removed.

    input:    128 bit netmask
    returns true if there are spurious
            zero bits remaining in the
            mask, false if the mask is
            contiguous one's,
        128 bit cidr number

=back

=head2 Decimal strings

=over 4

=item $bcdtext = bin2bcd($bits128);

Convert a 128 bit binary string into binary coded decimal text digits.

  input:    128 bit string variable
  returns:  string of bcd text digits

=item $bits128 = bcd2bin($bcdtxt);

Convert a bcd text string to 128 bit string variable

  input:    string of bcd text digits
  returns:  128 bit string variable

=cut

#=item $onescomp=NetAddr::IP::Util::comp128($bits128);
#
#This function is not exported because it is more efficient to use perl " ~ "
#on the bit string directly. This interface to the B<C> routine is published for
#module testing purposes because it is used internally in the B<sub128> routine. The
#function is very fast, but calling if from perl directly is very slow. It is almost
#33% faster to use B<sub128> than to do a 1's comp with perl and then call
#B<add128>.
#
#=item $bcdpacked = NetAddr::IP::Util::bin2bcdn($bits128);
#
#Convert a 128 bit binary string into binary coded decimal digits.
#This function is not exported.
#
#  input:    128 bit string variable
#  returns:    string of packed decimal digits
#
#  i.e.    text = unpack("H*", $bcd);
#
#=item $bcdtext =  NetAddr::IP::Util::bcdn2txt($bcdpacked);
#
#Convert a packed bcd string into text digits, suppress the leading zeros.
#This function is not exported.
#
#  input:    string of packed decimal digits
#  returns:    hexadecimal digits
#
#Similar to unpack("H*", $bcd);
#
#=item $bcdpacked = NetAddr::IP::Util::simple_pack($bcdtext);
#
#Convert a numeric string into a packed bcd string, left fill with zeros
#
#  input:    string of decimal digits
#  returns:    string of packed decimal digits
#
#Similar to pack("H*", $bcdtext);

=back

=head2 Resolver

=over 4

=item ($name,$aliases,$addrtype,$length,@addrs)=naip_gethostbyname(NAME);

Replacement for Perl's gethostbyname if Socket6 is available

In ARRAY context, returns a list of five elements, the hostname or NAME,
a space separated list of C_NAMES, AF family, length of the address
structure, and an array of one or more netaddr's

In SCALAR context, returns the first netaddr.

This function ALWAYS returns an IPv6 address, even on IPv4 only systems.
IPv4 answers are mapped into IPv6 space in the RFC 4291 s2.5.5.2 form:

  ::FFFF:d.d.d.d

so an answer for 127.0.0.1 is C<0:0:0:0:0:FFFF:7F00:1>.

This is NOT the expected result from Perl's gethostbyname2. It is instead equivalent to:

  On an IPv4 only system:
    $ipv6naddr = inet_4map6 scalar ( gethostbyname( name ));

  On a system with Socket6 and a working gethostbyname2:
    $ipv6naddr = gethostbyname2( name, AF_INET6 );
  and if that fails, the IPv4 conversion above.

For a gethostbyname2 emulator that behave like Socket6, see: L<Net::DNS::Dig>

=item $trueif = havegethostbyname2();

This function returns TRUE if Socket6 has a functioning B<gethostbyname2>,
otherwise it returns FALSE. See the comments above about the behavior of
B<naip_gethostbyname>.

=back

=head2 Build mode

=over 4

=item $modetext = mode;

Returns the operating mode of this module.

    input:     none
    returns:  "Pure Perl"
           or "CC XS"

=back


=head1 EXAMPLES

The four subs below are the ones this distribution used to carry as
examples.  Every one of them runs as written; the results are comments.

Convert any text address and mask into a 128 bit vector, extending a 32
bit mask over the IPv6 side:

  use NetAddr::IP::Util qw(ipv6_aton inet_any2n hasbits ipv6_n2x);

  sub text2vec {
      my ($anyIP, $anyMask) = @_;

  # not IPv4 bit mask
      my $notiv4 = ipv6_aton('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF::');

      my $vecip = inet_any2n($anyIP);
      my $mask  = inet_any2n($anyMask);
      my $bits  = 128;              # default
      unless (hasbits($mask & $notiv4)) {
          $mask |= $notiv4;
          $bits  = 32;
      }
      return ($vecip, $mask, $bits);
  }

  my ($addr, $mask, $bits) = text2vec('192.0.2.9', '255.255.255.0');
  print ipv6_n2x($addr), "\n";         # 0:0:0:0:0:0:C000:209
  print ipv6_n2x($mask), "\n";         # FFFF:...:FF00, all 128 bits
  print "$bits\n";                     # 32

  my ($a6, $m6, $b6) = text2vec('2001:db8::1', 'ffff:ffff:ffff:ffff::');
  print "$b6\n";                       # 128

The same thing keyed off C<isIPv4> instead of C<hasbits>, which is a
little faster and needs no mask constant:

  my $bits = 128;
  if (isIPv4($mask)) {
      $mask |= $notiv4;
      $bits  = 32;
  }

Network and broadcast addresses from a vector.  Note the C<$bcast>
name, which was C<$broadcast> in the original and never declared:

  use NetAddr::IP ();
  use NetAddr::IP::Util qw(ipv6_n2d);

  sub netbroad {
      my ($nip) = @_;
      my $notmask = ~ $nip->{mask};
      my $bcast   = $nip->{addr} | $notmask;
      my $network = $nip->{addr} & $nip->{mask};
      return ($network, $bcast);
  }

  my $nip = NetAddr::IP->new('192.0.2.9/24');
  print ipv6_n2d((netbroad($nip))[0]), "\n";    # 0:0:0:0:0:0:192.0.2.0
  print ipv6_n2d((netbroad($nip))[1]), "\n";    # 0:0:0:0:0:0:192.0.2.255

Whether one address falls inside a net, using C<sub128>, whose carry is
C<NOT borrow>:

  use NetAddr::IP::Util qw(sub128);

  sub within {
      my ($nip, $net) = @_;
      my $addr = $nip->{addr};             # a semicolon, which was missing
      my ($nw, $bc) = netbroad($net);
      return (sub128($addr, $nw) && sub128($bc, $addr)) ? 1 : 0;
  }

  my $other = NetAddr::IP->new('198.51.100.1/24');
  print within($nip, $nip), "\n";            # 1
  print within($other, $nip), "\n";          # 0

C<addconst> stores the carry in scalar context and C<($carry, $result)>
in list context, so wrapping a net at a boundary means taking the second
element.  The original example assigned the scalar form to C<$addr>,
which quietly stored the carry:

  use NetAddr::IP::Util qw(addconst);
  use NetAddr::IP ();

  my $ip = NetAddr::IP->new('192.0.2.127/26');
  my $nextnet = 64;                           # one /26 step

  my $before = $ip->copy;                     # a new object, same address
  $ip++;
  if ($ip < $before) {                        # host part wrapped
      (undef, $ip->{addr}) = addconst($ip->{addr}, $nextnet);
  }

  print "$ip\n";                              # 192.0.2.128/26

The test hands both objects to the overloaded C<< < >>, which compares
the addresses as 128 bit numbers.  Comparing their string forms instead
gives wrong answers, because text order is not address order.  As text,
192.0.2.10 sorts before 192.0.2.9, and the wrap from 192.0.2.11 back to
192.0.2.8 sorts after.  Stepping a /30 from 192.0.2.8 passes both points:

  my $ip = NetAddr::IP->new('192.0.2.8/30');
  for my $step (0 .. 3) {
      my $before = $ip->copy;
      $ip++;
      printf "step %d: %-16s wrapped: %d\n", $step, "$ip",
          ($ip < $before ? 1 : 0);
  }
  # step 0: 192.0.2.9/30     wrapped: 0
  # step 1: 192.0.2.10/30    wrapped: 0
  # step 2: 192.0.2.11/30    wrapped: 0
  # step 3: 192.0.2.8/30     wrapped: 1

=head1 EXPORTS

Nothing is exported by default.  Use explicit import tags:

  use NetAddr::IP::Util qw(:all);
  use NetAddr::IP::Util qw(:math);

The tags are:

=over 4

=item C<:all>

Everything in L</"EXPORT_OK">.

=item C<:inet>

Nineteen names: the text and binary conversions, the family tests, the
widening helpers and the resolver.

  inet_aton inet_ntoa ipv6_aton ipv6_ntoa ipv6_n2x ipv6_n2d
  inet_any2n inet_n2dx inet_n2ad inet_pton inet_ntop inet_4map6
  ipv4to6 mask4to6 ipanyto6 maskanyto6 ipv6to4
  packzeros naip_gethostbyname

=item C<:ipv4>

Two names:

  inet_aton inet_ntoa

=item C<:ipv6>

Sixteen names.  This is C<:inet> without C<inet_aton> and
C<inet_ntoa>:

  ipv6_aton ipv6_ntoa ipv6_n2x ipv6_n2d inet_any2n
  inet_n2dx inet_n2ad inet_pton inet_ntop
  ipv4to6 mask4to6 ipanyto6 maskanyto6 ipv6to4
  packzeros naip_gethostbyname

=item C<:math>

Eleven names:

  hasbits isIPv4 isNewIPv4 isAnyIPv4 addconst add128 sub128
  notcontiguous bin2bcd bcd2bin shiftleft

=back

=head1 EXPORT_OK

The functions this module can export.  The first group is the documented
API; the last five are helpers for the test suite, exported so that
C<UtilPP> and the XS build can be compared against each other, and not
stable API.

  inet_aton         inet_ntoa          ipv6_aton          ipv6_ntoa
  ipv6_n2x          ipv6_n2d           inet_any2n         inet_n2dx
  inet_n2ad         inet_pton          inet_ntop          inet_4map6
  shiftleft         addconst           add128             sub128
  notcontiguous     bin2bcd            bcd2bin            mode
  ipv4to6           mask4to6           ipanyto6           maskanyto6
  ipv6to4           packzeros          naip_gethostbyname
  havegethostbyname2
  AF_INET           AF_INET6

Test helpers, not API:

  bin2bcdn          bcdn2txt           bcdn2bin           simple_pack
  comp128

C<bin2bcd> returns text digits and C<simple_pack> turns text digits into
a packed string, padding to C<$MAX_BCD_DIGITS> first.  C<bcdn2txt> is the
inverse of the packing and C<bcdn2bin> turns it back to 128 bits.
C<comp128> exists because Perl's C<~> is faster than calling into the XS
routine for a one's complement, so it is published only for testing.

=head1 IMPORT TAGS THAT CHANGE BEHAVIOUR

Two tags change what the module does rather than which names it exports.

=over 4

=item C<:noSock6>

Forces C<naip_gethostbyname> to report that Socket6 is unavailable, so
the resolver fallback can be tested on a host that has it.  Test hook,
not API.

=item C<:upper> and C<:lower>

These are in L<NetAddr::IP::InetBase>, and see the note there: the case
setting is one package global, so importing either affects every user of
the module in the process. C<:upper> wins if both are given, whichever
order they are in.

=back

=head1 ADDITIONAL LICENSE

This file is also available to redistribute it and/or modify it under
the terms of the "Artistic License" which comes with this distribution,
in the file named "Artistic".

=head1 SEE ALSO

L<NetAddr::IP>, L<NetAddr::IP::Lite>, L<NetAddr::IP::InetBase>

=cut

1;
