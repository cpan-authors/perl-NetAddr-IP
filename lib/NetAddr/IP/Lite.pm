#!/bin/false
# ABSTRACT: Manages IPv4 and IPv6 addresses and subnets (lightweight)
# PODNAME: NetAddr::IP::Lite

use strict;

package NetAddr::IP::Lite;
# VERSION

use parent 'Exporter';
use Carp qw( croak );

#use warnings;
use NetAddr::IP::Constants qw(
    $IPV6_BITS
    $IPV4_BITS
    $IPV4_OFFSET
    $V6_PACKED_BYTES
    $V4_PACKED_BYTES
);
use NetAddr::IP::InetBase qw(
    fillIPv4
    inet_any2n
    inet_aton
    inet_n2dx
    ipv6_aton
    ipv6_n2x
    isIPv4
);
use NetAddr::IP::Util qw(
    add128
    addconst
    bcd2bin
    bin2bcd
    hasbits
    havegethostbyname2
    ipv4to6
    ipv6to4
    isAnyIPv4
    mask4to6
    naip_gethostbyname
    notcontiguous
    shiftleft
    sub128
);

our @EXPORT_OK = qw(Zeros Zero Ones V4mask V4net);
our $Accept_Binary_IP = 0;
our $Old_nth = 0;
our $NoFQDN;
our $AUTOLOAD;

*Zero = \&Zeros;

=encoding UTF-8

=head1 SYNOPSIS

  use NetAddr::IP::Lite qw(
	Zeros
	Ones
	V4mask
	V4net
	:aton		DEPRECATED !
	:old_nth
	:upper
	:lower
	:nofqdn
  );

  my $ip = NetAddr::IP::Lite->new('127.0.0.1');
	or from a packed IPv4 address
  my $ip = NetAddr::IP::Lite->new_from_aton(inet_aton('127.0.0.1'));
	or from an octal filtered IPv4 address
  my $ip = NetAddr::IP::Lite->new_no('127.012.0.0');

  print "The address is ", $ip->addr, " with mask ", $ip->mask, "\n" ;

  if ($ip->within(NetAddr::IP::Lite->new("192.0.2.0", "255.255.255.224"))) {
      print "Is a loopback address\n";
  }

				# This prints 127.0.0.1/32
  print "You can also say $ip...\n";

  The following four functions return ipV6 representations of:

  ::					   = Zeros();
  FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF  = Ones();
  FFFF:FFFF:FFFF:FFFF:FFFF:FFFF::	   = V4mask();
  ::FFFF:FFFF				   = V4net();

  Will also return an ipV4 or ipV6 representation of a
  resolvable Fully Qualified Domanin Name (FQDN).

=head1 INSTALLATION

Un-tar the distribution in an appropriate directory and type:

	perl Makefile.PL
	make
	make test
	make install

B<NetAddr::IP::Lite> depends on B<NetAddr::IP::Util> which installs by default with its primary functions compiled
using Perl's XS extensions to build a 'C' library. If you do not have a 'C'
compiler available or would like the slower Pure Perl version for some other
reason, then type:

	perl Makefile.PL -noxs
	make
	make test
	make install

=head1 DESCRIPTION

This module provides an object-oriented abstraction on top of IP
addresses or IP subnets, that allows for easy manipulations. Most of the
operations of NetAddr::IP are supported. This module will work with older
versions of Perl and is compatible with Math::BigInt.

* By default B<NetAddr::IP> functions and methods return string IPv6
addresses in uppercase.  To change that to lowercase:

NOTE: the AUGUST 2010 RFC5952 states:

    4.3. Lowercase

      The characters "a", "b", "c", "d", "e", and "f" in an IPv6
      address MUST be represented in lowercase.

It is recommended that all NEW applications using NetAddr::IP::Lite be
invoked as shown on the next line.

  use NetAddr::IP::Lite qw(:lower);

* To ensure the current IPv6 string case behavior even if the default changes:

  use NetAddr::IP::Lite qw(:upper);


The internal representation of all IP objects is in 128 bit IPv6 notation.
IPv4 and IPv6 objects may be freely mixed.

The supported operations are described below:

=cut

# in the off chance that NetAddr::IP::Lite objects are created
# and the caller later loads NetAddr::IP and expects to use
# those objects, let the AUTOLOAD routine find and redirect
# NetAddr::IP::Lite method and subroutine calls to NetAddr::IP.
#

my $parent = 'NetAddr::IP';

sub DESTROY {};

sub AUTOLOAD {
  no strict;
  my ($pkg,$func) = ($AUTOLOAD =~ /(.*)::([^:]+)$/);
  my $other = $parent .'::';

  if ($pkg =~ /^$other/o && exists ${$other}{$func}) {
    $other .= $func;
    goto &{$other};
  }

  my @stack = caller(0);

  if ( $pkg eq ref $_[0] ) {
    $other = qq|Can't locate object method "$func" via|;
  }
  else {
    $other = qq|Undefined subroutine \&$AUTOLOAD not found in|;
  }
  die $other . qq| package "$parent" or "$pkg" (did you forgot to load a module?) at $stack[1] line $stack[2].\n|;
}

=head2 Overloaded Operators

=cut

# these really should be packed in Network Long order but since they are
# symmetrical, that extra internal processing can be skipped

my $_v4zero = pack('L',0);
my $_zero = pack('L4',0,0,0,0);
my $_ones = ~$_zero;
my $_v4mask = pack('L4',0xffffffff,0xffffffff,0xffffffff,0);
my $_v4net = ~ $_v4mask;
my $_ipv4FFFF = pack('N4',0,0,0xffff,0);

sub Zeros() {
  return $_zero;
}
sub Ones() {
  return $_ones;
}
sub V4mask() {
  return $_v4mask;
}
sub V4net() {
  return $_v4net;
}

				#############################################
				# These are the overload methods, placed here
				# for convenience.
				#############################################

