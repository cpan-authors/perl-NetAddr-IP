#!/usr/bin/perl -w

package NetAddr::IP;

require 5.005_62;
use Carp;
use Socket;
use strict;
use warnings;

our $VERSION = '3.00';

# Preloaded methods go here.

				# This is a variant to ->new() that
				# creates and blesses a new object
				# without the fancy parsing of
				# IP formats and shorthands.

sub _fnew ($$) {
    my $type	= shift;
    my $class	= ref($type) || $type || "NetAddr::IP";
    my $r_addr	= shift;

    return 
	bless { addr => $r_addr->[0],
		mask => $r_addr->[1],
		bits => $r_addr->[2] },
	$class;
}

				# Returns 2 ** $bits -1 (ie,
				# $bits one bits)
sub _ones ($) {
    my $bits	= shift;
    return ~vec('', 0, $bits);
}

sub masklen ($) {
    my $self	= shift;
    my $bits	= 0;

    for (my $i = 0;
	 $i < $self->{bits};
	 $i ++) 
    {
	$bits += vec($self->{mask}, $i, 1);
    }

    return $bits;
}

sub _parse_mask ($$) {
    my $mask	= shift;
    my $bits	= shift;

    my $bmask	= '';

    if ($mask =~ m/^default$/i) {
	vec($bmask, 0, $bits) = 0x0;
    }
    elsif ($mask =~ m/^broadcast$/i) {
	vec($bmask, 0, $bits) = _ones $bits;
    }
    elsif ($mask =~ m/^loopback$/i) {
	vec($bmask, 0, 8) = 255;
    }
    elsif ($mask =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
	vec($bmask, 0, 8) = $1;
	vec($bmask, 1, 8) = $2;
	vec($bmask, 2, 8) = $3;
	vec($bmask, 3, 8) = $4;
    }
    elsif ($mask =~ m/^(\d+)$/ and $1 <= 32) {
	if ($1) {
	    vec($bmask, 0, $bits) = _ones $bits;
	    vec($bmask, 0, $bits) <<= ($bits - $1);
	} else {
	    vec($bmask, 0, $bits) = 0x0;
	}
    }
    elsif ($mask =~ m/^(\d+)$/) {
        vec($bmask, 0, $bits) = $1;
    }

    return $bmask;
}

sub _v4 ($$) {
    my $ip	= shift;
    my $mask	= shift;

    my $addr = '';

    if ($ip =~ m!^default$!i) {
	vec($addr, 0, 32) = 0x0;
    }
    elsif ($ip =~ m!^broadcast$!i) {
	vec($addr, 0, 32) = _ones 32;
    }
    elsif ($ip =~ m!^loopback$!i) {
	vec($addr, 0, 8) = 127;
	vec($addr, 3, 8) = 1;
    }
    elsif ($ip =~ m/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
	vec($addr, 0, 8) = $1;
	vec($addr, 1, 8) = $2;
	vec($addr, 2, 8) = $3;
	vec($addr, 3, 8) = $4;
    }
    elsif ($ip =~ m/^(\d+)\.(\d+)$/) {
	vec($addr, 0, 8) = $1;
	vec($addr, 1, 8) = 0;
	vec($addr, 2, 8) = 0;
	vec($addr, 3, 8) = $2;
    }
    elsif ($ip =~ m/^(\d+)\.(\d+)\.(\d+)$/) {
	vec($addr, 0, 8) = $1;
	vec($addr, 1, 8) = $2;
	vec($addr, 2, 8) = 0;
	vec($addr, 3, 8) = $3;
    }
    elsif ($ip =~ m/^([xb\d]+)$/) {
	vec($addr, 0, 32) = $1;
    }
    elsif (my $a = gethostbyname($ip)) {
	if (inet_ntoa($a) =~ m!^(\d+)\.(\d+)\.(\d+)\.(\d+)$!)  {
	    vec($addr, 0, 8) = $1;
	    vec($addr, 1, 8) = $2;
	    vec($addr, 2, 8) = $3;
	    vec($addr, 3, 8) = $4;
	}
    }
    else {
	croak "Cannot obtain an IP address out of $ip";
    }

    return { addr => $addr, mask => $mask, bits => 32 };
}

