#!/bin/false
# ABSTRACT: Manages IPv4 and IPv6 addresses and subnets
# PODNAME: NetAddr::IP

use strict;
use warnings;

package NetAddr::IP;
# VERSION

#use diagnostics;
use Carp;
use NetAddr::IP::Lite qw(Zero Zeros Ones V4mask V4net);
use NetAddr::IP::Util qw(
	sub128
	inet_aton
	inet_any2n
	ipv6_aton
	isIPv4
	ipv4to6
	mask4to6
	shiftleft
	addconst
	hasbits
	notcontiguous
);

use AutoLoader qw(AUTOLOAD);

use vars qw(
	@EXPORT_OK
	@EXPORT_FAIL
	@ISA
	$_netlimit
);
require Exporter;

@EXPORT_OK = qw(Compact Coalesce Zero Zeros Ones V4mask V4net netlimit);
@EXPORT_FAIL = qw($_netlimit);

@ISA = qw(Exporter NetAddr::IP::Lite);


=encoding UTF-8

=head1 SYNOPSIS

  use NetAddr::IP qw(
	Compact
	Coalesce
	Zeros
	Ones
	V4mask
	V4net
	netlimit
	:aton		DEPRECATED
	:lower
	:upper
	:old_storable
	:old_nth
	:rfc3021	DEPRECATED
	:nofqdn
  );

  NOTE: NetAddr::IP::Util has a full complement of network address
	utilities to convert back and forth between binary and text.

	inet_aton, inet_ntoa, ipv6_aton, ipv6_ntoa
	ipv6_n2x, ipv6_n2d inet_any2d, inet_n2dx,
	inet_n2ad, inetanyto6, ipv6to4

See L<NetAddr::IP::Util>


  my $ip = NetAddr::IP->new('127.0.0.1');
	or from a packed IPv4 address
  my $ip = NetAddr::IP->new_from_aton(inet_aton('127.0.0.1'));
	or from an octal filtered IPv4 address
  my $ip = NetAddr::IP->new_no('127.012.0.0');

  print "The address is ", $ip->addr, " with mask ", $ip->mask, "\n" ;

  if ($ip->within(NetAddr::IP->new("203.0.113.0", "255.255.255.224"))) {
      print "Is a loopback address\n";
  }

				# This prints 127.0.0.1/32
  print "You can also say $ip...\n";

* The following four functions return ipV6 representations of:

  ::                                       = Zeros();
  FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF  = Ones();
  FFFF:FFFF:FFFF:FFFF:FFFF:FFFF::          = V4mask();
  ::FFFF:FFFF                              = V4net();

  Will also return an ipV4 or ipV6 representation of a
  resolvable Fully Qualified Domanin Name (FQDN).

###### DEPRECATED, will be remove in version 5 ############

  * To accept addresses in the format as returned by
  inet_aton, invoke the module as:

  use NetAddr::IP qw(:aton);

###### USE new_from_aton instead ##########################

* To enable usage of legacy data files containing NetAddr::IP
objects stored using the L<Storable> module.

  use NetAddr::IP qw(:old_storable);

