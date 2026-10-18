#!/bin/false
# ABSTRACT: Count addresses in named groups of subnets
# PODNAME: NetAddr::IP::Count

use strict;
use warnings;

package NetAddr::IP::Count;
# VERSION

use Carp qw(croak);
use Scalar::Util qw(blessed looks_like_number);

# the cache size NetAddr::IP::Count 2.01 reported for a new counter
my $DEFAULT_CACHE_SIZE = 5;

# what an argument must be, as the croak messages name it
my $WANT_ADDRESS = q{a NetAddr::IP object};
my $WANT_NUMBER  = q{a number};

sub new {
    my ( $proto, @pairs ) = @_;
    croak sprintf(
        '%s::new takes group name and subnet pairs, got %d arguments',
        __PACKAGE__, scalar @pairs )
        if @pairs % 2;
    my %groups = @pairs;
    my $self   = bless {
        cache_size => $DEFAULT_CACHE_SIZE,
        subnets    => {},
        totals     => {},
    }, ref $proto || $proto;
    $self->add( $_, $groups{$_} ) for keys %groups;
    return $self;
}

sub add {
    my ( $self, $name, @subnets ) = @_;
    croak sprintf( '%s::add needs a group name', __PACKAGE__ )
        unless defined $name;
    @subnets = @{ $subnets[0] }
        if @subnets == 1 && ref $subnets[0] eq 'ARRAY';
    for my $i ( 0 .. $#subnets ) {
        croak _bad_argument( 'add', $i + 2, $subnets[$i], $WANT_ADDRESS )
            unless _is_address( $subnets[$i] );
    }
    push @{ $self->{subnets}{$name} }, @subnets;
    $self->{totals}{$name} //= 0;
    return $self;
}

sub count {
    my ( $self, @addresses ) = @_;
    for my $i ( 0 .. $#addresses ) {
        croak _bad_argument( 'count', $i + 1, $addresses[$i], $WANT_ADDRESS )
            unless _is_address( $addresses[$i] );
    }
    $self->_add_to_totals( $_, 1 ) for @addresses;
    return $self;
}

sub valcount {
    my ( $self, @pairs ) = @_;
    croak sprintf(
        '%s::valcount takes address and value pairs, got %d arguments',
        __PACKAGE__, scalar @pairs )
        if @pairs % 2;
    for my $i ( 0 .. $#pairs ) {
        if ( $i % 2 ) {
            croak _bad_argument( 'valcount', $i + 1, $pairs[$i], $WANT_NUMBER )
                unless looks_like_number( $pairs[$i] );
        }
        else {
            croak _bad_argument( 'valcount', $i + 1, $pairs[$i], $WANT_ADDRESS )
                unless _is_address( $pairs[$i] );
        }
    }
    while ( my ( $address, $value ) = splice @pairs, 0, 2 ) {
        $self->_add_to_totals( $address, $value );
    }
    return $self;
}

sub result {
    my ($self) = @_;
    return { %{ $self->{totals} } };
}

sub cache {
    my ( $self, @size ) = @_;
    my $old = $self->{cache_size};
    if (@size) {
        croak _bad_argument( 'cache', 1, $size[0], $WANT_NUMBER )
            unless looks_like_number( $size[0] );
        $self->{cache_size} = $size[0] if $size[0] >= 0;
    }
    return $old;
}

# every group with a subnet that contains the address takes the value, once
sub _add_to_totals {
    my ( $self, $address, $value ) = @_;
    my $subnets = $self->{subnets};
  GROUP:
    for my $name ( keys %{$subnets} ) {
        for my $subnet ( @{ $subnets->{$name} } ) {
            next unless $subnet->contains($address);
            $self->{totals}{$name} += $value;
            next GROUP;
        }
    }
    return;
}

sub _is_address {
    my ($arg) = @_;
    return blessed($arg) && $arg->isa('NetAddr::IP::Lite');
}

sub _bad_argument {
    my ( $method, $position, $arg, $wanted ) = @_;
    my $got
        = !defined $arg ? 'undefined'
        : ref $arg      ? ref $arg
        :                 "'$arg'";
    return sprintf( '%s::%s needs %s for argument %d, got %s',
        __PACKAGE__, $method, $wanted, $position, $got );
}

1;

