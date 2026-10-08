#!/bin/false
# ABSTRACT: IPv4 and IPv6 address parsing and formatting utilities
# PODNAME: NetAddr::IP::InetBase

use strict;
use warnings;

package NetAddr::IP::InetBase;
# VERSION

use parent 'Exporter';
use NetAddr::IP::Constants qw(
        $IPV6_BITS
        $MAX_OCTET
        $OCTET_BITS
        $V4_PACKED_BYTES
        $V6_PACKED_BYTES
);

our @EXPORT_OK = qw(
        inet_aton
        inet_ntoa
        ipv6_aton
        ipv6_ntoa
        ipv6_n2x
        ipv6_n2d
        inet_any2n
        inet_n2dx
        inet_n2ad
        inet_ntop
        inet_pton
        packzeros
        isIPv4
        isNewIPv4
        isAnyIPv4
        AF_INET
        AF_INET6
        fake_AF_INET6
        fillIPv4
);
our %EXPORT_TAGS = (
        all     => [@EXPORT_OK],
        ipv4    => [qw(
                inet_aton
                inet_ntoa
                fillIPv4
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
                packzeros
        )],
);
our $Mode;

# prototypes
sub inet_ntoa;
sub ipv6_aton;
sub ipv6_ntoa;
sub inet_any2n($);
sub inet_n2dx($);
sub inet_n2ad($);
sub _inet_ntop;
sub _inet_pton;

my $emulateAF_INET6 = 0;

{ no warnings 'once';

*packzeros = \&_packzeros;

## dynamic configuraton for IPv6

require Socket;

*AF_INET = \&Socket::AF_INET;

if (eval { local $SIG{__DIE__}; AF_INET6() } ) {
    *AF_INET6 = \&Socket::AF_INET6;
    $emulateAF_INET6 = -1;            # have it, remind below
}
if (eval{ local $SIG{__DIE__}; require Socket6 } ) {
    import Socket6 qw(
        inet_pton
        inet_ntop
    );
    unless ($emulateAF_INET6) {
        *AF_INET6 = \&Socket6::AF_INET6;
    }
    $emulateAF_INET6 = 0;                # clear, have it from elsewhere or here
}
else {
    unless ($emulateAF_INET6) {    # unlikely at this point
        if ($^O =~ /(?:free|dragon.+)bsd/i) {    # FreeBSD, DragonFlyBSD
            $emulateAF_INET6 = 28;
        }
        elsif ($^O =~ /bsd/i) {        # other BSD flavors like NetBDS, OpenBSD, BSD
            $emulateAF_INET6 = 24;
        }
        elsif ($^O =~ /(?:darwin|mac)/i) {    # Mac OS X
            $emulateAF_INET6 = 30;
        }
        elsif ($^O =~ /win/i) {        # Windows
            $emulateAF_INET6 = 23;
        }
        elsif ($^O =~ /(?:solaris|sun)/i) {        # Sun box
            $emulateAF_INET6 = 26;
        }
        else {                    # use linux default
            $emulateAF_INET6 = 10;
        }
        *AF_INET6 = sub { $emulateAF_INET6; };
    }
    else {
        $emulateAF_INET6 = 0;            # clear, have it from elsewhere
    }
      # Without Socket6 these give hex for IPv4-embedded addresses where libc
      # gives mixed notation (GH#99), and accept IPv4 short forms and names.
      *inet_pton = \&_inet_pton;
      *inet_ntop = \&_inet_ntop;
}

} # end no warnings 'once'

sub fake_AF_INET6 {
    return $emulateAF_INET6;
}

# allow user to choose upper or lower case
our ($n2x_format, $n2d_format);
BEGIN {
    $n2x_format = "%x:%x:%x:%x:%x:%x:%x:%x";
    $n2d_format = "%x:%x:%x:%x:%x:%x:%d.%d.%d.%d";
}

my $case = 0;    # default lower case

sub upper { $n2x_format = uc($n2x_format); $n2d_format = uc($n2d_format); $case = 1; }
sub lower { $n2x_format = lc($n2x_format); $n2d_format = lc($n2d_format); $case = 0; }