use overload

    '+'		=> \&plus,

    '-'		=> \&minus,

    '++'	=> \&plusplus,

    '--'	=> \&minusminus,

    'neg'	=> sub {
	croak 'cannot negate a ' . ref($_[0]) . ' object';
    },

    'abs'	=> sub {
	croak 'cannot take the absolute value of a ' . ref($_[0]) . ' object';
    },

    "="		=> \&copy,

    '""'	=> sub { $_[0]->cidr(); },

    'eq'	=> sub {
	my $a = (UNIVERSAL::isa($_[0],__PACKAGE__)) ? $_[0]->cidr : $_[0];
	my $b = (UNIVERSAL::isa($_[1],__PACKAGE__)) ? $_[1]->cidr : $_[1];
	$a eq $b;
    },

    'ne'	=> sub {
	my $a = (UNIVERSAL::isa($_[0],__PACKAGE__)) ? $_[0]->cidr : $_[0];
	my $b = (UNIVERSAL::isa($_[1],__PACKAGE__)) ? $_[1]->cidr : $_[1];
	$a ne $b;
    },

    '=='	=> sub {
	return 0 unless UNIVERSAL::isa($_[0],__PACKAGE__) && UNIVERSAL::isa($_[1],__PACKAGE__);
	$_[0]->cidr eq $_[1]->cidr;
    },

    '!='	=> sub {
	return 1 unless UNIVERSAL::isa($_[0],__PACKAGE__) && UNIVERSAL::isa($_[1],__PACKAGE__);
	$_[0]->cidr ne $_[1]->cidr;
    },

    '>'		=> sub {
	return &comp_addr_mask > 0 ? 1 : 0;
    },

    '<'		=> sub {
	return &comp_addr_mask < 0 ? 1 : 0;
    },

    '>='	=> sub {
	return &comp_addr_mask < 0 ? 0 : 1;
    },

    '<='	=> sub {
	return &comp_addr_mask > 0 ? 0 : 1;
    },

    '<=>'	=> \&comp_addr_mask,

    'cmp'	=> \&comp_addr_mask;

sub comp_addr_mask {
  my($c,$rv) = sub128($_[0]->{addr},$_[1]->{addr});
  return -1 unless $c;
  return 1 if hasbits($rv);
  ($c,$rv) = sub128($_[0]->{mask},$_[1]->{mask});
  return -1 unless $c;
  return hasbits($rv) ? 1 : 0;
}

=over

=item B<Assignment (C<=>)>

Has been optimized to copy one NetAddr::IP::Lite object to another very quickly.

=item B<C<-E<gt>copy()>>

The B<assignment (C<=>)> operation is only put in to operation when the
copied object is further mutated by another overloaded operation. See
L<overload> B<SPECIAL SYMBOLS FOR "use overload"> for details.

B<C<-E<gt>copy()>> actually creates a new object when called.

=cut

sub copy {
	return _new($_[0],$_[0]->{addr}, $_[0]->{mask});
}

=item B<Stringification>

An object can be used just as a string. For instance, the following code

	my $ip = NetAddr::IP::Lite->new('192.0.2.123');
        print "$ip\n";

Will print the string 192.0.2.123/32.

	my $ip = NetAddr::IP::Lite->new6('192.0.2.123');
	print "$ip\n";

Will print the string 0:0:0:0:0:0:C000:27B/128

=item B<Equality>

You can test for equality with either C<eq>, C<ne>, C<==> or C<!=>. C<eq>, C<ne> allows the
comparison with arbitrary strings as well as NetAddr::IP::Lite objects. The
following example:

    if (NetAddr::IP::Lite->new('198.51.100.1','255.255.255.224') eq '198.51.100.1/27')
       { print "Yes\n"; }

Will print out "Yes".

Comparison with C<==> and C<!=> requires both operands to be NetAddr::IP::Lite objects.

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

    print NetAddr::IP::Lite->new('203.0.113.1/24') + 5;

will output 203.0.113.6/24. The address wraps around at the broadcast back
to the network address, so this code:

    print NetAddr::IP::Lite->new('203.0.113.1/24') + 255;

outputs 203.0.113.0/24.

Returns a copy of the object when the constant is missing or zero. The
constant must be an integer with a magnitude below 2**64; anything else
croaks. Values above 2**53 must be passed as integers (IV or UV), since a
floating point value that large has no unit precision and is rejected.

=cut

sub plus {
    my $ip	= shift;
    my $const	= shift;

    return $ip->copy unless $const;
    # integer, unit precision (rejects floats above 2**53), below 2**64
    croak 'constant must be an exact integer with magnitude below 2**64'
	unless $const == int($const)
		&& ($const > 0 ? $const - 1 != $const : $const + 1 != $const)
		&& $const <= 18446744073709551615
		&& $const >= -18446744073709551615;

    my $a = $ip->{addr};
    my $m = $ip->{mask};

    my $lo = $a & ~$m;
    my $hi = $a & $m;

    my $new;
    if ($const < 2147483648 && $const > -2147483649) {
	$new = (addconst($lo,$const))[1];
    } else {
	my $mag = _const2bin(abs($const));
	$new = ($const > 0)
		? (add128($lo,$mag))[1]
		: (sub128($lo,$mag))[1];
    }
    $new = ($new & ~$m) | $hi;

    return _new($ip,$new,$m);
}

# 128 bit string for a non-negative integer constant below 2**64.
# Bit operators give exact results on a 64 bit perl; the division
# fallback is exact up to 2**53 on a 32 bit perl.
sub _const2bin {
    my $c = shift;
    my($hi,$lo);
    if ($c <= 4294967295) {
	($hi,$lo) = (0,$c);
    } elsif (~0 > 4294967295) {
	$hi = $c >> 32;
	$lo = $c & 4294967295;
    } else {
	$hi = int($c / 4294967296);
	$lo = $c - $hi * 4294967296;
    }
    return pack('N4',0,0,$hi,$lo);
}

=item B<Subtraction of a constant (C<->)>

The complement of the addition of a constant.

The object must be the left operand. Subtracting an object from a
constant (C<10 - $ip>) has no meaning and croaks.

=item B<Difference (C<->)>

Returns the difference between the address parts of two NetAddr::IP::Lite
objects address parts as a 32 bit signed number.

Returns B<undef> if the difference is out of range.

=cut

my $_smsk = pack('L3N',0xffffffff,0xffffffff,0xffffffff,0x80000000);

sub minus {
    my $ip	= shift;
    my $arg	= shift;
    my $swapped	= shift;
    croak 'cannot subtract a NetAddr::IP::Lite object from a constant'
	if $swapped;
    unless (ref $arg) {
	return plus($ip, -$arg);
    }
    my($carry,$dif) = sub128($ip->{addr},$arg->{addr});
    if ($carry) {					# value is positive
	return undef if hasbits($dif & $_smsk);		# all sign bits should be 0's
	return (unpack('L3N',$dif))[3];
    } else {
	return undef if hasbits(($dif & $_smsk) ^ $_smsk);	# sign is 1's
	return (unpack('L3N',$dif))[3] - 4294967296;
    }
}

				# Auto-increment an object

=item B<Auto-increment>

Auto-incrementing a NetAddr::IP::Lite object causes the address part to be
adjusted to the next host address within the subnet. It will wrap at
the broadcast address and start again from the network address.

=cut

sub plusplus {
    my $ip	= shift;

    my $a = $ip->{addr};
    my $m = $ip->{mask};

    my $lo = $a & ~ $m;
    my $hi = $a & $m;

    $ip->{addr} = ((addconst($lo,1))[1] & ~ $m) | $hi;
    return $ip;
}

=item B<Auto-decrement>

Auto-decrementing a NetAddr::IP::Lite object performs exactly the opposite
of auto-incrementing it, as you would expect.

=cut

