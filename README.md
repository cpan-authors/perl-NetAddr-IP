# NetAddr::IP

Manages IPv4 and IPv6 addresses and subnets.

## Synopsis

    use NetAddr::IP qw(Compact Coalesce);

    my $ip = NetAddr::IP->new('192.0.2.123/24');
    print $ip->network;    # 192.0.2.0/24
    print $ip->broadcast;  # 192.0.2.255/24

    # IPv6 works the same way
    my $ip6 = NetAddr::IP->new('2001:db8::1/64');
    print $ip6->network;   # 2001:DB8:0:0:0:0:0:0/64
    print $ip6->broadcast; # 2001:DB8:0:0:0:FFFF:FFFF:FFFF:FFFF/64

The addresses above are from RFC 5737 and RFC 3849, the documentation
ranges, so they are safe to paste anywhere.

## Modules

Six modules ship in the distribution, each adding a layer:

- **NetAddr::IP::Constants** — named constants for the magic numbers used
  elsewhere: widths, octet counts, the netlimit exponents, the packed BCD
  size.

- **NetAddr::IP::InetBase** — low-level address conversion, **pure Perl on
  every host**: `inet_aton`, `inet_ntoa`, `ipv6_aton`, `ipv6_ntoa`,
  `inet_pton`, `inet_ntop`, `packzeros`, `isIPv4`, `isNewIPv4`, `isAnyIPv4`.

- **NetAddr::IP::UtilPP** — the pure Perl implementation of the 128-bit
  arithmetic, compiled in when the distribution is built with `-noxs`.

- **NetAddr::IP::Util** — that same arithmetic, XS with the pure Perl
  fallback: `shiftleft`, `add128`, `sub128`, `addconst`, `notcontiguous`,
  `bin2bcd`, `bcd2bin`, `ipv4to6`, `ipv6to4`, `naip_gethostbyname`. It
  takes `inet_pton`, `inet_ntop` and `AF_INET6` from Socket6 when that is
  installed, which is a recommendation rather than a requirement.

- **NetAddr::IP::Lite** — core IP objects with overloaded operators, basic
  arithmetic and subnet queries: `new`, `addr`, `mask`, `broadcast`,
  `network`, `contains`, `within`, `first`, `last`, `nth`, `num`.

- **NetAddr::IP** — the advanced operations on subnets: `split`, `rsplit`,
  `hostenum`, `compact`, `coalesce`, `re`, `re6`, `wildcard`, `short`,
  `full`, `full6`.

`NetAddr::IP` subclasses `NetAddr::IP::Lite`, so anything the base class can
do it can do too. `NetAddr::IP::Util_IS` is generated at build time and
records which implementation is active; `mode()` reports it at runtime.

## Installation

    perl Makefile.PL
    make
    make test
    make install

### Pure Perl (no C compiler)

    perl Makefile.PL -noxs
    make
    make test
    make install

`mode()` then returns `Pure Perl` instead of `CC XS`. On Windows the build
selects pure Perl automatically, since the C toolchain is not required to
run the suite.

## Methods

### Constructor

    $ip = NetAddr::IP->new($addr, $mask);
    $ip = NetAddr::IP->new6($addr, $mask);
    $ip = NetAddr::IP->new6FFFF($addr, $mask);
    $ip = NetAddr::IP->new_no($addr, $mask);       # filters leading octal zeros
    $ip = NetAddr::IP->new_from_aton($packed);     # from inet_aton output

`$addr` accepts IPv4, IPv6, CIDR, prefix, range and bracketed notation, an
FQDN, and several other forms. Two are worth knowing about:

    NetAddr::IP->new('10.1');         # 10.0.0.1/32
    NetAddr::IP->new('10.1', 8);      # 10.1.0.0/8

A short dotted form is a host address on its own and the start of a network
when a mask is given. See the constructor entry in the module POD for the
rest.

### Accessors

    $ip->addr        # address as string
    $ip->mask        # mask as string
    $ip->masklen     # number of prefix bits
    $ip->bits        # address width (32 or 128)
    $ip->version     # 4 or 6
    $ip->cidr        # addr/masklen, and what the object stringifies to
    $ip->aton        # packed binary address
    $ip->broadcast   # broadcast address
    $ip->network     # network address
    $ip->range       # "addr - broadcast"
    $ip->numeric     # numeric address (and mask in list context)
    $ip->bigint      # Math::BigInt representation

### Predicates

    $ip->contains($other)   # true if $ip fully contains $other
    $ip->within($other)     # true if $ip is fully within $other
    $ip->is_rfc1918         # true for 10/8, 172.16/12, 192.168/16
    $ip->is_local           # true for 127.0.0.0/8, ::1, ::127.0.0.0/8
                            # and ::ffff:127.0.0.0/8