* To compact many smaller subnets (see: C<$me-E<gt>compact($addr1,$addr2,...)>

  @compacted_object_list = Compact(@object_list)

* Return a reference to list of C<NetAddr::IP> subnets of
C<$masklen> mask length, when C<$number> or more addresses from
C<@list_of_subnets> are found to be contained in said subnet.

  $arrayref = Coalesce($masklen, $number, @list_of_subnets)

* By default B<NetAddr::IP> functions and methods return string IPv6
addresses in uppercase.  To change that to lowercase:

NOTE: the AUGUST 2010 RFC5952 states:

    4.3. Lowercase

      The characters "a", "b", "c", "d", "e", and "f" in an IPv6
      address MUST be represented in lowercase.

It is recommended that all NEW applications using NetAddr::IP be
invoked as shown on the next line.

  use NetAddr::IP qw(:lower);

* To ensure the current IPv6 string case behavior even if the default changes:

  use NetAddr::IP qw(:upper);

* To set a limit on the size of B<nets> processed or returned by NetAddr::IP.

Set the maximum number of nets beyond which NetAddr::IP will return
an error as a power of 2 (default 16 or 65536 nets). Each 2**16
consumes approximately 4 megs of memory. A 2**20 consumes 64 megs of
memory, A 2**24 consumes 1 gigabyte of memory.

  use NetAddr::IP qw(netlimit);
  netlimit 20;

The maximum B<netlimit> allowed is 2**24. Attempts to set limits below
the default of 16 or above the maximum of 24 are ignored.

Returns true on success, otherwise C<undef>.

=cut

$_netlimit = 2 ** 16;			# default

sub netlimit($) {
  return undef unless $_[0];
  return undef if $_[0] =~ /[^0-9]/;
  return undef if $_[0] < 16;
  return undef if $_[0] > 24;
  $_netlimit = 2 ** $_[0];
};

=head1 INSTALLATION

Un-tar the distribution in an appropriate directory and type:

	perl Makefile.PL
	make
	make test
	make install

B<NetAddr::IP> depends on B<NetAddr::IP::Util> which installs by
default with its primary functions compiled using Perl's XS extensions
to build a C library. If you do not have a C compiler available or
would like the slower Pure Perl version for some other reason, then
type:

	perl Makefile.PL -noxs
	make
	make test
	make install

=head1 DESCRIPTION

This module provides an object-oriented abstraction on top of IP
addresses or IP subnets that allows for easy manipulations.  Version
4.xx of NetAddr::IP will work with older versions of Perl and is
compatible with Math::BigInt.

The internal representation of all IP objects is in 128 bit IPv6 notation.
IPv4 and IPv6 objects may be freely mixed.

=head2 Overloaded Operators

Many operators have been overloaded, as described below:

=cut

				#############################################
				# These are the overload methods, placed here
				# for convenience.
				#############################################

use overload

    '@{}'	=> sub {
	return [ $_[0]->hostenum ];
    };


=over

=item B<Assignment (C<=>)>

Has been optimized to copy one NetAddr::IP object to another very quickly.

=item B<C<-E<gt>copy()>>

The B<assignment (C<=>)> operation is only put in to operation when the
copied object is further mutated by another overloaded operation. See
L<overload> B<SPECIAL SYMBOLS FOR "use overload"> for details.

B<C<-E<gt>copy()>> actually creates a new object when called.

=item B<Stringification>

An object can be used just as a string. For instance, the following code

	my $ip = NetAddr::IP->new('192.0.2.123');
	print "$ip\n";

Will print the string 192.0.2.123/32.

=item B<Equality>

You can test for equality with either C<eq> or C<==>. C<eq> allows
comparison with arbitrary strings as well as NetAddr::IP objects. The
following example:

    if (NetAddr::IP->new('198.51.100.1','255.255.255.224') eq '198.51.100.1/27')
       { print "Yes\n"; }

will print out "Yes".

Comparison with C<==> requires both operands to be NetAddr::IP objects.

In both cases, a true value is returned if the CIDR representation of
the operands is equal.

=item B<Comparison via E<gt>, E<lt>, E<gt>=, E<lt>=, E<lt>=E<gt> and C<cmp>>

Internally, all network objects are represented in 128 bit format.
The numeric representation of the network is compared through the
corresponding operation. Comparisons are tried first on the address portion
of the object and if that is equal then the NUMERIC cidr portion of the
masks are compared. This leads to the counterintuitive result that

	/24 > /16

Comparison should not be done on netaddr objects with different CIDR as
this may produce indeterminate - unexpected results,
rather the determination of which netblock is larger or smaller should be
done by comparing

	$ip1->masklen <=> $ip2->masklen

=item B<Addition of a constant (C<+>)>

Add a signed integer constant to the address part of a NetAddr object.
This operation changes the address part to point so many hosts above the
current objects start address. For instance, this code:

    print NetAddr::IP->new('198.51.100.1/24') + 255;

will output 198.51.100.0/24. The address will wrap around at the broadcast
back to the network address. This code:

    print NetAddr::IP->new('203.0.113.1/24') + 255;

    outputs 203.0.113.0/24.

Returns a copy of the object when the constant is missing or zero. The
constant must be an integer with a magnitude below 2**64; anything else
croaks. Values above 2**53 must be passed as integers (IV or UV), since a
floating point value that large has no unit precision and is rejected.

=item B<Subtraction of a constant (C<->)>

The complement of the addition of a constant.

The object must be the left operand. Subtracting an object from a
constant (C<10 - $ip>) has no meaning and croaks.

=item B<Difference (C<->)>

Returns the difference between the address parts of two NetAddr::IP
objects address parts as a 32 bit signed number.

Returns B<undef> if the difference is out of range.

(See range restrictions on Addition above)

=item B<Auto-increment>

Auto-incrementing a NetAddr::IP object causes the address part to be
adjusted to the next host address within the subnet. It will wrap at
the broadcast address and start again from the network address.

=item B<Auto-decrement>

Auto-decrementing a NetAddr::IP object performs exactly the opposite
of auto-incrementing it, as you would expect.

=cut

				#############################################
				# End of the overload methods.
				#############################################


# Preloaded methods go here.


=back

=head2 Serializing and Deserializing

This module defines hooks to collaborate with L<Storable> for
serializing C<NetAddr::IP> objects, through compact and human readable
strings. You can revert to the old format by invoking this module as

  use NetAddr::IP ':old_storable';

You must do this if you have legacy data files containing NetAddr::IP
objects stored using the L<Storable> module.

=cut

my $full_format = "%04X:%04X:%04X:%04X:%04X:%04X:%D.%D.%D.%D";
my $full6_format = "%04X:%04X:%04X:%04X:%04X:%04X:%04X:%04X";

sub import
{
    if (grep { $_ eq ':old_storable' } @_) {
	@_ = grep { $_ ne ':old_storable' } @_;
    } else {
	*{STORABLE_freeze} = sub
	{
	    my $self = shift;
	    return $self->cidr();	# use stringification
	};
	*{STORABLE_thaw} = sub
	{
        my ($self, undef, $serial) = @_;

	    my $ip = NetAddr::IP->new($serial);
	    $self->{addr} = $ip->{addr};
	    $self->{mask} = $ip->{mask};
	    $self->{isv6} = $ip->{isv6};
	    return;
	};
    }

    if (grep { $_ eq ':aton' } @_)
    {
	$NetAddr::IP::Lite::Accept_Binary_IP = 1;
	@_ = grep { $_ ne ':aton' } @_;
    }
    if (grep { $_ eq ':old_nth' } @_)
    {
	$NetAddr::IP::Lite::Old_nth = 1;
	@_ = grep { $_ ne ':old_nth' } @_;
    }
    if (grep { $_ eq ':nofqdn'} @_)
    {
	$NetAddr::IP::Lite::NoFQDN = 1;
	@_ = grep { $_ ne ':nofqdn' } @_;
    }
    if (grep { $_ eq ':lower' } @_)
    {
        $full_format = lc($full_format);
        $full6_format = lc($full6_format);
        NetAddr::IP::Util::lower();
	@_ = grep { $_ ne ':lower' } @_;
    }
    if (grep { $_ eq ':upper' } @_)
    {
        $full_format = uc($full_format);
        $full6_format = uc($full6_format);
        NetAddr::IP::Util::upper();
	@_ = grep { $_ ne ':upper' } @_;
    }
    if (grep { $_ eq ':rfc3021' } @_)
    {
	warnings::warnif('deprecated',
	    ':rfc3021 is deprecated and no longer needed; hostenum now returns two hosts for /31 and /127 unconditionally');
	@_ = grep { $_ ne ':rfc3021' } @_;
    }
    NetAddr::IP->export_to_level(1, @_);
}

sub compact {
    return (ref $_[0] eq 'ARRAY')
	? compactref($_[0])	# Compact(\@list)
	: @{compactref(\@_)};	# Compact(@list)  or ->compact(@list)
}

*Compact = \&compact;

sub Coalesce {
  return &coalesce;
}

sub hostenumref($) {
  my $r = _splitref(0,$_[0]);
# a /32 or /128 is one host, a /31 or /127 is two (RFC 3021), matching
# first, last, nth and num in NetAddr::IP::Lite
  unless ((notcontiguous($_[0]->{mask}))[1] >= 127) {
    splice(@$r, 0, 1);
    splice(@$r, scalar @$r - 1, 1);
  }
  return $r;
}

sub splitref {
  unshift @_, 0;	# mark as no reverse
# perl 5.8.4 fails with this operation. see perl bug [ 23429]
#  goto &_splitref;
  &_splitref;
}

sub rsplitref {
  unshift @_, 1;	# mark as reversed
# perl 5.8.4 fails with this operation. see perl bug [ 23429]
#  goto &_splitref;
  &_splitref;
}

sub split {
  unshift @_, 0;	# mark as no reverse
  my $rv = &_splitref;
  return $rv ? @$rv : ();
}

sub rsplit {
  unshift @_, 1;	# mark as reversed
  my $rv = &_splitref;
  return $rv ? @$rv : ();
}

sub full($) {
  if (! $_[0]->{isv6} && isIPv4($_[0]->{addr})) {
    my @hex = (unpack("n8",$_[0]->{addr}));
    $hex[9] = $hex[7] & 0xff;
    $hex[8] = $hex[7] >> 8;
    $hex[7] = $hex[6] & 0xff;
    $hex[6] >>= 8;
    return sprintf($full_format,@hex);
  } else {
    &full6;
  }
}

sub full6($) {
  my @hex = (unpack("n8",$_[0]->{addr}));
  return sprintf($full6_format,@hex);
}

sub full6m($) {
  my @hex = (unpack("n8",$_[0]->{mask}));
  return sprintf($full6_format,@hex);
}

sub DESTROY {};

1;
__END__

sub do_prefix ($$$) {
    my $mask	= shift;
    my $faddr	= shift;
    my $laddr	= shift;

    if ($mask > 24) {
	return "$faddr->[0].$faddr->[1].$faddr->[2].$faddr->[3]-$laddr->[3]";
    }
    elsif ($mask == 24) {
	return "$faddr->[0].$faddr->[1].$faddr->[2].";
    }
    elsif ($mask > 16) {
	return "$faddr->[0].$faddr->[1].$faddr->[2]-$laddr->[2].";
    }
    elsif ($mask == 16) {
	return "$faddr->[0].$faddr->[1].";
    }
    elsif ($mask > 8) {
	return "$faddr->[0].$faddr->[1]-$laddr->[1].";
    }
    elsif ($mask == 8) {
	return "$faddr->[0].";
    }
    else {
	return "$faddr->[0]-$laddr->[0]";
    }
}


=head2 Methods

=over

=item C<-E<gt>new([$addr, [ $mask|IPv6 ]])>

=item C<-E<gt>new6([$addr, [ $mask]])>

=item C<-E<gt>new_no([$addr, [ $mask]])>

=item C<-E<gt>new_from_aton($netaddr)>

=item new_cis and new_cis6 are DEPRECATED

=item C<-E<gt>new_cis("$addr $mask)>

=item C<-E<gt>new_cis6("$addr $mask)>

The first two methods create a new address with the supplied address in
C<$addr> and an optional netmask C<$mask>, which can be omitted to get
a /32 or /128 netmask for IPv4 / IPv6 addresses respectively.

The third method C<new_no> is exclusively for IPv4 addresses and filters
improperly formatted
dot quad strings for leading 0's that would normally be interpreted as octal
format by NetAddr per the specifications for inet_aton.

B<new_from_aton> takes a packed IPv4 address and assumes a /32 mask. This
function replaces the DEPRECATED :aton functionality which is fundamentally
broken.

The last two methods B<new_cis> and B<new_cis6> differ from B<new> and
B<new6> only in that they except the common Cisco address notation for
address/mask pairs with a B<space> as a separator instead of a slash (/)

These methods are DEPRECATED because the functionality is now included
in the other "new" methods

  i.e.  ->new_cis('1.2.3.0 24')
        or
        ->new_cis6('::1.2.3.0 120')

C<-E<gt>new6> and
C<-E<gt>new_cis6> mark the address as being in ipV6 address space even
if the format would suggest otherwise.

  i.e.  ->new6('1.2.3.4') will result in ::102:304

  addresses submitted to ->new in ipV6 notation will
  remain in that notation permanently. i.e.
        ->new('::1.2.3.4') will result in ::102:304
  whereas new('1.2.3.4') would print out as 1.2.3.4

  See "STRINGIFICATION" below.

C<$addr> can be almost anything that can be resolved to an IP address
in all the notations I have seen over time. It can optionally contain
the mask in CIDR notation.

B<prefix> notation is understood, with the limitation that the range
specified by the prefix must match with a valid subnet.

Addresses in the same format returned by C<inet_aton> or
C<gethostbyname> can also be understood, although no mask can be
specified for them. The default is to not attempt to recognize this
format, as it seems to be seldom used.

To accept addresses in that format, invoke the module as in

  use NetAddr::IP ':aton'

If called with no arguments, 'default' is assumed. An explicit undef
argument returns undef.

If called with an empty string as the argument, returns 'undef'

C<$addr> can be any of the following and possibly more...

  n.n
  n.n/mm
  n.n.n
  n.n.n/mm
  n.n.n.n
  n.n.n.n/mm		32 bit cidr notation
  n.n.n.n/m.m.m.m
  loopback, localhost, broadcast, any, default
  x.x.x.x/host
  0xABCDEF, 0b111111000101011110, (a bcd number)
  a netaddr as returned by 'inet_aton'


Any RFC1884 notation

  ::n.n.n.n
  ::n.n.n.n/mmm		128 bit cidr notation
  ::n.n.n.n/::m.m.m.m
  ::x:x
  ::x:x/mmm
  x:x:x:x:x:x:x:x
  x:x:x:x:x:x:x:x/mmm
  x:x:x:x:x:x:x:x/m:m:m:m:m:m:m:m any RFC1884 notation
  loopback, localhost, unspecified, any, default
  ::x:x/host
  0xABCDEF, 0b111111000101011110 within the limits
  of perl's number resolution
  123456789012  a 'big' bcd number (bigger than perl likes)
  and Math::BigInt

A Fully Qualified Domain Name which returns an ipV4 address or an ipV6
address, embodied in that order. This previously undocumented feature
may be disabled with:

	use NetAddr::IP::Lite ':nofqdn';

If called with no arguments, 'default' is assumed. An explicit undef
argument returns undef.

If called with an empty string as the argument, returns 'undef'

=item C<-E<gt>broadcast()>

Returns a new object referring to the broadcast address of a given
subnet. The broadcast address has all ones in all the bit positions
where the netmask has zero bits. This is normally used to address all
the hosts in a given subnet.

=item C<-E<gt>network()>

Returns a new object referring to the network address of a given
subnet. A network address has all zero bits where the bits of the
netmask are zero. Normally this is used to refer to a subnet.

=item C<-E<gt>addr()>

Returns a scalar with the address part of the object as an IPv4 or IPv6 text
string as appropriate. This is useful for printing or for passing the
address part of the NetAddr::IP object to other components that expect an IP
address. If the object is an ipV6 address or was created using ->new6($ip)
it will be reported in ipV6 hex format otherwise it will be reported in dot
quad format only if it resides in ipV4 address space.

=item C<-E<gt>mask()>

Returns a scalar with the mask as an IPv4 or IPv6 text string as
described above.

=item C<-E<gt>masklen()>

Returns a scalar the number of one bits in the mask.

=item C<-E<gt>bits()>

Returns the width of the address in bits. Normally 32 for v4 and 128 for v6.

=item C<-E<gt>version()>

Returns the version of the address or subnet. Currently this can be
either 4 or 6.

=item C<-E<gt>cidr()>

Returns a scalar with the address and mask in CIDR notation. A
NetAddr::IP object I<stringifies> to the result of this function.
(see comments about ->new6() and ->addr() for output formats)

=item C<-E<gt>aton()>

Returns the address part of the NetAddr::IP object in the same format
as the C<inet_aton()> or C<ipv6_aton> function respectively. If the object
was created using ->new6($ip), the address returned will always be in ipV6
format, even for addresses in ipV4 address space.

=item C<-E<gt>range()>

Returns a scalar with the base address and the broadcast address
separated by a dash and spaces. This is called range notation.

=item C<-E<gt>prefix()>

Returns a scalar with the address and mask in ipV4 prefix
representation. This is useful for some programs, which expect its
input to be in this format. This method will include the broadcast
address in the encoding.

=cut

# only applicable to ipV4
sub prefix($) {
    return undef if $_[0]->{isv6};
    my $mask = (notcontiguous($_[0]->{mask}))[1];
    return $_[0]->addr if $mask == 128;
    $mask -= 96;
    my @faddr = split (/\./, $_[0]->first->addr);
    my @laddr = split (/\./, $_[0]->broadcast->addr);
    return do_prefix $mask, \@faddr, \@laddr;
}

=item C<-E<gt>nprefix()>

Just as C<-E<gt>prefix()>, but does not include the broadcast address.

=cut

# only applicable to ipV4
sub nprefix($) {
    return undef if $_[0]->{isv6};
    my $mask = (notcontiguous($_[0]->{mask}))[1];
    return $_[0]->addr if $mask == 128;
    $mask -= 96;
    my @faddr = split (/\./, $_[0]->first->addr);
    my @laddr = split (/\./, $_[0]->last->addr);
    return do_prefix $mask, \@faddr, \@laddr;
}


=item C<-E<gt>numeric()>

When called in a scalar context, will return a numeric representation
of the address part of the IP address. When called in an array
contest, it returns a list of two elements. The first element is as
described, the second element is the numeric representation of the
netmask.

This method is essential for serializing the representation of a
subnet.

=item C<-E<gt>bigint()>

When called in scalar context, will return a Math::BigInt
representation of the address part of the IP address. When called in
an array context, it returns a list of two elements, The first
element is as described, the second element is the Math::BigInt
representation of the netmask.

=item C<-E<gt>wildcard()>

When called in a scalar context, returns the wildcard bits
corresponding to the mask, in dotted-quad or ipV6 format as applicable.

When called in an array context, returns a two-element array. The
first element, is the address part. The second element, is the
wildcard translation of the mask.

=cut

sub wildcard($) {
  my $copy = $_[0]->copy;
  $copy->{addr} = ~ $copy->{mask};
  $copy->{addr} &= V4net unless $copy->{isv6};
  if (wantarray) {
    return ($_[0]->addr, $copy->addr);
  }
  return $copy->addr;
}


=item C<-E<gt>short()>

Returns the address part in a short or compact notation.

  (ie, 10.0.0.1 becomes 10.1).

Works with both, V4 and V6.

=cut

# thanks to Rob Riepel <riepel@networking.Stanford.EDU>
# for this faster and more compact solution 11-17-08
sub _compV6 ($) {
    my $ip = shift;
    return $ip unless my @candidates = $ip =~ /((?:^|:)0(?::0)+(?::|$))/g;
    my $longest = (sort { ($b =~ tr/0//) <=> ($a =~ tr/0//) } @candidates)[0];
    $ip =~ s/$longest/::/;
    return $ip;
}

sub short($) {
  my $addr = $_[0]->addr;
  if (! $_[0]->{isv6} && isIPv4($_[0]->{addr})) {
    my @o = split(/\./, $addr, 4);
    splice(@o, 1, 2) if $o[1] == 0 and $o[2] == 0;
    return join '.', @o;
  }
  return _compV6($addr);
}

=item C<-E<gt>canon()>

Returns the address part in canonical notation as a string.  For
ipV4, this is dotted quad, and is the same as the return value from
"->addr()".  For ipV6 it is as per RFC5952, and is the same as the LOWER CASE value
returned by "->short()".

=cut

sub canon($) {
  my $addr = $_[0]->addr;
  return $_[0]->{isv6} ? lc _compV6($addr) : $addr;
}

=item C<-E<gt>full()>

Returns the address part in FULL notation for
ipV4 and ipV6 respectively.

  i.e. for ipV4
    0000:0000:0000:0000:0000:0000:127.0.0.1

       for ipV6
    0000:0000:0000:0000:0000:0000:0000:0000

To force ipV4 addresses into full ipV6 format use:

=item C<-E<gt>full6()>

Returns the address part in FULL ipV6 notation

=item C<-E<gt>full6m()>

Returns the mask part in FULL ipV6 notation

=item C<$me-E<gt>contains($other)>

Returns true when C<$me> completely contains C<$other>. False is
returned otherwise and C<undef> is returned if C<$me> and C<$other>
are not both C<NetAddr::IP> objects.

=item C<$me-E<gt>within($other)>

The complement of C<-E<gt>contains()>. Returns true when C<$me> is
completely contained within C<$other>, undef if C<$me> and C<$other>
are not both C<NetAddr::IP> objects.

An IPv4 object and an IPv6 object never contain each other, even when
the IPv6 address is the IPv4 address in C<::a.b.c.d> or C<::ffff:a.b.c.d>
form.

=item C-E<gt>is_rfc1918()>

Returns true when C<$me> is an RFC 1918 address.

  10.0.0.0      -   10.255.255.255  (10/8 prefix)
  172.16.0.0    -   172.31.255.255  (172.16/12 prefix)
  192.168.0.0   -   192.168.255.255 (192.168/16 prefix)

=item C<-E<gt>is_local()>

Returns true when C<$me> is a local network address.

        i.e.    ipV4    127.0.0.0 - 127.255.255.255
  or            ipV6    === ::1

=item C<-E<gt>splitref($bits,[optional $bits1,$bits2,...])>

Returns a reference to a list of objects, representing subnets of C<bits> mask
produced by splitting the original object, which is left
unchanged. Note that C<$bits> must be longer than the original
mask in order for it to be splittable.

ERROR conditions:

  ->splitref will DIE with the message 'netlimit exceeded'
    if the number of return objects exceeds 'netlimit'.
    See function 'netlimit' above (default 2**16 or 65536 nets).

  ->splitref returns undef when C<bits> or the (bits list)
    will not fit within the original object.

  ->splitref returns undef if a supplied ipV4, ipV6, or NetAddr
    mask in inappropriately formatted,

B<bits> may be a CIDR mask, a dot quad or ipV6 string or a NetAddr::IP object.
If C<bits> is missing, the object is split for into all available addresses
within the ipV4 or ipV6 object ( auto-mask of CIDR 32, 128 respectively ).

With optional additional C<bits> list, the original object is split into
parts sized based on the list. NOTE: a short list will replicate the last
item. If the last item is too large to for what remains of the object after
splitting off the first parts of the list, a "best fits" list of remaining
objects will be returned based on an increasing sort of the CIDR values of
the C<bits> list.

  i.e.	my $ip = NetAddr::IP->new('192.0.2.0/24');
	my $objptr = $ip->split(28, 29, 28, 29, 26);

   has split plan 28 29 28 29 26 26 26 28
   and returns this list of objects

	192.0.2.0/28
	192.0.2.16/29
	192.0.2.24/28
	192.0.2.40/29
	192.0.2.48/26
	192.0.2.112/26
	192.0.2.176/26
	192.0.2.240/28

NOTE: that /26 replicates twice beyond the original request and /28 fills
the remaining return object requirement.

=item C<-E<gt>rsplitref($bits,[optional $bits1,$bits2,...])>

C<-E<gt>rsplitref> is the same as C<-E<gt>splitref> above except that the split plan is
applied to the original object in reverse order.

  i.e.	my $ip = NetAddr::IP->new('192.0.2.0/24');
	my @objects = $ip->split(28, 29, 28, 29, 26);

   has split plan 28 26 26 26 29 28 29 28
   and returns this list of objects

	192.0.2.0/28
	192.0.2.16/26
	192.0.2.80/26
	192.0.2.144/26
	192.0.2.208/29
	192.0.2.216/28
	192.0.2.232/29
	192.0.2.240/28

=item C<-E<gt>split($bits,[optional $bits1,$bits2,...])>

Similar to C<-E<gt>splitref> above but returns the list rather than a list
reference. You may not want to use this if a large number of objects is
expected.

=item C<-E<gt>rsplit($bits,[optional $bits1,$bits2,...])>

Similar to C<-E<gt>rsplitref> above but returns the list rather than a list
reference. You may not want to use this if a large number of objects is
expected.

=cut

# input:	$naip,
#		@bits,		 list of masks for splits
#
#  returns:	empty array request will not fit in submitted net
#		(\@bits,undef)	 if there is just one plan item i.e. return original net
#		(\@bits,\%masks) for a real plan
#
sub _splitplan {
  my($ip,@bits) = @_;
  my $addr = $ip->addr();
  my $isV6 = $ip->{isv6};
  unless (@bits) {
    $bits[0] = $isV6 ? 128 : 32;
  }
  my $basem = $ip->masklen();

  my(%nets,$dif);
  my $denom = 0;

  my($x,$maddr);
  foreach my $mask(@bits) {
    if (ref $mask) {	# is a NetAddr::IP
      $x = $mask->{isv6} ? $mask->{addr} : $mask->{addr} | V4mask;
      ($x,$maddr) = notcontiguous($x);
      return () if $x;	# spurious bits
      $mask = $isV6 ? $maddr : $maddr - 96;
    }
    elsif ($mask = NetAddr::IP->new($addr,$mask,$isV6)) { # will be undefined if bad mask and will fall into oops!
      $mask = $mask->masklen();
    }
    else {
      return ();	# oops!
    }
    $dif = $mask - $basem;			# for normalization
    return () if $dif < 0;		# overange nets not allowed
    return (\@bits,undef) unless ($dif || $#bits);	# return if original net = mask alone
    $denom = $dif if $dif > $denom;
    next if exists $nets{$mask};
    $nets{$mask} = $mask - $basem;		# for normalization
  }

# $denom is the normalization denominator, since these are all exponents
# normalization can use add/subtract to accomplish normalization
#
# keys of %nets are the masks used by this split
# values of %nets are the normalized weighting for
# calculating when the split is "full" or complete
# %masks values contain the actual masks for each split subnet
# @bits contains the masks in the order the user actually wants them
#
  my %masks;					# calculate masks
  my $maskbase = $isV6 ? 128 : 32;
  foreach( keys %nets ) {
    $nets{$_} = 2 ** ($denom - $nets{$_});
    $masks{$_} = shiftleft(Ones, $maskbase - $_);
  }

  my @plan;
  my $idx = 0;
  $denom = 2 ** $denom;
  PLAN:
  while ($denom > 0) {				# make a net plan
    my $nexmask = ($idx < $#bits) ? $bits[$idx] : $bits[$#bits];
    ++$idx;
    unless (($denom -= $nets{$nexmask}) < 0) {
      croak('netlimit exceeded') if (push @plan, $nexmask) > $_netlimit;
      next;
    }
# a fractional net is needed that is not in the mask list or the replicant
    $denom += $nets{$nexmask};			# restore mistake
  TRY:
    foreach my $try_mask (sort { $a <=> $b } keys %nets) {
      next TRY if $nexmask > $try_mask;
      do {
	next TRY if $denom - $nets{$try_mask} < 0;
	croak('netlimit exceeded') if (push @plan, $try_mask) > $_netlimit;
	$denom -= $nets{$try_mask};
      } while $denom;
    }
    die 'ERROR: miscalculated weights' if $denom;
  }
  return () if $idx < @bits;			# overrange original subnet request
  return (\@plan,\%masks);
}

# input:	$rev,	# t/f
#		$naip,
#		@bits	# list of masks for split
#
sub _splitref {
  my $rev = shift;
  my($plan,$masks) = &_splitplan;
# bug report 82719
  croak("netmask error: overrange or spurious bits") unless defined $plan;
#  return undef unless $plan;
  my $net = $_[0]->network();
  return [$net] unless $masks;
  my $addr = $net->{addr};
  my $isV6 = $net->{isv6};
  my @plan = $rev ? reverse @$plan : @$plan;
# print "plan @plan\n";

# create splits
  my @ret;
  while ($_ = shift @plan) {
    my $mask = $masks->{$_};
    push @ret, $net->_new($addr,$mask,$isV6);
    last unless @plan;
    $addr = (sub128($addr,$mask))[1];
  }
  return \@ret;
}


=item C<-E<gt>hostenum()>

Returns the list of hosts within a subnet.

ERROR conditions:

  ->hostenum will DIE with the message 'netlimit exceeded'
    if the number of return objects exceeds 'netlimit'.
    See function 'netlimit' above (default 2**16 or 65536 nets).

=cut

sub hostenum ($) {
    return @{$_[0]->hostenumref};
}


=item C<-E<gt>hostenumref()>

Faster version of C<-E<gt>hostenum()>, returning a reference to a list.

NOTE: hostenum and hostenumref report two (2) useable hosts in a /31 or
/127 point-to-point network (RFC 3021), the same as C<first>, C<last>,
C<nth> and C<num>. Versions before 4.080 reported zero hosts unless the
B<:rfc3021> tag was imported. The tag is now deprecated and emits a
warning if imported; it will be removed in a future version.

	use NetAddr::IP qw(:rfc3021);	# deprecated, no longer needed

=item C<$me-E<gt>compact($addr1, $addr2, ...)>

=item C<@compacted_object_list = Compact(@object_list)>

Given a list of objects (including C<$me>), this method will compact
all the addresses and subnets into the largest (ie, least specific)
subnets possible that contain exactly all of the given objects.

Note that in versions prior to 3.02, if fed with the same IP subnets
multiple times, these subnets would be returned. From 3.02 on, a more
"correct" approach has been adopted and only one address would be
returned.

Note that C<$me> and all C<$addr>'s must be C<NetAddr::IP> objects.

IPv4 and IPv6 objects are compacted separately. The returned list holds the
IPv4 results followed by the IPv6 results. The objects passed in are not
modified; the results are new objects.

=item C<$me-E<gt>compactref(\@list)>

=item C<$compacted_object_list = Compact(\@list)>

As usual, a faster version of C<-E<gt>compact()> that returns a
reference to a list. Note that this method takes a reference to a list
instead.

Note that C<$me> must be a C<NetAddr::IP> object.

=cut

sub compactref($) {
  my $unr;

  if (UNIVERSAL::isa($_[0], __PACKAGE__) and ref $_[1] eq 'ARRAY') {
    # ->compactref(\@list)
    #
    $unr = [$_[0], @{$_[1]}]; # keeping structures intact
  }
  else {
    # Compact(@list) or ->compact(@list) or Compact(\@list)
    #
    $unr = $_[0];
  }

  return [] unless @$unr;

  # work on network copies so the caller's objects are not modified, and
  # keep the address families apart: a 128 bit mask comparison would
  # otherwise merge 0.0.0.0/24 with ::100/120
  my(@v4,@v6);
  foreach my $entry (@$unr) {
    my $net = $entry->network;
    if ($net->{isv6}) {
      push @v6, $net;
    } else {
      push @v4, $net;
    }
  }
  return [ _merge_sorted(sort @v4), _merge_sorted(sort @v6) ];
}

# input:	sorted list of network objects of one address family
# returns:	the compacted list
#
sub _merge_sorted {
  my @r = @_;
  my $changed;
  do {
    $changed = 0;
    for(my $i=0; $i <= $#r -1;$i++) {
      if ($r[$i]->contains($r[$i +1])) {
        splice(@r,$i +1,1);
        ++$changed;
        --$i;
      }
      elsif ((notcontiguous($r[$i]->{mask}))[1] == (notcontiguous($r[$i +1]->{mask}))[1]) {		# masks the same
        if (hasbits($r[$i]->{addr} ^ $r[$i +1]->{addr})) {	# if not the same netblock
          my $upnet = $r[$i]->copy;
          $upnet->{mask} = shiftleft($upnet->{mask},1);
          if ($upnet->contains($r[$i +1])) {					# adjacent nets in next net up
      $r[$i] = $upnet;
      splice(@r,$i +1,1);
      ++$changed;
      --$i;
          }
        } else {									# identical nets
          splice(@r,$i +1,1);
          ++$changed;
          --$i;
        }
      }
    }
  } while $changed;
  return @r;
}


=item C<$me-E<gt>coalesce($masklen, $number, @list_of_subnets)>

=item C<$arrayref = Coalesce($masklen,$number,@list_of_subnets)>

Will return a reference to list of C<NetAddr::IP> subnets of
C<$masklen> mask length, when C<$number> or more addresses from
C<@list_of_subnets> are found to be contained in said subnet.

Subnets from C<@list_of_subnets> with a mask shorter than C<$masklen>
are passed "as is" to the return list.

Subnets from C<@list_of_subnets> with a mask exactly equal to
C<$masklen> are passed "as is" to the return list, as their network
address. They are not counted towards C<$number>, so an equal length
subnet is returned exactly once whatever C<$number> is set to, and is
never dropped for failing to reach it.

Subnets from C<@list_of_subnets> with a mask longer than C<$masklen>
have their address count added towards C<$number>. The count is the
size of the subnet, so a /25 counts 128 and a /32 counts 1.

Called as a method, the array will include C<$me>.

The returned list is in address order.

WARNING: the list of subnet must be the same type. i.e ipV4 or ipV6

=cut

sub coalesce
{
    my $masklen	= shift;
    if (UNIVERSAL::isa($masklen, __PACKAGE__)) {		# if called as a method
      push @_,$masklen;
      $masklen = shift;
    }

    my $number	= shift;

    # Addresses are at @_
    return [] unless @_;
    my %ret = ();
    my $type = $_[0]->{isv6};
    return [] unless defined $type;

    for my $ip (@_)
    {
	return [] unless $ip->{isv6} == $type;
	$type = $ip->{isv6};
	my $n = NetAddr::IP->new($ip->addr . '/' . $masklen)->network;
	if ($ip->masklen > $masklen)
	{
	    # the size of the subnet, which is not ->num, since ->num
	    # excludes the network and broadcast addresses
	    $ret{$n} += 2 ** (($type ? 128 : 32) - $ip->masklen);
	}
    }

    my @ret = ();

    # Add to @ret any arguments with netmasks longer than our argument
    for my $c (sort { $a->masklen <=> $b->masklen }
	       grep { $_->masklen <= $masklen } @_)
    {
	next if grep { $_->contains($c) } @ret;
	push @ret, $c->network;
    }

    # Now add to @ret all the subnets with more than $number hits
    for my $c (map { NetAddr::IP->new($_) }
	       grep { $ret{$_} >= $number }
	       sort keys %ret)
    {
	next if grep { $_->contains($c) } @ret;
	push @ret, $c;
    }

    return [ sort @ret ];
}


=item C<-E<gt>first()>

Returns a new object representing the first usable IP address within
the subnet (ie, the first host address).

=item C<-E<gt>last()>

Returns a new object representing the last usable IP address within
the subnet (ie, one less than the broadcast address).

=item C<-E<gt>nth($index)>

Returns a new object representing the I<n>-th usable IP address within
the subnet (ie, the I<n>-th host address).  If no address is available
(for example, when the network is too small for C<$index> hosts),
C<undef> is returned.

Version 4.00 of NetAddr::IP and version 1.00 of NetAddr::IP::Lite implements
C<-E<gt>nth($index)> and C<-E<gt>num()> exactly as the documentation states.
Previous versions behaved slightly differently and not in a consistent
manner. See the README file for details.

To use the old behavior for C<-E<gt>nth($index)> and C<-E<gt>num()>:

  use NetAddr::IP::Lite qw(:old_nth);

  old behavior:
  NetAddr::IP->new('10/32')->nth(0) == undef
  NetAddr::IP->new('10/32')->nth(1) == undef
  NetAddr::IP->new('10/31')->nth(0) == undef
  NetAddr::IP->new('10/31')->nth(1) == 203.0.113.1/31
  NetAddr::IP->new('10/30')->nth(0) == undef
  NetAddr::IP->new('10/30')->nth(1) == 203.0.113.1/30
  NetAddr::IP->new('10/30')->nth(2) == 203.0.113.2/30
  NetAddr::IP->new('10/30')->nth(3) == 203.0.113.3/30

Note that in each case, the broadcast address is represented in the
output set and that the 'zero'th index is always undef except for
a point-to-point /31 or /127 network where there are exactly two
addresses in the network.

  new behavior:
  NetAddr::IP->new('10/32')->nth(0)  == 203.0.113.0/32
  NetAddr::IP->new('10.1/32'->nth(0) == 203.0.113.1/32
  NetAddr::IP->new('10/31')->nth(0)  == 203.0.113.0/31
  NetAddr::IP->new('10/31')->nth(1)  == 203.0.113.1/31
  NetAddr::IP->new('10/30')->nth(0) == 203.0.113.1/30
  NetAddr::IP->new('10/30')->nth(1) == 203.0.113.2/30
  NetAddr::IP->new('10/30')->nth(2) == undef

Note that a /32 net always has 1 usable address while a /31 has exactly
two usable addresses for point-to-point addressing. The first
index (0) returns the address immediately following the network address
except for a /31 or /127 when it return the network address.

=item C<-E<gt>num()>

As of version 4.42 of NetAddr::IP and version 1.27 of NetAddr::IP::Lite
a /31 and /127 with return a net B<num> value of 2 instead of 0 (zero)
for point-to-point networks.

Version 4.00 of NetAddr::IP and version 1.00 of NetAddr::IP::Lite
return the number of usable IP addresses within the subnet,
not counting the broadcast or network address.

Previous versions worked only for ipV4 addresses, returned a
maximum span of 2**32 and returned the number of IP addresses
not counting the broadcast address.
        (one greater than the new behavior)

To use the old behavior for C<-E<gt>nth($index)> and C<-E<gt>num()>:

  use NetAddr::IP::Lite qw(:old_nth);

WARNING:

NetAddr::IP will calculate and return a numeric string for network
ranges as large as 2**128. These values are TEXT strings and perl
can treat them as integers for numeric calculations.

Perl on 32 bit platforms only handles integer numbers up to 2**32
and on 64 bit platforms to 2**64.

If you wish to manipulate numeric strings returned by NetAddr::IP
that are larger than 2**32 or 2**64, respectively,  you must load
additional modules such as Math::BigInt, bignum or some similar
package to do the integer math.

=item C<-E<gt>re()>

Returns a Perl regular expression that will match an IP address within
the given subnet. Defaults to ipV4 notation. Will return an ipV6 regex
if the address in not in ipV4 space.

=cut

sub re ($)
{
    return &re6 if $_[0]->{isv6} || !isIPv4($_[0]->{addr});
    my $self = shift->network;	# Insure a "zero" host part
    my ($addr, $mlen) = ($self->addr, $self->masklen);
    my @o = split('\.', $addr, 4);

    my $octet= '(?:[0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])';
    my @r = @o;
    my $d;

#    for my $i (0 .. $#o)
#    {
#	warn "# $self: $r[$i] == $o[$i]\n";
#    }

    if ($mlen != 32)
    {
	if ($mlen > 24)
	{
	     $d	= 2 ** (32 - $mlen) - 1;
	     $r[3] = '(?:' . join('|', ($o[3]..$o[3] + $d)) . ')';
	}
	else
	{
	    $r[3] = $octet;
	    if ($mlen > 16)
	    {
		$d = 2 ** (24 - $mlen) - 1;
		$r[2] = '(?:' . join('|', ($o[2]..$o[2] + $d)) . ')';
	    }
	    else
	    {
		$r[2] = $octet;
		if ($mlen > 8)
		{
		    $d = 2 ** (16 - $mlen) - 1;
		    $r[1] = '(?:' . join('|', ($o[1]..$o[1] + $d)) . ')';
		}
		else
		{
		    $r[1] = $octet;
		    if ($mlen > 0)
		    {
			$d = 2 ** (8 - $mlen) - 1;
			$r[0] = '(?:' . join('|', ($o[0] .. $o[0] + $d)) . ')';
		    }
		    else { $r[0] = $octet; }
		}
	    }
	}
    }

    ### no digit, and no digit followed by a dot, before nor after
    ### (look-behind, look-ahead) so that an address embedded in a longer
    ### dotted string such as 1.10.1.2.3 does not match
    return "(?:(?<![0-9])(?<![0-9]\\.)$r[0]\\.$r[1]\\.$r[2]\\.$r[3](?![0-9])(?!\\.[0-9]))";
}

=item C<-E<gt>re6()>

Returns a Perl regular expression that will match an IP address within
the given subnet. Always returns an ipV6 regex.

Both C<-E<gt>re> and C<-E<gt>re6> return a non-capturing group, so that
embedding either one in a larger pattern does not change the numbering of
the caller's own capture groups. Wrap the result yourself if you want the
matched text:

  my $re = $ip->re6;
  if ($text =~ /addr=($re)\\s/) { print "matched $1\\n" }

=cut

sub re6($) {
  my @net = split('',sprintf("%04X%04X%04X%04X%04X%04X%04X%04X",unpack('n8',$_[0]->network->{addr})));
  my @brd = split('',sprintf("%04X%04X%04X%04X%04X%04X%04X%04X",unpack('n8',$_[0]->broadcast->{addr})));

  my @dig;

  foreach(0..$#net) {
    my $n = $net[$_];
    my $b = $brd[$_];
    my $m;
    if ($n.'' eq $b.'') {
      if ($n =~ /[0-9]/) {
	push @dig, $n;
      } else {
	push @dig, '['.(lc $n).$n.']';
      }
    } else {
      my $n = $net[$_];
      my $b = $brd[$_];
      if ($n.'' eq 0 && $b =~ /F/) {
	push @dig, 'x';
      }
      elsif ($n =~ /[0-9]/ && $b =~ /[0-9]/) {
	push @dig, '['.$n.'-'.$b.']';
      }
      elsif ($n =~ /[A-F]/ && $b =~ /[A-F]/) {
	$n .= '-'.$b;
	push @dig, '['.(lc $n).$n.']';
      }
      elsif ($n =~ /[0-9]/ && $b =~ /[A-F]/) {
	$m = ($n == 9) ? 9 : $n .'-9';
	if ($b =~ /A/) {
	  $m .= 'aA';
	} else {
	  $b = 'A-'. $b;
	  $m .= (lc $b). $b;
	}
	push @dig, '['.$m.']';
      }
      elsif ($n =~ /[A-F]/ && $b =~ /[0-9]/) {
	if ($n =~ /A/) {
	  $m = 'aA';
	} else {
	  $n .= '-F';
	  $m = (lc $n).$n;
	}
	if ($b == 9) {
	  $m .= 9;
	} else {
	  $m .= $b .'-9';
	}
	push @dig, '['.$m.']';
      }
    }
  }
  my @grp;
  do {
    my $grp = join('',splice(@dig,0,4));
    if ($grp =~ /^(0+)/) {
      my $l = length($1);
      if ($l == 4) {
	$grp = '0{1,4}';
      } else {
	$grp =~ s/^${1}/0\{0,$l\}/;
      }
    }
    if ($grp =~ /(x+)$/) {
      my $l = length($1);
      if ($l == 4) {
	$grp = '[0-9a-fA-F]{1,4}';
      } else {
	$grp =~ s/x+/\[0\-9a\-fA\-F\]\{$l\}/;
      }
    }
    push @grp, $grp;
  } while @dig > 0;
  return '(?:'. join(':',@grp) .')';
}

sub mod_version {
  return $NetAddr::IP::VERSION;
  &Compact;			# suppress warnings about these symbols
  &Coalesce;
  &STORABLE_freeze;
  &STORABLE_thaw;
}


=back

=head1 EXPORT_OK

	Compact
	Coalesce
	Zeros
	Ones
	V4mask
	V4net
	netlimit

=head1 NOTES / BUGS ... FEATURES

NetAddr::IP only runs in Pure Perl mode on Windows boxes because I don't
have the resources or know how to get the "configure" stuff working in the
Windows environment. Volunteers WELCOME to port the "C" portion of this
module to Windows.

=head1 HISTORY

=over 4

See the Changes file

=back

=head1 ADDITIONAL LICENSE

This file is also available to redistribute it and/or modify it under
the terms of the "Artistic License" which comes with this distribution,
in the file named "Artistic".

=cut

1;