sub minusminus {
    my $ip	= shift;

    my $a = $ip->{addr};
    my $m = $ip->{mask};

    my $lo = $a & ~$m;
    my $hi = $a & $m;

    $ip->{addr} = ((addconst($lo,-1))[1] & ~$m) | $hi;
    return $ip;
}

				#############################################
				# End of the overload methods.
				#############################################

# Preloaded methods go here.

				# This is a variant to ->new() that
				# creates and blesses a new object
				# without the fancy parsing of
				# IP formats and shorthands.

# return a blessed IP object without parsing
# input:	prototype, naddr, nmask
# returns:	blessed IP object
#
sub _new ($$$) {
  my $proto = shift;
  my $class = ref($proto) || die "reference required";
  $proto = $proto->{isv6};
  my $self = {
	addr	=> $_[0],
	mask	=> $_[1],
	isv6	=> $proto,
  };
  return bless $self, $class;
}


=back

=head2 Methods

=over

=item C<-E<gt>new([$addr, [ $mask|IPv6 ]])>

=item C<-E<gt>new6([$addr, [ $mask]])>

=item C<-E<gt>new6FFFF([$addr, [ $mask]])>

=item C<-E<gt>new_no([$addr, [ $mask]])>

=item C<-E<gt>new_from_aton($netaddr)>

=item new_cis and new_cis6 are DEPRECATED