sub ipv6_n2x {
    die sprintf('Bad arg length for \'ipv6_n2x\', length is %d should be %d', length($_[0]), $V6_PACKED_BYTES)
        unless length($_[0]) == $V6_PACKED_BYTES;
    return sprintf($n2x_format,unpack("n8", $_[0]));
}

sub ipv6_n2d {
    die sprintf('Bad arg length for \'ipv6_n2d\', length is %d should be %d', length($_[0]), $V6_PACKED_BYTES)
        unless length($_[0]) == $V6_PACKED_BYTES;
    my @hex = (unpack("n8", $_[0]));
    $hex[9] = $hex[7] & $MAX_OCTET;
    $hex[8] = $hex[7] >> $OCTET_BITS;
    $hex[7] = $hex[6] & $MAX_OCTET;
    $hex[6] >>= $OCTET_BITS;
    return sprintf($n2d_format, @hex);
}

# if Socket lib is broken in some way, check for overange values
#

sub fillIPv4 {
    my $host = $_[0];
    return undef unless defined $host;
    if ($host =~ /^([0-9]+)(?:|\.([0-9]+)(?:|\.([0-9]+)(?:|\.([0-9]+))))$/) {
        if (defined $4) {
            return undef unless
                $1 >= 0 && $1 < 256 &&
                $2 >= 0 && $2 < 256 &&
                $3 >= 0 && $3 < 256 &&
                $4 >= 0 && $4 < 256;
            $host = $1.'.'.$2.'.'.$3.'.'.$4;
        }
        elsif (defined $3) {
            return undef unless
                $1 >= 0 && $1 < 256 &&
                $2 >= 0 && $2 < 256 &&
                $3 >= 0 && $3 < 256;
            $host = $1.'.'.$2.'.0.'.$3
        }
        elsif (defined $2) {
            return undef unless
                $1 >= 0 && $1 < 256 &&
                $2 >= 0 && $2 < 256;
            $host = $1.'.0.0.'.$2;
        }
        else {
            $host = '0.0.0.'.$1;
        }
    }
    $host;
}

sub inet_aton {
    my $host = fillIPv4($_[0]);
    return $host ? scalar gethostbyname($host) : undef;
}

my $_zero = pack('L4', 0, 0, 0, 0);
my $_ipv4mask = pack('L4', 0xffffffff, 0xffffffff, 0xffffffff, 0);

sub isIPv4 {
    if (length($_[0]) != $V6_PACKED_BYTES) {
        my $sub = (caller(1))[3] || (caller(0))[3];
        die "Bad arg length for $sub, length is ". (length($_[0]) * $OCTET_BITS) .", should be $IPV6_BITS";
    }
    return ($_[0] & $_ipv4mask) eq $_zero
        ? 1 : 0;
}

my $_newV4compat = pack('N4', 0, 0, 0xffff, 0);

sub isNewIPv4 {
    my $naddr = $_[0] ^ $_newV4compat;
    return isIPv4($naddr);
}

sub isAnyIPv4 {
    my $naddr = $_[0];
    my $rv = isIPv4($_[0]);
    return $rv if $rv;
    return isNewIPv4($naddr);
}

sub DESTROY {};

sub import {
    if (grep { $_ eq ':upper' } @_) {
        upper();
        @_ = grep { $_ ne ':upper' } @_;
    }
    NetAddr::IP::InetBase->export_to_level(1, @_);
}

1;

=head1 SYNOPSIS

  use NetAddr::IP::InetBase qw(fillIPv4 inet_any2n inet_aton inet_n2dx
      inet_ntoa ipv6_aton ipv6_n2x);

  my $packed = inet_aton('192.0.2.1');
  print length($packed), "\n";                      # 4
  print inet_ntoa($packed), "\n";                   # 192.0.2.1
  print ipv6_n2x(ipv6_aton('2001:db8::1')), "\n";   # 2001:db8:0:0:0:0:0:1
  print inet_n2dx(inet_any2n('192.0.2.1')), "\n";   # 192.0.2.1
  print fillIPv4('192.0.2'), "\n";                  # 192.0.0.2

  NetAddr::IP::InetBase::lower();            # case, see IMPORT TAGS
  NetAddr::IP::InetBase::upper();

=head1 DESCRIPTION

