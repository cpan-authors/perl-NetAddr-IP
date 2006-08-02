#!/usr/bin/perl -w

package NetAddr::IP;

use strict;
#use diagnostics;
use NetAddr::IP::Lite 1.01 qw(Zero Ones V4mask V4net);
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
	@ISA
	$VERSION
	$isV6
);
require Exporter;

@EXPORT_OK = qw(Compact Coalesce Zero Ones V4mask V4net);

@ISA = qw(Exporter NetAddr::IP::Lite);

$VERSION = do { sprintf " %d.%03d", (q$Revision: 4.001 $ =~ /\d+/g) };

=pod

=head1 NAME

NetAddr::IP - Manages IPv4 and IPv6 addresses and subnets

=head1 SYNOPSIS

  use NetAddr::IP qw(
	Compact
	Coalesce
	Zero
	Ones
	V4mask
	V4net
	:aton
	:old_storable
  );

  my $ip = new NetAddr::IP 'loopback';

  print "The address is ", $ip->addr, " with mask ", $ip->mask, "\n" ;

  if ($ip->within(new NetAddr::IP "127.0.0.0", "255.0.0.0")) {
      print "Is a loopback address\n";
  }

				# This prints 127.0.0.1/32
  print "You can also say $ip...\n";

* The following four functions return ipV6 representations of:

  ::                                       = Zeros();
  FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF: = Ones();
  FFFF:FFFF:FFFF:FFFF:FFFF:FFFF::          = V4mask();
  ::FFFF:FFFF                              = V4net();


* To accept addresses in the format as returned by inet_aton, invoke the module
as:

  use NetAddr::IP qw(:aton);

* To enable usage of legacy data files containing NetAddr::IP
objects stored using the L<Storable> module.

  use NetAddr::IP qw(:old_storable);  

* To compact many smaller subnets (see: C<$me-E<gt>compact($addr1, $addr2,...)>

  @compacted_object_list = Compact(@object_list)

* Return a reference to list of C<NetAddr::IP> subnets of
C<$masklen> mask length, when C<$number> or more addresses from
C<@list_of_subnets> are found to be contained in said subnet.

  $arrayref = Coalesce($masklen, $number, @list_of_subnets)

=head1 INSTALLATION

Un-tar the distribution in an appropriate directory and type:

	perl Makefile.PL
	make
	make test
	make install

B<NetAddr::IP> depends on B<NetAddr::IP::Util> which installs by default with its primary functions compiled
using Perl's XS extensions to build a 'C' library. If you do not have a 'C'
complier available or would like the slower Pure Perl version for some other
reason, then type:

	perl Makefile.PL -noxs
	make
	make test
	make install

=head1 DESCRIPTION

This module provides an object-oriented abstraction on top of IP
addresses or IP subnets, that allows for easy manipulations. 
Version 4.xx of NetAdder::IP will will work older
versions of Perl and does B<not> use Math::BigInt as in previous versions.

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

=pod

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

	my $ip = new NetAddr::IP '192.168.1.123';
        print "$ip\n";

Will print the string 192.168.1.123/32.

=item B<Equality>

You can test for equality with either C<eq> or C<==>. C<eq> allows the
comparison with arbitrary strings as well as NetAddr::IP objects. The
following example:

    if (NetAddr::IP->new('127.0.0.1','255.0.0.0') eq '127.0.0.1/8') 
       { print "Yes\n"; }

Will print out "Yes".

Comparison with C<==> requires both operands to be NetAddr::IP objects.

In both cases, a true value is returned if the CIDR representation of
the operands is equal.

=item B<Comparison via E<gt>, E<lt>, E<gt>=, E<lt>=, E<lt>=E<gt> and C<cmp>>

Internally, all network objects are represented in 128 bit format.
The numeric representation of the network is compared through the
corresponding operation. Comparisons are tried first on the address portion
of the object and if that is equal then the cidr portion of the masks are
compared.

=item B<Addition of a constant>

Adding a constant to a NetAddr::IP object changes its address part to
point to the one so many hosts above the start address. For instance,
this code:

    print NetAddr::IP->new('127.0.0.1') + 5;

will output 127.0.0.6/8. The address will wrap around at the broadcast
back to the network address. This code:

    print NetAddr::IP->new('10.0.0.1/24') + 255;

outputs 10.0.0.0/24.

=item B<Substraction of a constant>

The complement of the addition of a constant.

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

=pod

=back

=head2 Serializing and Deserializing

This module defines hooks to collaborate with L<Storable> for
serializing C<NetAddr::IP> objects, through compact and human readable
strings. You can revert to the old format by invoking this module as

  use NetAddr::IP ':old_storable';

You must do this if you have legacy data files containing NetAddr::IP
objects stored using the L<Storable> module.

=cut

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
	    my $self	= shift;
	    my $cloning	= shift;	# Not used
	    my $serial	= shift;
	    
	    my $ip = new NetAddr::IP $serial;
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
    NetAddr::IP->export_to_level(1, @_);
}