=item C<-E<gt>new_cis("$addr $mask)>

=item C<-E<gt>new_cis6("$addr $mask)>

The first three methods create a new address with the supplied address in
C<$addr> and an optional netmask C<$mask>, which can be omitted to get
a /32 or /128 netmask for IPv4 / IPv6 addresses respectively.

new6FFFF specifically returns an IPv4 address in IPv6 format according to RFC4291

  new6		     ::xxxx:xxxx
  new6FFFF	::FFFF:xxxx:xxxx

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
the mask in CIDR notation. If the OPTIONAL perl module Socket6 is
available in the local library it will autoload and ipV6 host6
names will be resolved as well as ipV4 hostnames.

B<prefix> notation is understood, with the limitation that the range
specified by the prefix must match with a valid subnet.

Addresses in the same format returned by C<inet_aton> or
C<gethostbyname> can also be understood, although no mask can be
specified for them. The default is to not attempt to recognize this
format, as it seems to be seldom used.

###### DEPRECATED, will be remove in version 5 ############
To accept addresses in that format, invoke the module as in

  use NetAddr::IP::Lite ':aton'

###### USE new_from_aton instead ##########################

If called with no arguments, 'default' is assumed. An explicit undef
argument returns undef.

If called with an empty string as the argument, returns 'undef'

C<$addr> can be any of the following and possibly more...

  n.n
  n.n/mm
  n.n mm
  n.n.n
  n.n.n/mm
  n.n.n mm
  n.n.n.n
  n.n.n.n/mm		32 bit cidr notation
  n.n.n.n mm
  n.n.n.n/m.m.m.m
  n.n.n.n m.m.m.m
  loopback, localhost, broadcast, any, default
  x.x.x.x/host
  0xABCDEF, 0b111111000101011110, (or a bcd number)
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

If called with and empty string as the argument, 'undef' is returned;

=cut

my $_p4broad	= inet_any2n('255.255.255.255');
my $_p4loop	= inet_any2n('127.0.0.1');
# a literal mask must not need a resolver: InetBase::inet_aton is a
# gethostbyname call, which fails at load time wherever the resolver cannot
# answer a dotted quad
my $_p4mloop	= mask4to6(pack('C4',255,0,0,0));
my $_p6loop	= inet_any2n('::1');

my %fip4 = (
        default         => Zeros,
        any             => Zeros,
        broadcast       => $_p4broad,
        loopback        => $_p4loop,
	unspecified	=> undef,
);
my %fip4m = (
        default         => Zeros,
        any             => Zeros,
        broadcast       => Ones,
        loopback        => $_p4mloop,
	unspecified	=> undef,	# not applicable for ipV4
	host		=> Ones,
);

my %fip6 = (
	default         => Zeros,
	any             => Zeros,
	broadcast       => undef,	# not applicable for ipV6
	loopback        => $_p6loop,
	unspecified     => Zeros,
);

my %fip6m = (
	default         => Zeros,
	any             => Zeros,
	broadcast       => undef,	# not applicable for ipV6
	loopback        => Ones,
	unspecified     => Ones,
	host		=> Ones,
);

my $ff000000 = pack('L3N',0xffffffff,0xffffffff,0xffffffff,0xFF000000);
my $ffff0000 = pack('L3N',0xffffffff,0xffffffff,0xffffffff,0xFFFF0000);
my $ffffff00 = pack('L3N',0xffffffff,0xffffffff,0xffffffff,0xFFFFFF00);

sub _obits ($$) {
    my($lo,$hi) = @_;

    return 0xFF if $lo == $hi;
    return (~ ($hi ^ $lo)) & 0xFF;
}

sub new_no($;$$) {
  unshift @_, -1;
  goto &_xnew;
}

sub new($;$$) {
  unshift @_, 0;
  goto &_xnew;
}

sub new_from_aton($$) {
  my $proto     = shift;
  my $class = ref $proto || $proto || __PACKAGE__;
  my $ip = shift;
  return undef unless defined $ip;
  my $addrlen = length($ip);
  return undef unless $addrlen == $V4_PACKED_BYTES;
  my $self = {
	addr    => ipv4to6($ip),
	mask    => &Ones,
	isv6    => 0,
  };
  return bless $self, $class;
}

sub new6($;$$) {
  unshift @_, 1;
  goto &_xnew;
}

sub new6FFFF($;$$) {
  my $ip = _xnew(1,@_);
  return undef unless defined $ip;
  $ip->{addr} |= $_ipv4FFFF;
  return $ip;
}

sub new_cis($;$$) {
  my @in = @_;
  if ( $in[1] && $in[1] =~ m!^(.+)\s+(.+)$! ) {
    $in[1] = $1 .'/'. $2;
  }
  @_ = (0,@in);
  goto &_xnew;
}

sub new_cis6($;$$) {
  my @in = @_;
  if ( $in[1] && $in[1] =~ m!^(.+)\s+(.+)$! ) {
    $in[1] = $1 .'/'. $2;
  }
  @_ = (1,@in);
  goto &_xnew;
}

sub _no_octal {
  (my $rv = $_[0]) =~ s#\b0*([1-9][0-9]*/?|0/?)#$1#g;	# suppress leading zeros
  $rv;
}

# bcd2bin croaks on input that is too long, has a non-digit, or is larger
# than 128 bits. The constructor returns undef for bad input, so map the
# croak to undef here.
#
sub _bcd2bin_or_undef {
  local ($@, $SIG{__DIE__});		# keep the croak out of the caller's error state
  return scalar eval { bcd2bin($_[0]) };
}

sub _xnew($$;$$) {
  my $noctal	= 0;
  my $isV6	= shift;
  if ($isV6 < 0) {		# flag for no octal?
    $isV6	= 0;
    $noctal	= 1;
  }
  my $proto	= shift;
  my $class	= ref $proto || $proto || __PACKAGE__;
  my $ip	= @_ ? shift : 'default';	# no argument at all means default

  if ($ip && $noctal && $ip !~ m|(?:[^\s0123456789/. -])|) {		# octal suppression required if not an IPv4 address
    $ip = _no_octal($ip);
  }

# fix for bug #75976, and an explicit undef is a missing value, not a route
  return undef unless defined $ip && $ip ne '';
  $ip = _retMBIstring($ip)		# treat as big bcd string
	if ref $ip && ref $ip eq 'Math::BigInt';	# can /CIDR notation
  my $hasmask = 1;
  my($mask,$tmp);

# IP to lower case AFTER ref test for Math::BigInt. 'lc' strips blessing

  $ip = lc $ip;

# strip surrounding whitespace so "10.0.0.1\n" and " 10.0.0.1" are treated alike.
# skipped in :aton mode because a raw 4 or 16 byte address may begin or end with a whitespace byte
  unless ($Accept_Binary_IP) {
    $ip =~ s/^\s+//;
    $ip =~ s/\s+\z//;
    return undef if $ip eq '';
    # reject non-ASCII digits (Arabic-Indic, Devanagari, Fullwidth, etc.)
    (my $ipcore = $ip) =~ s{/[^/]+$}{};
    return undef if $ipcore =~ /[^\x00-\x7F]/;
  }

  while (1) {
# process IP's with no CIDR or that have the CIDR as part of the IP argument string
    unless (@_) {
      if ($ip !~ /[^0-9]/) {		# binary number notation
	return undef unless defined ($ip = _bcd2bin_or_undef($ip));
	$mask = Ones;
	$isV6 = 1 unless isIPv4($ip);
	last;
      }
      elsif ($ip =~ m!^([a-z0-9.:-]+)(?:/|\s+)([a-z0-9.:-]+)$!) {
	$ip	= $1;
	$mask	= $2;
      }
      elsif ($ip =~ m!^\[([a-z0-9.:-]+)(?:/|\s+)([a-z0-9.:-]+)\]$! ||
	     $ip =~ m!^\[([a-z0-9.:-]+)\](?:/|\s+)([a-z0-9.:-]+)$!) {
	return undef if index($1, ':') < 0;	# RFC 3986 brackets enclose an IPv6 literal only
	$ip	= $1;
	$mask	= $2;
      } elsif (grep($ip eq $_,(qw(default any broadcast loopback unspecified)))) {
	$isV6 = 1 if $ip eq 'unspecified';
	if ($isV6) {
	  $mask = $fip6m{$ip};
	  return undef unless defined ($ip = $fip6{$ip});
	} else {
	  $mask	= $fip4m{$ip};
	  return undef unless defined ($ip = $fip4{$ip});
	}
	last;
      }
    }
# process "ipv6" token and default IP's
    elsif (defined $_[0]) {
      if ($_[0] =~ /ipv6/i || $isV6) {
	if (grep($ip eq $_,(qw(default any loopback unspecified)))) {
	  $mask	= $fip6m{$ip};
	  $ip	= $fip6{$ip};
	  last;
	} else {
	  return undef unless $isV6;
# add for ipv6 notation "12345, 1"
        }
      }
# extract mask
      $mask = $_[0];
      # an empty mask argument is a caller error, not a /0
      return undef if $mask eq '';
    }
###
### process mask
    unless (defined $mask) {
      $hasmask	= 0;
      $mask	= 'host';
    }

# two kinds of IP's can turn on the isV6 flag
# 1) big digits that are over the IPv4 boundry
# 2) IPv6 IP syntax
#
# check these conditions and set isV6 as appropriate
#
    my $try;
    $isV6 = 1 if	# check big bcd and IPv6 rfc1884
	( $ip !~ /[^0-9]/ && 				  # ip is all decimal
	  (length($ip) > 3 || $ip > 255) &&		  # exclude a single digit in the range of zero to 255, could be funny IPv4
	  ($try = _bcd2bin_or_undef($ip)) && ! isIPv4($try)) ||	  # precedence so $try is not corrupted
	(index($ip,':') >= 0 && ($try = ipv6_aton($ip))); # fails if not an rfc1884 address

# if either of the above conditions is true, $try contains the NetAddr 128 bit address

# checkfor Math::BigInt mask
    $mask = _retMBIstring($mask)				# treat as big bcd string
        if ref $mask && ref $mask eq 'Math::BigInt';

# MASK to lower case AFTER ref test for Math::BigInt, 'lc' strips blessing

    $mask = lc $mask;

    if ($mask !~ /[^0-9]/) {				# bcd or CIDR notation
      my $isCIDR = length($mask) < 4 && $mask <= $IPV6_BITS;
      if ($isV6) {
	if ($isCIDR) {
	  my($dq1,$dq2,$dq3,$dq4);
	  if ($ip =~ /^([0-9]+)(?:|\.([0-9]+)(?:|\.([0-9]+)(?:|\.([0-9]+))))$/ &&
	    do {$dq1 = $1;
		$dq2 = $2 || 0;
		$dq3 = $3 || 0;
		$dq4 = $4 || 0;
		1;
	    } &&
	    $dq1 >= 0 && $dq1 < 256 &&
	    $dq2 >= 0 && $dq2 < 256 &&
	    $dq3 >= 0 && $dq3 < 256 &&
	    $dq4 >= 0 && $dq4 < 256
	  ) {	# corner condition of IPv4 with isV6
	    $ip = join('.',$dq1,$dq2,$dq3,$dq4);
	    $try = ipv4to6(inet_aton($ip));
	    if ($mask < $IPV4_BITS) {
	      $mask = shiftleft(Ones,$IPV4_BITS -$mask);
	    }
	    elsif ($mask == $IPV4_BITS) {
	      $mask = Ones;
	    } else {
	      return undef;			# undoubtably an error
	    }
	  }
	  elsif ($mask < $IPV6_BITS) {
	    $mask = shiftleft(Ones,$IPV6_BITS -$mask);	# small cidr
	  } else {
	    $mask = Ones();
	  }
	} else {
	  return undef unless defined ($mask = _bcd2bin_or_undef($mask));
	}
      }
      elsif ($isCIDR && $mask < 33) {		# is V4
#	if ($ip && $noctal && $ip !~ m|(?:[^\s0123456789.])|) {              # octal suppression required if not an IPv4 address
#	  $mask = _no_octal($mask);
#	}
	if ($mask < $IPV4_BITS) {
	  $mask = shiftleft(Ones,$IPV4_BITS -$mask);
	}
	elsif ( $mask == $IPV4_BITS) {
	  $mask = Ones;
	} else {
	  return undef unless defined ($mask = _bcd2bin_or_undef($mask));
	  $mask |= $_v4mask;			# v4 always
	}
      } else {					# also V4
	return undef unless defined ($mask = _bcd2bin_or_undef($mask));
	$mask |= $_v4mask;
      }
      if ($try) {				# is a big number
	$ip = $try;
	last;
      }
    } elsif ($mask =~ m/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) { # ipv4 form of mask
      $mask = _no_octal($mask) if $noctal;	# filter for octal
      return undef unless defined ($mask = inet_aton($mask));
      $mask = mask4to6($mask);
    } elsif (grep($mask eq $_,qw(default any broadcast loopback unspecified host))) {
      if (index($ip,':') < 0 && ! $isV6) {
	return undef unless defined ($mask = $fip4m{$mask});
      } else {
	return undef unless defined ($mask = $fip6m{$mask});
      }
    } else {
      return undef unless defined ($mask = ipv6_aton($mask));	# try ipv6 form of mask
    }

# process remaining IP's

    if (index($ip,':') < 0) {				# ipv4 address
      if ($ip =~ m/^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/) {
	;	# the common case
      }
      elsif (grep($ip eq $_,(qw(default any broadcast loopback)))) {
	return undef unless defined ($ip = $fip4{$ip});
	last;
      }
      elsif ($ip =~ m/^([0-9]+)\.([0-9]+)$/) {
	$ip = ($hasmask)
		? "${1}.${2}.0.0"
		: "${1}.0.0.${2}";
      }
      elsif ($ip =~ m/^([0-9]+)\.([0-9]+)\.([0-9]+)$/) {
	$ip = ($hasmask)
		? "${1}.${2}.${3}.0"
		: "${1}.${2}.0.${3}";
      }
      elsif ($ip =~ /^([0-9]+)$/ && $hasmask && $1 >= 0 and $1 < 256) { # pure numeric
	$ip = sprintf("%d.0.0.0",$1);
      }
#      elsif ($ip =~ /^[0-9]+$/ && !$hasmask) {	# a big integer
      elsif ($ip =~ /^[0-9]+$/ ) {	# a big integer
	return undef unless defined ($ip = _bcd2bin_or_undef($ip));
	last;
      }
# binary and hex literals, 0b[01]+ or 0x[0-9a-f]+ ($ip is already lower case)
      elsif ($ip =~ /^(?:0b[01]+|0x[0-9a-f]+)$/ && $hasmask &&
		($tmp = oct($ip)) < 256) {
        $ip = sprintf("%d.0.0.0",$tmp);
      }
      elsif ($ip =~ /^-?[0-9]+$/) {
	# negative values in -1 .. -(2**32) are accepted as 2's complement
	$ip += 2 ** $IPV4_BITS;
	return undef if $ip < 0;		# would wrap in pack
	$ip = pack('L3N',0,0,0,$ip);
	last;
      }
      elsif ($ip =~ /^(-?)(0b[01]+|0x[0-9a-f]+)$/) {
	$ip = oct($2);
	$ip = 2 ** $IPV4_BITS - $ip if $1 && $ip;
	$ip = pack('L3N',0,0,0,$ip);
	last;
      }

#	notations below include an implicit mask specification

      elsif ($ip =~ m/^([0-9]+)\.$/) {
	$ip = "${1}.0.0.0";
	$mask = $ff000000;
      }
      elsif ($ip =~ m/^([0-9]+)\.([0-9]+)-([0-9]+)\.?$/ && $2 <= $3 && $3 < 256) {
	$ip = "${1}.${2}.0.0";
	$mask = pack('L3C4',0xffffffff,0xffffffff,0xffffffff,255,_obits($2,$3),0,0);
      }
      elsif ($ip =~ m/^([0-9]+)-([0-9]+)\.?$/ and $1 <= $2 && $2 < 256) {
	$ip = "${1}.0.0.0";
	$mask = pack('L3C4',0xffffffff,0xffffffff,0xffffffff,_obits($1,$2),0,0,0)
      }
      elsif ($ip =~ m/^([0-9]+)\.([0-9]+)\.$/) {
	$ip = "${1}.${2}.0.0";
	$mask = $ffff0000;
      }
      elsif ($ip =~ m/^([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)\.?$/ && $3 <= $4 && $4 < 256) {
	$ip = "${1}.${2}.${3}.0";
	$mask = pack('L3C4',0xffffffff,0xffffffff,0xffffffff,255,255,_obits($3,$4),0);
      }
      elsif ($ip =~ m/^([0-9]+)\.([0-9]+)\.([0-9]+)\.$/) {
	$ip = "${1}.${2}.${3}.0";
	$mask = $ffffff00;
      }
      elsif ($ip =~ m/^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)$/ && $4 <= $5 && $5 < 256) {
	$ip = "${1}.${2}.${3}.${4}";
	$mask = pack('L3C4',0xffffffff,0xffffffff,0xffffffff,255,255,255,_obits($4,$5));
      }
      elsif ($ip =~ m/^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)
		\s*-\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)$/x) {
#	if ($noctal) {
#	  return undef unless ($ip = inet_aton(_no_octal($1)));
#	  return undef unless ($tmp = inet_aton(_no_octal($2)));
#	} else {
	  return undef unless ($ip = inet_aton($1));
	  return undef unless ($tmp = inet_aton($2));
#	}
# check for left side greater than right side
# save numeric difference in $mask
	return undef if ($tmp = unpack('N',$tmp) - unpack('N',$ip)) < 0;
	$ip = ipv4to6($ip);
	$tmp = pack('L3N',0,0,0,$tmp);
	$mask = ~$tmp;
	return undef if notcontiguous($mask);
# check for non-aligned left side
	return undef if hasbits($ip & $tmp);
	last;
      }
# check for resolvable IPv6 hosts first when an IPv6 object was requested.
# naip_gethostbyname falls back to an A lookup and maps the result, so accept
# its answer only when it really is an IPv6 address, else let the IPv4 branch
# below produce the ::a.b.c.d form that new6 documents
      elsif ($isV6 && ! $NoFQDN && $ip !~ /[^a-zA-Z0-9\._-]/ && havegethostbyname2()
	     && ($tmp = naip_gethostbyname($ip)) && ! isAnyIPv4($tmp)) {
	$ip = $tmp;
	last;
      }
# check for resolvable IPv4 hosts
      elsif (! $NoFQDN && $ip !~ /[^a-zA-Z0-9\._-]/ && ($tmp = gethostbyname(fillIPv4($ip))) && $tmp ne $_v4zero && $tmp ne $_zero ) {
	$ip = ipv4to6($tmp);
	last;
      }
# check for resolvable IPv6 hosts
      elsif (! $NoFQDN && $ip !~ /[^a-zA-Z0-9\._-]/ && havegethostbyname2() && ($tmp = naip_gethostbyname($ip))) {
	$ip = $tmp;
	$isV6 = 1;
	last;
      }
      elsif ($Accept_Binary_IP && ! $hasmask) {
	if (length($ip) == $V4_PACKED_BYTES) {
	  $ip = ipv4to6($ip);
	} elsif (length($ip) == $V6_PACKED_BYTES) {
	  $isV6 = 1;
	} else {
	  return undef;
	}
	last;
      } else {
	return undef;
      }
      return undef unless defined ($ip = inet_aton($ip));
      $ip = ipv4to6($ip);
      last;
    }
########## continuing
    else {						# ipv6 address
      $isV6 = 1;
      if (index($ip,'[') >= 0 || index($ip,']') >= 0) {	# transform URI notation
	return undef unless $ip =~ /^\[([^[\]]+)\]$/;	# nothing may follow the closing bracket
	$ip = $1;
      }
      if (defined ($tmp = ipv6_aton($ip))) {
	$ip = $tmp;
	last;
      }
      last if grep($ip eq $_,(qw(default any loopback unspecified))) &&
		defined ($ip = $fip6{$ip});
      return undef;
    }
  } # end while (1)
  return undef if notcontiguous($mask);			# invalid if not contiguous

  my $self = {
	addr	=> $ip,
	mask	=> $mask,
	isv6	=> $isV6,
  };
  return bless $self, $class;
}