B<NetAddr::IP::InetBase> is the pure Perl layer that converts IPv4 and
IPv6 addresses between binary and text.  Everything here is pure Perl on
every host.  B<NetAddr::IP::Util> and the XS build take these functions
from it rather than reimplementing them, except that C<inet_pton>,
C<inet_ntop> and C<AF_INET6> come from Socket6 when it is installed.
See L</"Socket6 substitution">.

The IPv6 functions accept every text form in RFC 4291 s2.2:

  x:x:x:x:x:x:x:x
  x:x:x:x:x:x:d.d.d.d
  ::x:x:x
  ::x:d.d.d.d
  ::ffff:d.d.d.d

Text that is not an address is not an error.  Four functions,
C<inet_aton>, C<ipv6_aton>, C<inet_any2n> and C<inet_pton>, return undef
for it.  A binary argument of the wrong length is an error, and each
entry below says which functions croak on one.

=head1 FUNCTIONS

=head2 Text to binary

=over 4

=item $netaddr = inet_aton($dotquad);

Convert a dot-quad IP address into an IPv4 packed network address.

  input:    IP address i.e. 192.0.2.1
  returns:  packed network address, or undef

Short forms follow the BSD C<inet_aton> convention, not RFC 791:
C<127.1> is 127.0.0.1 and C<192.0.2> is 192.0.0.2.  Other text goes to
C<gethostbyname>, so a host name is resolved.  Returns undef for an
octet above 255 and for text that does not resolve.

=item $bits128 = ipv6_aton($ipv6_text);

Takes an IPv6 address in any of the RFC 4291 s2.2 text forms and returns
a 128 bit binary RDATA string.  Returns undef if the text is not a valid
address.

  input:    ipv6 text
  returns:  128 bit RDATA string, or undef

=cut