__END__
=head1 SYNOPSIS

  use NetAddr::IP;
  use NetAddr::IP::Count;

  my $counter = NetAddr::IP::Count->new(
      customers => NetAddr::IP->new('198.51.100.0/24'),
      lab       => [
          NetAddr::IP->new('203.0.113.0/25'),
          NetAddr::IP->new('2001:db8::/32'),
      ],
  );
  $counter->add( 'customer-a' => NetAddr::IP->new('198.51.100.0/28') );

  $counter->count( map { NetAddr::IP->new($_) }
        qw(198.51.100.1 198.51.100.77 2001:db8::1) );
  $counter->valcount( NetAddr::IP->new('203.0.113.9'), 5 );

  my $totals = $counter->result;
  print "$_ $totals->{$_}\n" for sort keys %{$totals};
  # customer-a 1
  # customers 2
  # lab 6

=head1 DESCRIPTION

Counts how many addresses fall in each named group of subnets, for example
the visits in a web server log from each customer's networks.  A group is a
name and one or more NetAddr::IP subnets.

Each address counted adds to the total of every group with a subnet that
contains it, once per group.  Overlapping groups therefore each see the
address: in the synopsis, 198.51.100.1 counts for both customers and
customer-a.  The totals do not depend on the order the groups were added or
the addresses were counted, and with overlapping groups they add up to more
than the number of addresses counted.

A subnet contains an address when C<< $subnet->contains($address) >> is
true, so an IPv4 address never counts in an IPv6 subnet, and the other way
round.

This module has the interface of NetAddr::IP::Count 2.01, by Luis E. Munoz
with C<valcount> by Alvaro Carvajal, and replaces it.  Where no two groups
overlap, the totals are the same.  Three things differ:

=over 4

=item *

Overlapping groups.  Version 2.01 counted an address in one group only, and
which group depended on hash order, the order of the addresses and the cache
size.

=item *

Arguments.  Anything but a NetAddr::IP object where an address or subnet is
expected, or anything but a number where a value is expected, croaks before
any total changes.  Version 2.01 stopped counting at the first false
element of a list.

=item *

The cache.  The C<cache> method keeps its interface, but the size no longer
changes how addresses are counted or how fast.

=back

=head2 Constructor

=over 4

=item C<< NetAddr::IP::Count->new(%groups) >>

Returns a new counter holding the given groups, each with a total of zero.
Each key is a group name, and each value is a NetAddr::IP subnet or a
reference to an array of them, as C<add> takes.  Croaks on an odd number of
arguments or on a subnet that is not a NetAddr::IP object.  Called on a
counter, it returns a new, empty counter of the same class.

  my $counter = NetAddr::IP::Count->new(
      lab => NetAddr::IP->new('203.0.113.0/24') );
  print join( ',', keys %{ $counter->result } ), "\n";    # lab

=back

=head2 Groups

=over 4

=item C<< ->add($name, @subnets) >>

=item C<< ->add($name, \@subnets) >>

Adds the subnets to the group called C<$name>, creating the group with a
total of zero if it is new, and returns the counter.  Croaks when C<$name> is
undefined or a subnet is not a NetAddr::IP object.

  $counter->add( lab => NetAddr::IP->new('2001:db8::/32') );

=back

=head2 Counting

=over 4

=item C<< ->count(@addresses) >>

Adds one to the total of every group with a subnet that contains each
address, once per group, and returns the counter.  Croaks, changing no
total, when any element is not a NetAddr::IP object.

  $counter->count( NetAddr::IP->new('198.51.100.1') );

=item C<< ->valcount($address, $value, ...) >>

Works as C<count> does, but adds the value paired with each address instead
of one.  Croaks, changing no total, on an odd number of arguments, an address
that is not a NetAddr::IP object, or a value that is not a number.

  $counter->valcount( NetAddr::IP->new('203.0.113.9'), 5 );

=back

=head2 Results

=over 4

=item C<< ->result >>

Returns a new hash reference from each group name to its total, including
the groups whose total is zero.  Changing that hash does not change the
counter.

  my $totals = $counter->result;
  print $totals->{lab}, "\n";    # 6, after the synopsis

=item C<< ->cache($size) >>

=item C<< ->cache >>

Returns the cache size before the call, 5 for a new counter, and sets it to
C<$size> when C<$size> is zero or more.  The size is kept for compatibility
with NetAddr::IP::Count 2.01 and does not affect counting.  Croaks when
C<$size> is given and is not a number.

  my $old = $counter->cache(10);    # 5

=back

=head1 SEE ALSO

L<NetAddr::IP>

=cut