=item C<-E<gt>broadcast()>

Returns a new object referring to the broadcast address of a given
subnet. The broadcast address has all ones in all the bit positions
where the netmask has zero bits. This is normally used to address all
the hosts in a given subnet.

=cut

sub broadcast ($) {
  my $ip = _new($_[0],$_[0]->{addr} | ~$_[0]->{mask},$_[0]->{mask});
  $ip->{addr} &= V4net unless $ip->{isv6};
  return $ip;
}

=item C<-E<gt>network()>

Returns a new object referring to the network address of a given
subnet. A network address has all zero bits where the bits of the
netmask are zero. Normally this is used to refer to a subnet.

=cut

sub network ($) {
  return _new($_[0],$_[0]->{addr} & $_[0]->{mask},$_[0]->{mask});
}

=item C<-E<gt>addr()>

Returns a scalar with the address part of the object as an IPv4 or IPv6 text
string as appropriate. This is useful for printing or for passing the address
part of the NetAddr::IP::Lite object to other components that expect an IP
address. If the object is an ipV6 address or was created using ->new6($ip)
it will be reported in ipV6 hex format otherwise it will be reported in dot
quad format only if it resides in ipV4 address space.

=cut

sub addr ($) {
  return ($_[0]->{isv6})
	? ipv6_n2x($_[0]->{addr})
	: inet_n2dx($_[0]->{addr});
}