An IPv4 loopback address held in an IPv6 object is still local:

    NetAddr::IP->new('::ffff:127.0.0.1')->is_local;   # true

### Host enumeration

    $ip->first      # first usable host address
    $ip->last       # last usable host address
    $ip->nth($n)    # n-th usable host address
    $ip->num        # count of usable host addresses

A /31 or /127 counts as two usable addresses, per RFC 3021, and a /32 or
/128 as one. `hostenum()` and `hostenumref()` agree with `first`, `last`,
`nth` and `num` on all of those.

### Advanced (NetAddr::IP only)

These are methods on an object, not functions called on the class name:

    $ip->split(26)                # 192.0.2.0/26, 192.0.2.64/26, ...
    $ip->rsplit(28, 29, 28, 29, 26)   # the plan applied in reverse
    $ip->splitref(26)             # the same, as an arrayref
    $ip->rsplitref(28, 29, 28, 29, 26)
    $ip->hostenum                 # every usable address
    $ip->hostenumref              # the same, as an arrayref
    $ip->compact(@other)          # merge adjacent subnets, returns a list
    $ip->compactref(\@other)      # the same, returns an arrayref
    $ip->coalesce($masklen, $number, @other)   # summarise, returns an arrayref
    $ip->re                       # regex matching addresses in this subnet
    $ip->re6                      # the same for IPv6
    $ip->wildcard                 # wildcard mask notation
    $ip->short                    # compressed address notation
    $ip->canon                    # RFC 5952 s4.1 to 4.3, lowercase
    $ip->full                     # full expanded IPv4
    $ip->full6                    # full expanded IPv6

A split plan whose parts do not add up to the subnet croaks rather than
returning undef:

    NetAddr::IP->new('192.0.2.0/24')->split(16);
    # netmask error: overrange or spurious bits

`rsplit` differs from `split` only in the order the plan is applied:

    my @plan = (28, 29, 28, 29, 26);
    # splitref gives  0/28, 16/29, 24/28, 40/29, 48/26, 112/26, 176/26, 240/28
    # rsplitref gives 0/28, 16/26, 80/26, 144/26, 208/29, 216/28, 232/29, 240/28

### Functions

    use NetAddr::IP qw(Compact Coalesce netlimit);

    Compact($a, $b);                 # 192.0.2.0/24, merging two /25s
    Coalesce(24, 2, $a, $b);         # the same, as an arrayref
    netlimit(20);                    # 1048576, the max nets to process

`Compact` and `Coalesce` are what the method forms call. `netlimit` sets
the ceiling past which `hostenum` dies with `netlimit exceeded`, and
returns the new limit, or undef if the request was ignored. It accepts a
power of 2 from 16 (the default) to 24.

### Overloaded operators

`+`, `-`, `++`, `--`, `=`, `""`, `eq`, `ne`, `==`, `!=`, `>`, `>=`, `<`, `<=`,
`cmp`, `<=>`

`@{...}` is overloaded too, and gives the host list:

    my @hosts = @{ NetAddr::IP->new('192.0.2.0/28') };   # 14 addresses

Negation and `abs` croak, since neither means anything for an address:

    -$ip;      # cannot negate a NetAddr::IP object
    abs $ip;   # cannot take the absolute value of a NetAddr::IP object

Comparisons run on the 128-bit form: address first, then the mask as a
number, so at the same address `/24` sorts after `/16`. That is
predictable but not the order that ranks netblocks by size; compare
`masklen` for that.

## Import tags

Every tag is process-wide: it changes behaviour for the whole program, not
for one object.

    :upper          IPv6 addresses in uppercase (default)
    :lower          IPv6 addresses in lowercase (RFC 5952 s4.3)
    :old_storable   read legacy Storable files (deprecated)
    :old_nth        legacy nth/num behaviour (deprecated)
    :nofqdn         do not resolve FQDNs in the constructor
    :aton           accept packed input (deprecated)
    :rfc3021        the pre-4.080 /31 and /127 behaviour (deprecated, no
                    longer needed since hostenum returns two hosts anyway)

The default case setting is a process global in
`NetAddr::IP::InetBase`, so an unrelated package importing `:lower` changes
the output for everyone. `ipv6_ntoa` and `inet_ntop` are always lowercase
whatever the setting, since they mirror the platform's `inet_ntop`.

## Authors

Dean Hamstead <dean@fragfest.com.au>, Luis E. Muñoz <luismunoz@cpan.org>,
Michael Robinton <miker@cpan.org>

## License

Dual licensed under the GNU GPL v2 and the Artistic License.
See [Copying](Copying) and [Artistic](Artistic) for details.