sub compact {
    return @{compactref(\@_)};
}

*Compact = \&compact;

sub Coalesce {
  return &coalesce;
}

sub hostenumref($) {
  my $r = $_[0]->splitref();
  unless ((notcontiguous($_[0]->{mask}))[1] == 128) {
    splice(@$r, 0, 1);
    splice(@$r, scalar @$r - 1, 1);
  }
  return $r;
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

=pod

=head2 Methods

=over

=item C<-E<gt>new([$addr, [ $mask|IPv6 ]])>

=item C<-E<gt>new6([$addr, [ $mask]])>

These methods creates a new address with the supplied address in
C<$addr> and an optional netmask C<$mask>, which can be omitted to get
a /32 or /128 netmask for IPv4 / IPv6 addresses respectively

C<-E<gt>new6> marks the address as being in ipV6 address space even if the
format would suggest otherwise.

  i.e.	->new6('1.2.3.4') will result in ::102:304

  addresses submitted to ->new in ipV6 notation will
  remain in that notation permanently. i.e.
	->new('::1.2.3.4') will result in ::102:304
  whereas new('1.2.3.4') would print out as 1.2.3.4

  See "STRINGIFICATION" below.

C<$addr> can be almost anything that can be resolved to an IP address
in all the notations I have seen over time. It can optionally contain
the mask in CIDR notation.

B<prefix> notation is understood, with the limitation that the range
speficied by the prefix must match with a valid subnet.

Addresses in the same format returned by C<inet_aton> or
C<gethostbyname> can also be understood, although no mask can be
specified for them. The default is to not attempt to recognize this
format, as it seems to be seldom used.

To accept addresses in that format, invoke the module as in

  use NetAddr::IP ':aton'

If called with no arguments, 'default' is assumed.

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
  123456789012  a 'big' bcd number i.e. Math::BigInt

If called with no arguments, 'default' is assumed.

=item C<-E<gt>broadcast()>

Returns a new object refering to the broadcast address of a given
subnet. The broadcast address has all ones in all the bit positions
where the netmask has zero bits. This is normally used to address all
the hosts in a given subnet.

=item C<-E<gt>network()>

Returns a new object refering to the network address of a given
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

=pod

=item C<-E<gt>numeric()>

When called in a scalar context, will return a numeric representation
of the address part of the IP address. When called in an array
contest, it returns a list of two elements. The first element is as
described, the second element is the numeric representation of the
netmask.

This method is essential for serializing the representation of a
subnet.

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

=pod

=item C<-E<gt>short()>

Returns the address part in a short or compact notation. 

  (ie, 127.0.0.1 becomes 127.1). 

Works with both, V4 and V6.

=cut

sub _compact_v6 ($) {
    my $addr = shift;

    my @o = split /:/, $addr;
    return $addr unless @o and grep { $_ =~ m/^0+$/ } @o;

    my @candidates	= ();
    my $start		= undef;

    for my $i (0 .. $#o)
    {
	if (defined $start)
	{
	    if ($o[$i] !~ m/^0+$/)
	    {
		push @candidates, [ $start, $i - $start ];
		$start = undef;
	    }
	}
	else
	{
	    $start = $i if $o[$i] =~ m/^0+$/;
	}
    }

    push @candidates, [$start, 8 - $start] if defined $start;

    my $l = (sort { $b->[1] <=> $a->[1] } @candidates)[0];

    return $addr unless defined $l;

    $addr = $l->[0] == 0 ? '' : join ':', @o[0 .. $l->[0] - 1];
    $addr .= '::';
    $addr .= join ':', @o[$l->[0] + $l->[1] .. $#o];
    $addr =~ s/(^|:)0{1,3}/$1/g;

    return $addr;
}


sub _compV6 {
  my @addr = split(':',shift);
  my $found = 0;
  my $v;
  foreach(0..$#addr) {
    ($v = $addr[$_]) =~ s/^0+//;
    $addr[$_] = $v || 0;
  }
  @_ = reverse(1..$#addr);
  foreach(@_) {
    if ($addr[$_] || $addr[$_ -1]) {
      last if $found;
      next;
    }
    $addr[$_] = $addr[$_ -1] = '';
    $found = '1';
  }
  (my $rv = join(':',@addr)) =~ s/:+:/::/;
  return $rv;
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

=pod

=item C<$me-E<gt>contains($other)>

Returns true when C<$me> completely contains C<$other>. False is
returned otherwise and C<undef> is returned if C<$me> and C<$other>
are not both C<NetAddr::IP> objects.

=item C<$me-E<gt>within($other)>

The complement of C<-E<gt>contains()>. Returns true when C<$me> is
completely con tained within C<$other>.

Note that C<$me> and C<$other> must be C<NetAddr::IP> objects.

=item C<-E<gt>split($bits)>

Returns a list of objects, representing subnets of C<$bits> mask
produced by splitting the original object, which is left
unchanged. Note that C<$bits> must be longer than the original
mask in order for it to be splittable.

Note that C<$bits> can be given as an integer (the length of the mask)
or as a dotted-quad. If omitted, a host mask is assumed.

=cut

sub split ($;$) {
    return @{$_[0]->splitref($_[1])};
}

=pod

=item C<-E<gt>splitref($bits)>

A (faster) version of C<-E<gt>split()> that returns a reference to a
list of objects instead of a real list. This is useful when large
numbers of objects are expected.

Return undef if the number of subnets > 2 ** 32

=cut

sub splitref($;$) {
  my $net = $_[0]->network;
  my $mask = $_[1] || '';
  if ($mask) {
    return undef unless ($mask = NetAddr::IP->new($net->addr,$mask)->{mask});
  } else {
    $mask = Ones();
  }
  my $scidr = (notcontiguous($mask))[1];
  my $nnets = $scidr - (notcontiguous($net->{mask}))[1];
  return undef if $nnets < 0 || $nnets > 32;
  return [$net] if $nnets == 0;
  $nnets = 2 ** $nnets;			# number of nets
  my $nsize = (sub128(Zero,$mask))[1];
  my @ret = unpack('L3N',$nsize);
  return undef if $ret[0] || $ret[1] || $ret[2];
  $nsize = $ret[3];
  @ret = ();
  
  while ($nnets-- > 0) {
    push @ret, $net->_new($net->{addr},$mask);
    $net->{addr} = (addconst($net->{addr},$nsize))[1];
  }
  return \@ret;
}

=pod

=item C<-E<gt>hostenum()>

Returns the list of hosts within a subnet.

=cut

sub hostenum ($) {
    return @{$_[0]->hostenumref};
}

=pod

=item C<-E<gt>hostenumref()>

Faster version of C<-E<gt>hostenum()>, returning a reference to a list.

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

=item C<$me-E<gt>compactref(\@list)>

As usual, a faster version of =item C<-E<gt>compact()> that returns a
reference to a list. Note that this method takes a reference to a list
instead.

Note that C<$me> must be a C<NetAddr::IP> object.

=cut

sub compactref($) {
  my @r = sort @{$_[0]}
	or return [];
  return [] unless @r;
  foreach(0..$#r) {
    $r[$_]->{addr} = $r[$_]->network->{addr};
  }
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
	    if (hasbits($r[$i]->network->{addr} ^ $r[$i +1]->network->{addr})) {	# if not the same netblock
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
  return \@r;
}

=pod

=item C<$me-E<gt>coalesce($masklen, $number, @list_of_subnets)>

=item C<$arrayref = Coalesce($masklen,$number,@list_of_subnets)>

Will return a reference to list of C<NetAddr::IP> subnets of
C<$masklen> mask length, when C<$number> or more addresses from
C<@list_of_subnets> are found to be contained in said subnet.

Subnets from C<@list_of_subnets> with a mask shorter than C<$masklen>
are passed "as is" to the return list.

Subnets from C<@list_of_subnets> with a mask longer than C<$masklen>
will be counted (actually, the number of IP addresses is counted)
towards C<$number>.

Called as a method, the array will include C<$me>.

WARNING: the list of subnet must be the same type. i.e ipV4 or ipV6

=cut

sub coalesce
{
    my $masklen	= shift;
    if (ref $masklen && ref $masklen eq __PACKAGE__ ) {	# if called as a method
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
	    $ret{$n} += $ip->num + $NetAddr::IP::Lite::Old_nth;
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
    for my $c (map { new NetAddr::IP $_ } 
	       grep { $ret{$_} >= $number } 
	       keys %ret)
    {
	next if grep { $_->contains($c) } @ret;
	push @ret, $c;
    }

    return \@ret;
}

=pod

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

=item C<-E<gt>num()>

Version 4.00 of NetAddr::IP and version 1.00 of NetAddr::IP::Lite
Returns the number of usable addresses IP addresses within the
subnet, not counting the broadcast or network address. Previous versions
returned th number of IP addresses not counting the broadcast address.

To use the old behavior for C<-E<gt>nth($index)> and C<-E<gt>num()>:

  use NetAddr::IP::Lite qw(:old_nth);

=item C<-E<gt>re()>

Returns a Perl regular expression that will match an IP address within
the given subnet. Defaults to ipV4 notation. Will return an ipV6 regex
if the address in not in ipV4 space.

=cut

sub re ($)
{
    goto &re6 unless isIPv4($_[0]->{addr});
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

    ### no digit before nor after (look-behind, look-ahead)
    return "(?:(?<![0-9])$r[0]\\.$r[1]\\.$r[2]\\.$r[3](?![0-9]))";
}

=item C<-E<gt>re6()>

Returns a Perl regular expression that will match an IP address within
the given subnet. Always returns an ipV6 regex.

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
      if ($n =~ /\d/) {
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
      elsif ($n =~ /\d/ && $b =~ /\d/) {
	push @dig, '['.$n.'-'.$b.']';
      }
      elsif ($n =~ /[A-F]/ && $b =~ /[A-F]/) {
	$n .= '-'.$b;
	push @dig, '['.(lc $n).$n.']';
      }
      elsif ($n =~ /\d/ && $b =~ /[A-F]/) {
	$m = ($n == 9) ? 9 : $n .'-9';
	if ($b =~ /A/) {
	  $m .= 'aA';
	} else {
	  $b = 'A-'. $b;
	  $m .= (lc $b). $b;
	}
	push @dig, '['.$m.']';
      }
      elsif ($n =~ /[A-F]/ && $b =~ /\d/) {
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
    if ($grp =~ /^0+/) {
      my $l = length($&);  
      if ($l == 4) {
	$grp = '0{1,4}';
      } else {
	$grp =~ s/^${&}/0\{0,$l\}/;  
      }
    }
    if ($grp =~ /x+$/) {
      my $l = length($&);
      if ($l == 4) {
	$grp = '[0-9a-fA-F]{1,4}';
      } else {
	$grp =~ s/x+/\[0\-9a\-fA\-F\]\{$l\}/;
      }
    }
    push @grp, $grp;
  } while @dig > 0;
  return '('. join(':',@grp) .')';
}

sub mod_version {
  return $VERSION;
  &Compact;			# suppress warnings about these symbols
  &Coalesce;
  &STORABLE_freeze;
  &STORABLE_thaw;
}

1;

__END__

=pod

=back

=head1 EXPORT_OK

	Compact
	Coalesce
	Zero
	Ones
	V4mask
	V4net 

=head1 HISTORY

$Id: IP.pm,v 3.28 2005/09/28 23:56:52 lem Exp $

=over

=item 0.01

=over


=item *

original  version;  Basic testing  and  release  to CPAN  as
version 0.01. This is considered beta software.

=back


=item 0.02

=over


=item *

Multiple changes  to fix endiannes issues. This  code is now
moderately tested on Wintel and Sun/Solaris boxes.

=back


=item 0.03

=over


=item *

Added -E<gt>first and -E<gt>last methods. Version changed to 0.03.

=back


=item 1.00

=over


=item *

Implemented -E<gt>new_subnet. Version changed to 1.00.

=item *

less croak()ing when improper input  is fed to the module. A
more consistent 'undef' is returned now instead to allow the
user to better handle the error.

=back


=item 1.10

=over


=item *

As  per  Marnix   A.   Van  Ammers  [mav6@ns02.comp.pge.com]
suggestion, changed  the syntax of the loop  in host_enum to
be the same of the enum method.

=item *

Fixed the MS-DOS ^M  at the end-of-line problem. This should
make the module easier to use for *nix users.

=back


=item 1.20

=over


=item *

Implemented -E<gt>compact and -E<gt>expand methods.

=item *

Applying for official name

=back


=item 1.21

=over


=item *

Added  -E<gt>addr_number and  -E<gt>mask_bits.  Currently  we return
normal  numbers (not  BigInts).   Please test  this in  your
platform and report any problems!

=back


=item 2.00

=over


=item *

Released under the new *official* name of NetAddr::IP

=back


=item 2.10

=over


=item *

Added support for -E<gt>new($min, $max, $bits) form

=item *

Added -E<gt>to_numeric. This helps serializing objects

=back


=item 2.20

=over


=item *

Chris Dowling  reported that  the sort method  introduced in
v1.20  for -E<gt>expand  and -E<gt>compact  doesn't always  return a
number under perl versions < 5.6.0.  His fix was applied and
redistributed.  Thanks Chris!

=item *

This module is hopefully released with no CR-LF issues!

=item *

Fixed a warning about uninitialized values during make test

=back


=item 2.21

=over


=item *

Dennis  Boylan pointed  out a  bug under  Linux  and perhaps
other platforms  as well causing the  error "Sort subroutine
didn't         return         single        value         at
/usr/lib/perl5/site_perl/5.6.0/NetAddr/IP.pm  line  299,  E<lt>E<gt>
line 2." or similar. This was fixed.

=back


=item 2.22

=over


=item *

Some changes  suggested by Jeroen Ruigrok  and Anton Berezin
were included. Thanks guys!

=back


=item 2.23

=over


=item *

Bug fix for /XXX.XXX.XXX.XXX netmasks under v5.6.1 suggested
by Tim Wuyts. Thanks!

=item *

Tested the module under MACHTYPE=hppa1.0-hp-hpux11.00. It is
now  konwn to  work  under Linux  (Intel/AMD), Digital  Unix
(Alpha),   Solaris  (Sun),  HP-UX11   (HP-PA-RISC),  Windows
9x/NT/2K (using ActiveState on Intel).

=back


=item 2.24

=over


=item *

A spurious  warning when  expand()ing with C<-w>  under certain
circumstances  was removed. This  involved using  /31s, /32s
and the same netmask as the input.  Thanks to Elie Rosenblum
for pointing it out.

=item *

Slight change  in license terms to ease  redistribution as a
Debian package.

=back


=item 3.00

This is  a major rewrite, supposed  to fix a number  of issues pointed
out in earlier versions.

The goals for this version include getting rid of BigInts, speeding up
and also  cleaning up the code,  which is written in  a modular enough
way so  as to allow IPv6  functionality in the  future, taking benefit
from most of the methods.

Note that no effort has  been made to remain backwards compatible with
earlier versions. In particular, certain semantics of the earlier
versions have been removed in favor of faster performance.

This  version  was tested  under  Win98/2K (ActiveState  5.6.0/5.6.1),
HP-UX11 on PA-RISC (5.6.0), RedHat  Linux 6.2 (5.6.0), Digital Unix on
Alpha (5.6.0), Solaris on Sparc (5.6.0) and possibly others.

=item 3.01

=over

=item * 

Added C<-E<gt>numeric()>.

=item *

C<-E<gt>new()> called with no parameters creates a B<default>
NetAddr::IP object.

=back

=item 3.02

=over

=item *

Fxed C<-E<gt>compact()> for cases of equal subnets or
mutually-contained IP addresses as pointed out by Peter Wirdemo. Note
that now only distinct IP addresses will be returned by this method.

=item *

Fixed the docs as suggested by Thomas Linden.

=item *

Introduced overloading to ease certain common operations.

=item *

    Fixed compatibility issue with C<-E<gt>num()> on 64-bit processors.

=back

=item 3.03

=over

=item *

Added more comparison operators.

=item *

As per Peter Wirdemo's suggestion, added C<-E<gt>wildcard()> for
producing subnets in wildcard format.

=item *

Added C<++> and C<+> to provide for efficient iteration operations
over all the hosts of a subnet without C<-E<gt>expand()>ing it.

=back

=item 3.04

=over

=item *

Got rid of C<croak()> when invalid input was fed to C<-E<gt>new()>.

=item *

As suggested by Andrew Gaskill, added support for prefix
notation. Thanks for the code of the initial C<-E<gt>prefix()>
function.

=back

=item 3.05

=over

=item *

Added support for range notation, where base and broadcast addresses
are given as arguments to C<-E<gt>new()>.

=back

=item 3.06

=over

=item *

Andrew Ruthven pointed out a bug related to proper interpretation of
"compact" CIDR blocks. This was fixed. Thanks!

=back

=item 3.07

=over

=item *

Sami Pohto pointed out a bug with C<-E<gt>last()>. This was fixed.

=item *

A small bug related to parsing of 'localhost' was fixed.

=back

=item 3.08

=over

=item *

By popular request, C<-E<gt>new()> now checks the sanity of the netmasks
it receives. If the netmask is invalid, C<undef> will be returned.

=back

=item 3.09

=over

=item *

Fixed typo that invalidated otherwise correct masks. This bug appeared in 3.08.

=back

=item 3.10

=over

=item *

Fixed relops. Semantics where adjusted to remove the netmask from the
comparison. (ie, it does not make sense to say that 10.0.0.0/24 is >
10.0.0.0/16 or viceversa).

=back

=item 3.11

=over

=item *

Thanks to David D. Zuhn for contributing the C<-E<gt>nth()> method.

=item *

tutorial.htm now included in the  distribution. I hope this helps some
people to better  understand what kind of stuff can  be done with this
module.

=item *

C<'any'> can be used as a synonim of C<'default'>. Also, C<'host'> is
now a valid (/32) netmask.

=back

=item 3.12

=over

=item *

Added CVS control files, though this is of no relevance to the community.

=item *

Thanks to Steve Snodgrass for pointing out a bug in the processing of
the special names such as default, any, etc. A fix was produced and
adequate tests were added to the code.

=item *

First steps towards "regexp free" parsing.

=item *

Documentation revisited and reorganized within the file, so that it
helps document the code.

=item *

Added C<-E<gt>aton()> and support for this format in
C<-E<gt>new()>. This makes the code helpful to interface with
old-style socket code.

=back

=item 3.13

=over

=item *

Fixes a warning related to 'wrapping', introduced in 3.12 in
C<pack()>/C<unpack()> for the new support for C<-E<gt>aton()>.

=back

=item 3.14

=over

=item *

C<Socket::gethostbyaddr> in Solaris seems to behave a bit different
from other OSes. Reversed change in 3.13 and added code around this
difference.

=back

=item 3.14_1

This is an interim release just to incorporate the v6 patches
contributed.  No extensive testing has been done with this support
yet. More tests are needed.

=over

=item *

Preliminary support for IPv6 contributed by Kadlecsik Jozsi
E<lt>kadlec at sunserv.kfki.huE<gt>. Thanks a lot!

=item *

IP.pm and other files are enconded in ISO-8859-1 (Latin1) so that I
can spell my name properly.

=item *

Tested under Perl 5.8.0, no surprises found.

=back

=item 3.14_2

Minor development release.

=over

=item *

Added C<-E<gt>version> and C<-E<gt>bits>, including testing.

=item *

C<Compact> can now be exported if the user so requests.

=item *

Fixed a bug when octets in a dotted quad were > 256 (ie, were not
octets). Thanks to Anton Berezin for pointing this out.

=back

=item 3.14_3

Fixed a bug pointed out by Brent Imhoff related to the implicit
comparison that happens within C<Compact()>. The netmask was being
ignored in the comparison (ie, 10/8 was considered the same as
10.0/16). Since some people have requested that 10.0/16 was considered
larger than 10/8, I added this change, which makes the bug go
away. This will be the last '_' release, pending new bugs.

Regarding the comparison of subnets, I'm still open to debate so as to
wether 10.0/16 > 10/8. Certainly 255.255.0.0 > 255.0.0.0, but 2 ** 24
are more hosts than 2 ** 16. I think we might use gt & friends for
this semantic and make everyone happy, but I won't do anything else
here without (significant) feedback.

=item 3.14_4

As noted by Michael, 127/8 should be 127.0.0.0/8 and not
0.0.0.128/8. Also, improved docs on the usage of contains() and
friends.

=item 3.15

Finally. Added POD tests (and fixed minor doc bug in IP.pm). As
reported by Anand Vijay, negative numbers are assumed to be signed
ints and converted accordingly to a v4 address. split() and nth() now
work with IPv6 addresses (Thanks to Venkata Pingali for
reporting). Tests were added for v6 base functionality and
splitting. Also tests for bitwise aritmethic with long integers has
been added. I'm afraid Math::BigInt is now required.

Note that IPv6 might not be as solid as I would like. Be careful...

=item 3.16

Fixed a couple of (minor) bugs in shipped tests in the last
version. Also, fixed a small pod typo that caused code to show up in
the documentation.

=item 3.17

Fixed IP.pm so that all test could pass in Solaris machines. Thanks to
all who reported this.

=item 3.18

Fixed some bugs pointed out by David Lloyd, having to do with the
module packaging and version requirements. Thanks David!

=item 3.19

Fixed a bug pointed out by Andrew D. Clark, regarding proper parsing
of IP ranges with non-contiguous masks. Thanks Andrew!

=item 3.20

Suggestion by Reuland Olivier gave birth to C<short()>, which provides
for a compact representation of the IP address. Rewrote C<_compact> to
find the longest sequence of zeros to compact. Reuland also pointed
out a flaw in contains() and within(), which was fixed. Thanks
Reuland!

Fixed rt bug #5478 in t/00-load.t.

=item 3.21

Fixed minor v-string problem pointed out by Steve Snodgrass (Thanks
Steve!). NetAddr::IP can now collaborate with Storable to serialize
itself.

=item 3.22

Fixed bug rt.cpan.org #7070 reported by Grover Browning (auto-inc/dec
on v6 fails). Thanks Grover. Ruben van Staveren pointed out a bug in
v6 canonicalization, as well as providing a patch that was
applied. Thanks Ruben.

=item 3.23

Included support for Module::Signature. Added -E<gt>re() as
contributed by Laurent Facq (Thanks Laurent!). Added Coalesce() as
suggested by Perullo.

=item 3.24

Version bump. Transfer of 3.23 to CPAN ended up in a truncated file
being uploaded.

=item 3.25

Some IP specs resembling range notations but not depicting actual CIDR
ranges, were being erroneously recognized. Thanks to Steve Snodgrass
for reporting a bug with parsing IP addresses in 4-octet binary
format. Added optional Pod::Coverage tests. compact_addr has been
commented out, after a long time as deprecated. Improved speed of
-E<gt>new() for the case of a single host IPv4 address, which seems to
be the most common one.

=item 4.00

Dependence on Math::BigInt removed, works with earlier versions of Perl.
The module was partitioned into three logical pieces as follows:

Util.pm		Math and logic operation on bit strings and number
		that represent IP addresses and masks. Conversions
		between various number formats. Implemented in
		C_XS for speed and PURE PERL of transportability.

Lite.pm		Operations, simple conversions and comparisons of 
		IP addresses, notations and formats.

IP.pm		Complex operations and conversions of IP address 
		notation, nets, subnets, and ranges.

The internal representation of addresses was changed to 128 bit binary
strings as returned by inet_pton (ipv6_aton in this module). Both
ipV4 and ipV6 notations can be freely mixed and matched. 

Additional methods added to force operations into ipV6 space even when 
ipV4 notation is used.

=back

=head1 AUTHORS

Luis E. Muñoz <luismunoz@cpan.org>,
Michael Robinton <michael@bizsystems.com>

=head1 WARRANTY

This software comes with the same warranty as perl itself (ie, none),
so by using it you accept any and all the liability.

=head1 LICENSE

This software is (c) Luis E. Muñoz, 1999 - 2005, and (c) Michael Robinton, 2006.
It can be used under the terms of the perl artistic license provided that
proper credit for the work of the author is preserved in the form of this
copyright notice and license for this module.

=head1 SEE ALSO

  perl(1)

  L<NetAddr::IP::Lite>

  L<NetAddr::IP::Util>

=cut