=item C<-E<gt>mask()>

Returns a scalar with the mask as an IPv4 or IPv6 text string as
described above.

=cut

sub mask ($) {
  return ipv6_n2x($_[0]->{mask}) if $_[0]->{isv6};
  my $mask = isIPv4($_[0]->{addr})
	? $_[0]->{mask} & V4net
	: $_[0]->{mask};
  return inet_n2dx($mask);
}

=item C<-E<gt>masklen()>

Returns a scalar the number of one bits in the mask.

=cut

sub masklen ($) {
  my $len = (notcontiguous($_[0]->{mask}))[1];
  return 0 unless $len;
  return $len if $_[0]->{isv6};
  return isIPv4($_[0]->{addr})
	? $len -$IPV4_OFFSET
	: $len;
}

=item C<-E<gt>bits()>

Returns the width of the address in bits. Normally 32 for v4 and 128 for v6.

=cut

sub bits {
  return $_[0]->{isv6} ? $IPV6_BITS : $IPV4_BITS;
}

=item C<-E<gt>version()>

Returns the version of the address or subnet. Currently this can be
either 4 or 6.

=cut

sub version {
  my $self = shift;
  return $self->{isv6} ? 6 : 4;
}

=item C<-E<gt>cidr()>

Returns a scalar with the address and mask in CIDR notation. A
NetAddr::IP::Lite object I<stringifies> to the result of this function.
(see comments about ->new6() and ->addr() for output formats)

=cut

sub cidr ($) {
  return $_[0]->addr . '/' . $_[0]->masklen;
}

=item C<-E<gt>aton()>

Returns the address part of the NetAddr::IP::Lite object in the same format
as the C<inet_aton()> or C<ipv6_aton> function respectively. If the object
was created using ->new6($ip), the address returned will always be in ipV6
format, even for addresses in ipV4 address space.

=cut

sub aton {
  return $_[0]->{addr} if $_[0]->{isv6};
  return isIPv4($_[0]->{addr})
	? ipv6to4($_[0]->{addr})
	: $_[0]->{addr};
}

=item C<-E<gt>range()>

Returns a scalar with the base address and the broadcast address
separated by a dash and spaces. This is called range notation.

=cut

sub range ($) {
  return $_[0]->network->addr . ' - ' . $_[0]->broadcast->addr;
}

=item C<-E<gt>numeric()>

When called in a scalar context, will return a numeric representation
of the address part of the IP address. When called in an array
context, it returns a list of two elements. The first element is as
described, the second element is the numeric representation of the
netmask.

This method is essential for serializing the representation of a
subnet.

=cut

sub numeric ($) {
  if (wantarray) {
    if (! $_[0]->{isv6} && isIPv4($_[0]->{addr})) {
      return (	sprintf("%u",unpack('N',ipv6to4($_[0]->{addr}))),
		sprintf("%u",unpack('N',ipv6to4($_[0]->{mask}))));
    }
    else {
      return (	bin2bcd($_[0]->{addr}),
		bin2bcd($_[0]->{mask}));
    }
  }
  return (! $_[0]->{isv6} && isIPv4($_[0]->{addr}))
    ? sprintf("%u",unpack('N',ipv6to4($_[0]->{addr})))
    : bin2bcd($_[0]->{addr});
}

=item C<-E<gt>bigint()>

When called in a scalar context, will return a Math::BigInt representation
of the address part of the IP address. When called in an array
contest, it returns a list of two elements. The first element is as
described, the second element is the Math::BigInt  representation of the
netmask.

=cut

my $biloaded;
my $bi2strng;
my $no_mbi_emu = 1;

# function to force into test development mode
#
sub _force_bi_emu {
  undef $biloaded;
  undef $bi2strng;
  $no_mbi_emu = 0;
  print STDERR "\n\n\tWARNING: test development mode, this
\tmessage SHOULD NEVER BE SEEN IN PRODUCTION!
set my \$no_mbi_emu = 1 in t/bigint.t to remove this warning\n\n";
}

# function to stringify various flavors of Math::BigInt objects
# tests to see if the object is a hash or a signed scalar

sub _bi_stfy {
  "$_[0]" =~ /([0-9]+)/;		# stringify and remove '+' if present
  $1;
}