sub new ($$;$) {
    my $type	= $_[0];
    my $class	= ref($type) || $type || "NetAddr::IP";
    my $ip	= $_[1];
    my $mask;

    if (@_ == 2) {
	if ($ip =~ m!^(.+)/(.+)$!) {
	    $ip		= $1;
	    $mask	= $2;
	}
	elsif ($ip =~ m!^(default|broadcast|loopback)$!) {
	    $mask	= $ip;
	}
    }

    if (defined $_[2]) {
	$mask = _parse_mask $_[2], 32;
    }
    elsif (defined $mask) {
	$mask = _parse_mask $mask, 32;
    }
    else {
	$mask = _parse_mask 32, 32;
    }

    return bless _v4($ip, $mask), $class;
}

sub new4 ($$;$) {
    new($_[0], $_[1], $_[2]);
}

				# Output a vec() as a dotted-quad

sub _to_quad ($) {
    my $vec = shift;
    return vec($vec, 0, 8) . '.' . 
	vec($vec, 1, 8) . '.' .
	    vec($vec, 2, 8) . '.' . 
		vec($vec, 3, 8);
}

				# Get the network address

sub _network ($) {
    my $self	= shift;
    my $a = $self->{addr};
    my $m = $self->{mask};

    return [ "$a" & "$m", $self->{mask}, $self->{bits} ];
}

				# Should be obvious

sub _broadcast ($) {
    my $self	= shift;
    my $a = $self->{addr};
    my $m = $self->{mask};

    return [ "$a" | ~ "$m", $self->{mask}, $self->{bits} ];
}

				# This will become an lvalue later

sub mask ($) {
    my $self	= shift;
    _to_quad $self->{mask};
}

				# idem

sub addr ($) {
    my $self	= shift;
    _to_quad $self->{addr};
}

sub cidr ($) {
    my $self	= shift;
    return $self->addr . '/' . $self->masklen;
}

sub broadcast ($) {
    my $self	= shift;
    return $self->_fnew($self->_broadcast);
}

sub network ($) {
    my $self	= shift;
    return $self->_fnew($self->_network);
}

				# Return the shortest possible subnet
				# list that completely contains all
				# the given addresses or subnets.

sub compactref ($) {
    my @addr = sort 
    { (vec($a->{addr}, 0, $a->{bits}) <=> vec($b->{addr}, 0, $a->{bits}))
	  || (vec($a->{mask}, 0, $a->{bits}) 
	      <=> vec($b->{mask}, 0, $a->{bits}))
	  } @{$_[0]} or
	      return [];

    my $bits = $addr[0]->{bits};
    my $changed;

    do {
	$changed = 0;
	for (my $i = 0;
	     $i <= $#addr - 1;
	     $i ++)
	{
	    my $lip = $addr[$i];
	    my $hip = $addr[$i + 1];
	    if (vec($lip->{mask}, 0, $bits) 
		== vec($hip->{mask}, 0, $bits)) 
	    {
		my $la = $lip->{addr};
		my $ha = $hip->{addr};
		my $nb = '';
		my $na = '';
		my $nm = '';

		vec($nb, 0, $bits) = 
		    vec($na, 0, $bits) = 
			vec($la, 0, $bits);
		vec($nb, 0, $bits) ^= vec($ha, 0, $bits);
		vec($na, 0, $bits) ^= vec($nb, 0, $bits);
		vec($nm, 0, $bits) = vec($lip->{mask}, 0, $bits);
		vec($nm, 0, $bits) <<= 1;


#		if ((vec($la, 0, $bits) & vec($nm, 0, $bits))
#		    == (vec($ha, 0, $bits) & vec($nm, 0, $bits)))

		if (("$la" & "$nm") eq ("$ha" & "$nm"))
		{
		    $addr[$i] = ($lip->_fnew([ "$na" & "$nm", 
					       $nm, $bits ]));
		    splice(@addr, $i + 1, 1);

#		    print $lip->addr, "/", $lip->mask, " + ", $hip->addr, 
#		    "/", $hip->mask, " = ", $addr[$i]->addr, "/", 
#		    $addr[$i]->mask, "\n";

		    -- $i;
		    ++ $changed;
		}
	    }
	}
    } while ($changed);

    return \@addr;
}