sub ipv6_aton {
    my ($ipv6) = @_;
    return undef unless $ipv6;
    local($1, $2, $3, $4, $5);
    if ($ipv6 =~ /^(.*:)([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$/) {    # mixed hex, dot-quad
        return undef if $2 > $MAX_OCTET || $3 > $MAX_OCTET || $4 > $MAX_OCTET || $5 > $MAX_OCTET;
        $ipv6 = sprintf("%s%X%02X:%X%02X", $1, $2, $3, $4, $5);            # convert to pure hex
    }
    my $c;
    return undef if
        $ipv6 =~ /[^:0-9a-fA-F]/ ||            # non-hex character
        (($c = $ipv6) =~ s/::/x/ && $c =~ /(?:x|:):/) ||    # double :: ::?
        $ipv6 =~ /[0-9a-fA-F]{5,}/ ||            # more than 4 digits
        $ipv6 =~ /^:(?!:)/ ||                # single leading colon
        $ipv6 =~ /(?<!:):$/;                # single trailing colon
    $c = $ipv6 =~ tr/:/:/;                # count the colons
    return undef if $c < 7 && $ipv6 !~ /::/;
    if ($c > 7) {                        # strip leading or trailing ::
        return undef unless
        $ipv6 =~ s/^::/:/ ||
        $ipv6 =~ s/::$/:/;
        return undef if --$c > 7;
    }
    while ($c++ < 7) {                    # expand compressed fields
        $ipv6 =~ s/::/:::/;
    }
    $ipv6 .= 0 if $ipv6 =~ /:$/;
    my @hex = split(/:/, $ipv6);
    return undef if @hex > 8;                # too many fields
    foreach(0..$#hex) {
        $hex[$_] = hex($hex[$_] || 0);
    }
    pack("n8", @hex);
}

=item $ipv6naddr = inet_any2n($dotquad or $ipv6_text);

This function converts a text IPv4 or IPv6 address in text format in any
standard notation into a 128 bit IPv6 string address. It prefixes any
dot-quad address (if found) with '::' and passes it to B<ipv6_aton>.

  input:    dot-quad or RFC 4291 s2.2 address
  returns:  128 bit IPv6 string, or undef

Returns undef if the text is not an address.  An empty or undefined
argument is read as C<::>, the all-zero address.

=cut

sub inet_any2n($) {
    my ($addr) = @_;
    $addr = '' unless $addr;
    $addr = '::' . $addr
        unless $addr =~ /:/;
    return ipv6_aton($addr);
}

=item $netaddr = inet_pton($AF_family,$text_addr);

This function takes an IP address in IPv4 or IPv6 text format and converts it into
binary format. The type of IP address conversion is controlled by the FAMILY
argument.

Returns undef for text that is not an address of that family, and croaks
on a family other than C<AF_INET> and C<AF_INET6>.

NOTE: inet_pton, inet_ntop and AF_INET6 come from the Socket6 library if it
is present on this host.  The two sources differ on IPv4 text: without
Socket6, C<inet_pton(AF_INET, ...)> is C<inet_aton> and also takes short
forms such as C<127.1> and host names, which Socket6 rejects.

=cut

sub _inet_pton {
    my ($af, $ip) = @_;
    die 'Bad address family for '. __PACKAGE__ ."::inet_pton, got $af"
        unless $af == AF_INET6() || $af == AF_INET();
    if ($af == AF_INET()) {
        inet_aton($ip);
    }
    else {
        ipv6_aton($ip);
    }
}

=back

=head2 Binary to text

=over 4

=item $dotquad = inet_ntoa($netaddr);

Convert a packed IPv4 network address to a dot-quad IP address.

  input:    packed network address
  returns:  IP address i.e. 192.0.2.1

Croaks if the argument is not 4 bytes.

=cut

sub inet_ntoa {
    my $packed = $_[0];
    die 'Bad arg length for '. __PACKAGE__ ."::inet_ntoa, length is ".
        (defined $packed ? length($packed) : 'undefined') .
        " should be $V4_PACKED_BYTES"
                unless defined $packed && length($packed) == $V4_PACKED_BYTES;
    my @hex = (unpack("n2", $packed));
    $hex[3] = $hex[1] & $MAX_OCTET;
    $hex[2] = $hex[1] >> $OCTET_BITS;
    $hex[1] = $hex[0] & $MAX_OCTET;
    $hex[0] >>= $OCTET_BITS;
    return sprintf("%d.%d.%d.%d", @hex);
}

=item $ipv6text = ipv6_ntoa($ipv6naddr);

Convert a 128 bit binary IPv6 address to the compressed RFC 5952 s4
text representation.

  input:    128 bit RDATA string
  returns:  ipv6 text

This is inet_ntop(AF_INET6,$ipv6naddr), so for an address with an IPv4
address embedded in the low 32 bits the text depends on whether Socket6
is installed. See the notes on inet_ntop below.

No method of NetAddr::IP or NetAddr::IP::Lite calls this function.
Stringification goes through ipv6_n2x, which is pure Perl on every host,
so the difference only reaches callers of this function.

=cut

sub ipv6_ntoa {
    die 'Bad arg length for '. __PACKAGE__ ."::ipv6_ntoa, length is undefined should be $V6_PACKED_BYTES"
                unless defined $_[0];
    return inet_ntop(AF_INET6(), $_[0]);
}

=item $hex_text = ipv6_n2x($bits128);

Takes an IPv6 RDATA string and returns an 8 segment IPv6 hex address

  input:    128 bit RDATA string
  returns:  x:x:x:x:x:x:x:x

  Note: this function does NOT compress adjacent
  strings of 0:0:0:0 into the :: format

=item $dec_text = ipv6_n2d($bits128);

Takes an IPv6 RDATA string and returns a mixed hex - decimal IPv6 address
with the 6 uppermost chunks in hex and the lower 32 bits in dot-quad
representation.

  input:    128 bit RDATA string
  returns:  x:x:x:x:x:x:d.d.d.d

  Note: this function does NOT compress adjacent
  strings of 0:0:0:0 into the :: format

=item $dotquad or $hex_text = inet_n2dx($ipv6naddr);

This function B<does the right thing> and returns the text for either a
dot-quad IPv4 or a hex notation IPv6 address.

  input:    128 bit IPv6 string
  returns:  ddd.ddd.ddd.ddd
        or  x:x:x:x:x:x:x:x

  Note: this function does NOT compress adjacent
  strings of 0:0:0:0 into the :: format

Croaks if the argument is not 16 bytes.

=cut

sub inet_n2dx($) {
    my ($nadr) = @_;
    if (isAnyIPv4($nadr)) {
        local $1;
        ipv6_n2d($nadr) =~ /([^:]+)$/;
        return $1;
    }
    return ipv6_n2x($nadr);
}

=item $dotquad or $dec_text = inet_n2ad($ipv6naddr);

This function B<does the right thing> and returns the text for either a
dot-quad IPv4 or a hex::decimal notation IPv6 address.

  input:    128 bit IPv6 string
  returns:  ddd.ddd.ddd.ddd
        or  x:x:x:x:x:x:ddd.ddd.ddd.ddd

  Note: this function does NOT compress adjacent
  strings of 0:0:0:0 into the :: format

Croaks if the argument is not 16 bytes.

=cut

sub inet_n2ad($) {
    my ($nadr) = @_;
    my $addr = ipv6_n2d($nadr);
    return $addr unless isAnyIPv4($nadr);
    local $1;
    $addr =~ /([^:]+)$/;
    return $1;
}

=item $text_addr = inet_ntop($AF_family,$netaddr);

This function takes an IP address in binary format and converts it into
text format. The type of IP address conversion is controlled by the FAMILY
argument.

NOTE: inet_ntop ALWAYS returns lowercase characters.

NOTE: inet_pton, inet_ntop and AF_INET6 come from the Socket6 library if it
is present on this host.

The two sources disagree on the text for an address with an IPv4 address
embedded in the low 32 bits, so for those addresses the output depends on
whether Socket6 is installed:

  address           with Socket6      without Socket6
  ::ffff:192.0.2.1  ::ffff:192.0.2.1 ::ffff:c000:201
  ::ffff:0:0        ::ffff:0.0.0.0   ::ffff:0:0
  ::192.0.2.1       ::192.0.2.1      ::c000:201

The difference is confined to the mapped prefix ::ffff:0:0/96 and the
deprecated compatible prefix ::/96. Everything else agrees, including zero
run compression, which of two equal runs is shortened, a single zero group,
leading zeros and case. Socket6 is a recommendation, not a requirement, so
the choice is made by what happens to be installed.

=cut

sub _inet_ntop {
    my ($af, $naddr) = @_;
    die 'Unsupported address family for '. __PACKAGE__ ."::inet_ntop, af is $af"
        unless $af == AF_INET6() || $af == AF_INET();
    if ($af == AF_INET()) {
        inet_ntoa($naddr);
    }
    else {
        return ($case)
        ? lc packzeros(ipv6_n2x($naddr))
        : _packzeros(ipv6_n2x($naddr));
    }
}

=item $hex_text = packzeros($hex_text);

This function optimizes and rfc 1884 IPv6 hex address to reduce the number of
long strings of zero bits as specified in rfc 1884, 2.2 (2) by substituting
B<::> for the first occurrence of the longest string of zeros in the address.

=cut

sub _packzeros {
    my $x6 = shift;
    if ($x6 =~ /\:\:/) {                # already contains ::
        # then re-optimize
        $x6 = ($x6 =~ /\:[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)    # ipv4 notation ?
        ? ipv6_n2d(ipv6_aton($x6))
        : ipv6_n2x(ipv6_aton($x6));
    }
    $x6 = ':'. lc $x6;                # prefix : & always lower case
    my $d = '';
    if ($x6 =~ /(.+\:)([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/) {    # if contains dot quad
        $x6 = $1;                    # save hex piece
        $d = $2;                    # and dot quad piece
    }
    $x6 .= ':';                    # suffix :
    $x6 =~ s/\:0+/\:0/g;                # compress strings of 0's to single '0'
    $x6 =~ s/\:0([1-9a-f]+)/\:$1/g;        # eliminate leading 0's in hex strings
    my @x = $x6 =~ /(?:\:0)*/g;            # split only strings of :0:0..."

    my $m = 0;
    my $i = 0;

    for (0..$#x) {                # find next longest pattern :0:0:0...
        my $len = length($x[$_]);
        next unless $len > $m;
        $m = $len;
        $i = $_;                    # index to first longest pattern
    }

    if ($m > 2) {                    # there was a string of 2 or more zeros
        $x6 =~ s/$x[$i]/\:/;              # replace first longest :0:0:0... with "::"
        unless ($i) {                # if it is the first match, $i = 0
            $x6 = substr($x6, 0,-1);            # keep the leading ::, remove trailing ':'
        }
        else {
            $x6 = substr($x6, 1,-1);            # else remove leading & trailing ':'
        }
        $x6 .= ':' unless $x6 =~ /\:\:/;        # restore ':' if match and we can't see it, implies trailing '::'
    }
    else {                    # there was no match
        $x6 = substr($x6, 1,-1);            # remove leading & trailing ':'
    }
    $x6 .= $d;                    # append digits if any
    return $case
        ? uc $x6
        : $x6;
}

=back

=head2 Family tests

=over 4

=item $rv = isIPv4($bits128);

This function returns true if there are no on bits present in the IPv6
portion of the 128 bit string and false otherwise.

  i.e.    the address must be of the form - ::d.d.d.d

which is the RFC 4291 s2.5.5.1 IPv4-compatible prefix C<::/96>, deprecated
by that RFC.

Croaks if the argument is not 16 bytes.  The message names the sub that
called C<isIPv4>, not C<isIPv4> itself, unless the call is made from file
scope.

=item $rv = isNewIPv4($bits128);

This function returns true if the 128 bit string is an IPv4-mapped
address, of the form

  ::ffff:d.d.d.d

which is the RFC 4291 s2.5.5.2 prefix C<::ffff:0:0/96>.

Returns false for an argument shorter than 16 bytes and croaks for a
longer one.

=item $rv = isAnyIPv4($bits128);

This function returns true if the 128 bit string has an IPv4 address in
the low 32 bits, of either form

  ::d.d.d.d    or    ::ffff:d.d.d.d

which is the union of the RFC 4291 s2.5.5.1 compatible prefix and the
s2.5.5.2 mapped prefix.  Croaks if the argument is not 16 bytes.

=back

=head2 Address family

=over 4

=item $constant = AF_INET;

Returns the system value for AF_INET, taken from Socket.

=item $constant = AF_INET6;

Returns the value for AF_INET6.  It comes from Socket6 when Socket6 is
installed.  Without Socket6 it is a value guessed from the name of the
operating system, which is 10 on Linux.

  use NetAddr::IP::InetBase qw(AF_INET AF_INET6);
  print AF_INET(), ' ', AF_INET6(), "\n";   # 2 10 on Linux

NOTE: inet_pton, inet_ntop and AF_INET6 come from the Socket6 library if it
is present on this host.

=item $trueif = fake_AF_INET6;

Returns false when Socket6 is installed.  Without Socket6 it returns the
guessed value that C<AF_INET6> also returns, 10 on Linux, even where the
Socket module has its own AF_INET6.

=back

=head2 Short IPv4 text

=over 4

=item $ip_filled = fillIPv4($shortIP);

Expands a short IPv4 text address to the four part form, padding the
missing octets with zeros.  This is the BSD C<inet_aton> convention and
is not RFC 791.

  input:    short or full IPv4 text
  returns:  the four part form, or undef

  print fillIPv4('192.0.2.1'), "\n";   # 192.0.2.1
  print fillIPv4('192.0.2'),   "\n";   # 192.0.0.2
  print fillIPv4('192.0'),     "\n";   # 192.0.0.0
  print fillIPv4('10'),        "\n";   # 0.0.0.10

An argument that does not look like a short or full IPv4 address is
returned unchanged, so a hostname passes straight through, and an octet
out of range gives undef:

  print fillIPv4('example.com'), "\n"; # example.com
  print defined(fillIPv4('256.1.1.1')) ? 'defined' : 'undef', "\n";   # undef

The argument is text, not a packed address.  A packed string does not
match, so it is returned unchanged too.

=back

=head2 Case

=over 4

=item NetAddr::IP::InetBase::lower();

Return IPv6 strings in lowercase.  This is the default only when
NetAddr::IP::InetBase is loaded on its own. NetAddr::IP::Util loads this
module with the :upper tag, so a program that loads NetAddr::IP::Util,
NetAddr::IP::Lite or NetAddr::IP gets uppercase output unless it imports
:lower.

=item NetAddr::IP::InetBase::upper();

Return IPv6 strings in uppercase.

The case setting is one package-wide variable. Calling lower() or upper(),
or importing :lower or :upper from any of the modules named above, changes
the output for every user of these modules in the running program, not
only the caller. The last call wins.

The default may be set to uppercase when the module is loaded by invoking
the TAG :upper. i.e.

=back

=head1 EXPORTS

Nothing is exported by default.

=head1 EXPORT_OK

  inet_aton     inet_ntoa      ipv6_aton      ipv6_ntoa
  ipv6_n2x      ipv6_n2d       inet_any2n     inet_n2dx
  inet_n2ad     inet_pton      inet_ntop      packzeros
  isIPv4        isNewIPv4      isAnyIPv4      AF_INET
  AF_INET6      fake_AF_INET6  fillIPv4

=head1 IMPORT TAGS

=over 4

=item C<:all>

Every name in L</EXPORT_OK>.

=item C<:ipv4>

  inet_aton inet_ntoa fillIPv4

=item C<:ipv6>

  ipv6_aton ipv6_ntoa ipv6_n2x ipv6_n2d
  inet_any2n inet_n2dx inet_n2ad
  inet_pton inet_ntop packzeros

=item C<:upper>

The case tag.  See below.

=back

=head1 THE CASE POLICY

The case of IPv6 text output is one package global, not a setting per
object or per module, so it applies to every user of the library in the
process.  Two consequences worth stating plainly.

This module defaults to lowercase:

  use NetAddr::IP::InetBase qw(ipv6_aton ipv6_n2x);
  my $bits128 = ipv6_aton('2001:db8::1');
  print ipv6_n2x($bits128);          # 2001:db8:0:0:0:0:0:1

Importing C<:upper> switches it, either here or on import of
B<NetAddr::IP::Util>, B<NetAddr::IP::Lite> or B<NetAddr::IP>, since
B<NetAddr::IP::Util> imports C<:upper> on your behalf:

  use NetAddr::IP::InetBase qw(:upper ipv6_aton ipv6_n2x);
  my $bits128 = ipv6_aton('2001:db8::1');
  print ipv6_n2x($bits128);          # 2001:DB8:0:0:0:0:0:1

And once set, an unrelated package importing C<:lower> changes it back for
everyone:

  use NetAddr::IP;
  package Other;
  use NetAddr::IP::Lite qw(:lower);
  package main;
  print NetAddr::IP->new('2001:db8::1')->addr, "\n";   # 2001:db8:0:0:0:0:0:1

Whether uppercase or lowercase should be the default, and whether the
setting should be process-wide at all, is an open question: see GH#7.

Two functions ignore the setting entirely and are always lowercase, since
they mirror the platform's C<inet_ntop>: C<ipv6_ntoa> and
C<inet_ntop>.  Which of them you get depends on Socket6: see below.

=head1 Socket6 substitution

C<inet_pton>, C<inet_ntop> and C<AF_INET6> are bound to Socket6 when it is
installed, and to this module's own implementations when it is not.  The
choice is made at load time, so two hosts differing only in that one
optional module can behave differently.

Socket6 is a runtime recommendation, not a requirement.  Where the
substitution matters for output it is noted on the entry: for C<inet_ntop>
and C<ipv6_ntoa>, an address with an IPv4 address in the low 32 bits is
rendered in mixed notation with Socket6 and in hex without it.  The parse
side agrees on IPv6 text and differs on IPv4 text: without Socket6,
C<inet_pton(AF_INET, ...)> is C<inet_aton>, so it takes short forms such
as C<127.1> and host names, which Socket6 rejects.

When Socket6 is not installed, C<AF_INET6> is a value guessed from the
name of the operating system, and C<fake_AF_INET6()> returns that same
value, which is true:

  print AF_INET6();          # a platform constant, or 10 here
  print fake_AF_INET6();     # true when emulated

=head1 ADDITIONAL LICENSE

This file is also available to redistribute it and/or modify it under
the terms of the "Artistic License" which comes with this distribution,
in the file named "Artistic".

=head1 SEE ALSO

L<NetAddr::IP>, L<NetAddr::IP::Lite>, L<NetAddr::IP::Util>

=cut

1;