sub _fakebi2strg {
  ${$_[0]} =~ /([0-9]+)/;
  $1;
}

# fake new from bi string Math::BigInt 0.01
#
sub _bi_fake {
  bless \('+'. $_[1]), 'Math::BigInt';
}

# as of this writing there are three known flavors of Math::BigInt
# v0.01         MBI::new returns a scalar ref
# v1.?? - 1.69  CALC::_new takes a reference to a scalar, returns an array, MBI returns a hash ref
# v1.70 and up  CALC::_new takes a scalar, returns and array, MBI returns a hash ref

sub _loadMBI {						# load Math::BigInt on demand
  if (eval { local $SIG{__DIE__}; $no_mbi_emu && require Math::BigInt}) {	# any version should work, three known
    import Math::BigInt;
    $biloaded = \&Math::BigInt::new;
    $bi2strng = \&_bi_stfy;
  } else {
    $biloaded = \&_bi_fake;
    $bi2strng = \&_fakebi2strg;
  }
}

sub _retMBIstring {
  _loadMBI unless $biloaded;				# load Math::BigInt on demand
  $bi2strng->(@_);
}

sub _biRef {
  _loadMBI unless $biloaded;				# load Math::BigInt on demand
  $biloaded->('Math::BigInt',$_[0]);
}

sub bigint($) {
  my($addr,$mask);
  if (wantarray) {
    if (! $_[0]->{isv6} && isIPv4($_[0]->{addr})) {
      $addr = $_[0]->{addr}
	? sprintf("%u",unpack('N',ipv6to4($_[0]->{addr})))
	: 0;
      $mask = $_[0]->{mask}
	? sprintf("%u",unpack('N',ipv6to4($_[0]->{mask})))
	: 0;
    }
    else {
      $addr = $_[0]->{addr}
	? bin2bcd($_[0]->{addr})
	: 0;
      $mask = $_[0]->{mask}
	? bin2bcd($_[0]->{mask})
	: 0;
    }
    (_biRef($addr),_biRef($mask));

  } else {	# not wantarray

    if (! $_[0]->{isv6} && isIPv4($_[0]->{addr})) {
      $addr = $_[0]->{addr}
	? sprintf("%u",unpack('N',ipv6to4($_[0]->{addr})))
	: 0;
    } else {
      $addr = $_[0]->{addr}
	? bin2bcd($_[0]->{addr})
	: 0;
    }
    _biRef($addr);
  }
}

=item C<$me-E<gt>contains($other)>

Returns true when C<$me> completely contains C<$other>. False is
returned otherwise and C<undef> is returned if C<$me> and C<$other>
are not both C<NetAddr::IP::Lite> objects.

=cut

sub contains ($$) {
  return within(@_[1,0]);
}

=item C<$me-E<gt>within($other)>

The complement of C<-E<gt>contains()>. Returns true when C<$me> is
completely contained within C<$other>, undef if C<$me> and C<$other>
are not both C<NetAddr::IP::Lite> objects.

An IPv4 object and an IPv6 object never contain each other, even when
the IPv6 address is the IPv4 address in C<::a.b.c.d> or C<::ffff:a.b.c.d>
form. Compare C<-E<gt>addr()> of the two to see why: they print as
different addresses.

=cut

sub within ($$) {
  return undef unless UNIVERSAL::isa($_[0],__PACKAGE__)
		   && UNIVERSAL::isa($_[1],__PACKAGE__);
  return 0 if ($_[0]->{isv6} ? 1 : 0) != ($_[1]->{isv6} ? 1 : 0);	# different address families
  return 1 unless hasbits($_[1]->{mask});	# 0x0 contains everything
  my $netme	= $_[0]->{addr} & $_[0]->{mask};
  my $brdme	= $_[0]->{addr} | ~ $_[0]->{mask};
  my $neto	= $_[1]->{addr} & $_[1]->{mask};
  my $brdo	= $_[1]->{addr} | ~ $_[1]->{mask};
  return (sub128($netme,$neto) && sub128($brdo,$brdme))
	? 1 : 0;
}

=item C<-E<gt>is_rfc1918()>

Returns true when C<$me> is an RFC 1918 address.

     10.0.0.0        -   10.255.255.255  (10/8 prefix)
     172.16.0.0      -   172.31.255.255  (172.16/12 prefix)
     192.168.0.0     -   192.168.255.255 (192.168/16 prefix)

=cut

my $ip_10	= NetAddr::IP::Lite->new('10.0.0.0/8');
my $ip_10n	= $ip_10->{addr};               # already the right value
my $ip_10b	= $ip_10n | ~ $ip_10->{mask};

my $ip_172	= NetAddr::IP::Lite->new('172.16.0.0/12');
my $ip_172n	= $ip_172->{addr};              # already the right value
my $ip_172b	= $ip_172n | ~ $ip_172->{mask};

my $ip_192	= NetAddr::IP::Lite->new('192.168.0.0/16');
my $ip_192n	= $ip_192->{addr};              # already the right value
my $ip_192b	= $ip_192n | ~ $ip_192->{mask};

sub is_rfc1918 ($) {
  my $netme     = $_[0]->{addr} & $_[0]->{mask};
  my $brdme     = $_[0]->{addr} | ~ $_[0]->{mask};
  return 1 if (sub128($netme,$ip_10n) && sub128($ip_10b,$brdme));
  return 1 if (sub128($netme,$ip_192n) && sub128($ip_192b,$brdme));
  return (sub128($netme,$ip_172n) && sub128($ip_172b,$brdme))
        ? 1 : 0;
}

=item C<-E<gt>is_local()>

Returns true when C<$me> is a local network address.

	i.e.	ipV4	127.0.0.0 - 127.255.255.255
  or		ipV6	=== ::1
  or		ipV6	::127.0.0.0 - ::127.255.255.255
  or		ipV6	::ffff:127.0.0.0 - ::ffff:127.255.255.255

An IPv4 loopback address held in an IPv6 object (from C<new6>, or an
IPv4 mapped address) is local, the same as its IPv4 form.

=cut

my $_lclhost6	= NetAddr::IP::Lite->new('::1');
my $_lclnet	= NetAddr::IP::Lite->new('127/8');
my $_lclnetn	= $_lclnet->{addr};
my $_lclnetb	= $_lclnetn | ~ $_lclnet->{mask};

sub is_local ($) {
  my $self = $_[0];
  my $addr = $self->{addr};
  if ($self->{isv6}) {
    return 1 if $self == $_lclhost6;
    return 0 unless isAnyIPv4($addr);	# ::a.b.c.d or ::ffff:a.b.c.d
    $addr &= ~ $_ipv4FFFF;		# drop the mapped prefix
  }
  my $netme = $addr & $self->{mask};
  my $brdme = $addr | ~ $self->{mask};
  return (sub128($netme,$_lclnetn) && sub128($_lclnetb,$brdme))
	? 1 : 0;
}