sub compact {
    return @{compactref(\@_)};
}

				# Splits the current object in
				# smaller subnets, of $bits bits
				# netmask.

sub splitref ($;$) {
    my $self	= shift;
    my $mask	= _parse_mask shift || $self->{bits}, $self->{bits};

    my $bits	= $self->{bits};

    my @ret;

    if (vec($self->{mask}, 0, $bits) 
	<= vec($mask, 0, $bits))
    {

	my $delta	= '';
	my $num		= '';
	my $v		= '';

	vec($num, 0, $bits) = _ones $bits;
	vec($num, 0, $bits) ^= vec($mask, 0, $bits);
	vec($num, 0, $bits) ++;

	vec($delta, 0, $bits) = (vec($self->{mask}, 0, $bits) 
				 ^ vec($mask, 0, $bits));

	my $net	= $self->network->{addr}; 
	$net = "$net" & "$mask";

	my $to = $self->broadcast->{addr}; 
	$to = "$to" & "$mask";

				# XXX - Note that most likely, 
				# this loop will NOT work on IPv6... 
				# $net, $to and $num might very well 
				# be too large for most integer or 
				# floating pointrepresentations.

	for (my $i	= vec($net, 0, $bits);
	     $i 	<= vec($to, 0, $bits);
	     $i 	+= vec($num, 0, $bits))
	{
	    vec($v, 0, $bits) = $i;
	    push @ret, $self->_fnew([ $v, $mask, $bits ]);
	}
    }

    return \@ret;
}

sub split ($;$) {
    return @{$_[0]->splitref($_[1])};
}

sub hostenumref ($) {
    my $r = $_[0]->splitref(32);
    if ($_[0]->mask ne '255.255.255.255') {
	splice(@$r, 0, 1);
	splice(@$r, scalar @$r - 1, 1);
    }
    return $r;
}

sub hostenum ($) {
    return @{$_[0]->hostenumref};
}


				# Returns TRUE if $a completely
				# contains $b and both are of the
				# same length (ie, V4 or V6).
sub contains ($$) {
    my $a	= shift;
    my $b	= shift;

    my $bits	= $a->{bits};

    my $mask;
    
				# Both must be of the same length...
    return undef
	unless $bits == $b->{bits};

				# $a must be less specific than $b...
    return 0
	unless ($mask = vec($a->{mask}, 0, $bits))
	    <= vec($b->{mask}, 0, $bits);

				# A default address always contains
    return 1 if ($mask == 0x0);

    return 
	((vec($a->{addr}, 0, $bits) & $mask)
	 == (vec($b->{addr}, 0, $bits) & $mask));
}

sub within ($$) {
    return contains($_[1], $_[0]);
}

sub first ($) {
    my $self	= shift;
    my $bits 	= $self->{bits};
    my $a 	= $self->{addr};
    my $m 	= $self->{mask};

    my $h 	= '';
    my $addr	= '';

    vec($h, 0, $bits) = 0x1;	# Turn on just the first bit

    return $self->_fnew([ ("$a" & "$m") | "$h", 
			  $self->{mask}, $bits ]);
}

sub last ($) {
    my $self	= shift;
    my $bits 	= $self->{bits};
    my $a 	= $self->{addr};
    my $m 	= $self->{mask};

    my $h 	= '';
    my $addr	= '';

    vec($h, 0, $bits) = _ones $bits;

    return $self->_fnew([ ("$a" & "$m") | ("$h" & ~"$m"), 
			  $self->{mask}, $bits ]);
}

sub num ($) {
    my $self	= shift;
    return ~vec($self->{mask}, 0, $self->{bits});
}

1;
__END__

=head1 NAME

NetAddr::IP - Manages IPv4 addresses and subnets

=head1 SYNOPSIS

  use NetAddr::IP;

  my $ip = new NetAddr::IP 'loopback';

  print "The address is ", $ip->addr, " with mask ", $ip->mask, "\n" ;

  if ($ip->within(new NetAddr::IP "127.0.0.0", "255.0.0.0")) {
      print "Is a loopback address\n";
  }

=head1 DESCRIPTION

This module provides a number of methods useful for handling IPv4
addresses ans subnets. Hopefully, its methods are also usable for IPv6
addresses.

Methods so far include:

=over

=item C<-E<gt>new($addr, [ $mask ])>

This method creates a new IPv4 address with the supplied address in
C<$addr> and an optional netmask C<$mask>, which can be omitted to get
a /32 mask.

C<$addr> can be almost anything that can be resolved to an IP address
in all the notations I have seen over time. It can optionally contain
the mask in CIDR notation.

=item C<-E<gt>broadcast()>

Returns the broadcast address for a subnet.

=item C<-E<gt>network()>

Returns the "network" address for a subnet.

=item C<-E<gt>addr()>

Returns the address part of the object as a dotted-quad.

=item C<-E<gt>mask()>

Returns the mask as a dotted-quad.

=item C<-E<gt>masklen()>

Returns the number of one bits in the mask.

=item C<-E<gt>cidr()>

Returns the address and mask in CIDR notation.

=item C<$me-E<gt>contains($other)>

Returns true when C<$me> completely contains C<$other>. False is
returned otherwise and C<undef> is returned if C<$me> and C<$other>
are of different versions.

=item C<$me-E<gt>within($other)>

The complement of C<-E<gt>contains()>. Returns true when C<$me> is
completely con tained within C<$other>.

=item C<-E<gt>split($bits)>

Returns a list of objects, representing subnets of C<$bits> mask
produced by splitting the original object, which is left
unchanged. Note that C<$bits> must be longer than the original
object's mask in order for it to be splittable.

Note that C<$bits> can be given as an integer (the length of the mask)
or as a dotted-quad. If omitted, a host mask is assumed.

=item C<-E<gt>splitref($bits)>

A (faster) version of C<-E<gt>split()> that returns a reference to a
list of objects instead of a real list. This is useful when large
numbers of objects are expected.

=item C<-E<gt>hostenum()>

Returns the list of hosts within a subnet.

=item C<-E<gt>hostenumref()>

Faster version of C<-E<gt>hostenum()>, returning a reference to a list.

=item C<$me-E<gt>compact($addr1, $addr2, ...)>

Given a list of objects (including C<$me>), this method will compact
all the addresses and subnets into the largest (ie, least specific)
subnets possible that contain exactly all of the given objects.

=item C<$me-E<gt>compactref(\@list)>

As usual, a faster version of =item C<-E<gt>compact()> that returns a
reference to a list. Note that this method takes a reference to a list
instead.

=item C<-E<gt>first()>

Returns a new object representing the first useable IP address within
the subnet (ie, the first host address).

=item C<-E<gt>last()>

Returns a new object representing the last useable IP address within
the subnet (ie, one less than the broadcast address).


=item C<-E<gt>num()>

Returns the number of useable addresses IP addresses within the
subnet, not counting the broadcast address.

=back

=head2 EXPORT

None by default.


=head1 HISTORY

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

A spurious  warning when  expand()ing with -w  under certain
circumstances  was removed. This  involved using  /31s, /32s
and the same netmask as the input.  Thanks to Elie Rosenblum
for pointing it out.

=item *

Slight change  in license terms to ease  redistribution as a
Debian package.

=back


=item 3.00

=over

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

=back

=back


=head1 AUTHOR

Luis E. Munoz <lem@cantv.net>

=head1 WARRANTY

This software comes with the same warranty as perl itself (ie, none), so
by using it you accept any and all the liability.

=head1 LICENSE

This software is (c) Luis E. Munoz. It can be used under the terms of
the perl artistic license provided that proper credit for the work of
the author is preserved in the form of this copyright notice and
license for this module.

=head1 SEE ALSO

perl(1).

=cut