=item C<-E<gt>first()>

Returns a new object representing the first usable IP address within
the subnet (ie, the first host address).

=cut

my $_cidr127 = pack('N4',0xffffffff,0xffffffff,0xffffffff,0xfffffffe);

sub first ($) {
  if (hasbits($_[0]->{mask} ^ $_cidr127)) {
    return $_[0]->network + 1;
  } else {
    return $_[0]->network;
  }
#  return $_[0]->network + 1;
}

=item C<-E<gt>last()>

Returns a new object representing the last usable IP address within
the subnet (ie, one less than the broadcast address).

=cut

sub last ($) {
  if (hasbits($_[0]->{mask} ^ $_cidr127)) {
    return $_[0]->broadcast - 1;
  } else {
    return $_[0]->broadcast;
  }
#  return $_[0]->broadcast - 1;
}

=item C<-E<gt>nth($index)>

Returns a new object representing the I<n>-th usable IP address within
the subnet (ie, the I<n>-th host address).  If no address is available
(for example, when the network is too small for C<$index> hosts),
C<undef> is returned.

Version 4.00 of NetAddr::IP and version 1.00 of NetAddr::IP::Lite implements
C<-E<gt>nth($index)> and C<-E<gt>num()> exactly as the documentation states.
Previous versions behaved slightly differently and not in a consistent
manner.

To use the old behavior for C<-E<gt>nth($index)> and C<-E<gt>num()>:

  use NetAddr::IP::Lite qw(:old_nth);

  old behavior:
  NetAddr::IP::Lite->new('192.0.2.0/32')->nth(0) == undef
  NetAddr::IP::Lite->new('192.0.2.0/32')->nth(1) == undef
  NetAddr::IP::Lite->new('192.0.2.0/31')->nth(0) == undef
  NetAddr::IP::Lite->new('192.0.2.0/31')->nth(1) == 192.0.2.1/31
  NetAddr::IP::Lite->new('192.0.2.0/30')->nth(0) == undef
  NetAddr::IP::Lite->new('192.0.2.0/30')->nth(1) == 192.0.2.1/30
  NetAddr::IP::Lite->new('192.0.2.0/30')->nth(2) == 192.0.2.2/30
  NetAddr::IP::Lite->new('192.0.2.0/30')->nth(3) == 192.0.2.3/30

Note that in each case, the broadcast address is represented in the
output set and that the 'zero'th index is always undef.

  new behavior:
  NetAddr::IP::Lite->new('192.0.2.0/32')->nth(0) == 192.0.2.0/32
  NetAddr::IP::Lite->new('192.0.2.1/32')->nth(0) == 192.0.2.1/32
  NetAddr::IP::Lite->new('192.0.2.0/31')->nth(0) == 192.0.2.0/31
  NetAddr::IP::Lite->new('192.0.2.0/31')->nth(1) == 192.0.2.1/31
  NetAddr::IP::Lite->new('192.0.2.0/30')->nth(0) == 192.0.2.1/30
  NetAddr::IP::Lite->new('192.0.2.0/30')->nth(1) == 192.0.2.2/30
  NetAddr::IP::Lite->new('192.0.2.0/30')->nth(2) == undef

Note that a /32 net always has 1 usable address while a /31 has exactly
two usable addresses for point-to-point addressing. The first
index (0) returns the address immediately following the network address
except for a /31 or /127 when it return the network address.

=cut

sub nth ($$) {
  my $self    = shift;
  my $count   = shift;

  return undef unless defined $count && $count =~ /^-?[0-9]+$/;

  my $slash31 = ! hasbits($self->{mask} ^ $_cidr127);
  if ($Old_nth) {
    return undef if $slash31 && $count != 1;
    return undef if ($count < 1 or $count > $self->num ());
  }
  elsif ($slash31) {
    return undef if ($count && $count != 1);	# only index 0, 1 allowed for /31
  } else {
    ++$count;
    return undef if ($count < 1 or $count > $self->num ());
  }
  return $self->network + $count;
}

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

=cut

sub num ($) {
  if ($Old_nth) {
    my @net = unpack('L3N',$_[0]->{mask} ^ Ones);
# number of ip's less broadcast
    return 0xfffffffe if $net[0] || $net[1] || $net[2]; # 2**32 - 2
    return $net[3] if $net[3];
  } else {	# returns 1 for /32 /128, 2 for /31 /127 else n-2 up to 2**32
    (undef, my $net) = addconst($_[0]->{mask},1);
    return 1 unless hasbits($net);	# ipV4/32 or ipV6/128
    $net = $net ^ Ones;
    return 2 unless hasbits($net);	# ipV4/31 or ipV6/127
    $net &= $_v4net unless $_[0]->{isv6};
    return bin2bcd($net);
  }
}

# deprecated
#sub num ($) {
#  my @net = unpack('L3N',$_[0]->{mask} ^ Ones);
#  if ($Old_nth) {
## number of ip's less broadcast
#    return 0xfffffffe if $net[0] || $net[1] || $net[2]; # 2**32 - 2
#    return $net[3] if $net[3];
#  } else {	# returns 1 for /32 /128, 0 for /31 /127 else n-2 up to 2**32
## number of usable IP's === number of ip's less broadcast & network addys
#    return 0xfffffffd if $net[0] || $net[1] || $net[2]; # 2**32 -2
#    return 1 unless $net[3];
#    $net[3]--;
#  }
#  return $net[3];
#}


=back

=cut

sub import {
  if (grep { $_ eq ':aton' } @_) {
    $Accept_Binary_IP = 1;
    @_ = grep { $_ ne ':aton' } @_;
  }
  if (grep { $_ eq ':old_nth' } @_) {
    $Old_nth = 1;
    @_ = grep { $_ ne ':old_nth' } @_;
  }
  if (grep { $_ eq ':lower' } @_)
  {
    NetAddr::IP::Util::lower();
    @_ = grep { $_ ne ':lower' } @_;
  }
  if (grep { $_ eq ':upper' } @_)
  {
    NetAddr::IP::Util::upper();
    @_ = grep { $_ ne ':upper' } @_;
  }
  if (grep { $_ eq ':nofqdn' } @_)
  {
    $NoFQDN = 1;
    @_ = grep { $_ ne ':nofqdn' } @_;
  }
  NetAddr::IP::Lite->export_to_level(1, @_);
}

=head1 EXPORT_OK

	Zeros
	Ones
	V4mask
	V4net
	:aton		DEPRECATED
	:old_nth
	:upper
	:lower
	:nofqdn

=head1 SEE ALSO

NetAddr::IP(3), NetAddr::IP::Util(3), NetAddr::IP::InetBase(3)

=head1 ADDITIONAL LICENSE

This file is also available to redistribute it and/or modify it under
the terms of the "Artistic License" which comes with this distribution,
in the file named "Artistic".

=cut

1;
