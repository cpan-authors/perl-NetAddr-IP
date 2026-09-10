# NetAddr::IP

Manages IPv4 and IPv6 addresses and subnets.

## Synopsis

    use NetAddr::IP qw(Compact Coalesce);

    my $ip = NetAddr::IP->new('192.168.1.123/24');
    print $ip->network;    # 192.168.1.0/24
    print $ip->broadcast;  # 192.168.1.255/24

    # IPv6 works the same way
    my $ip6 = NetAddr::IP->new('fe80::1/64');
    print $ip6->network;   # fe80::/64

## Module Hierarchy

The distribution provides four modules, each adding a layer of functionality:

- **NetAddr::IP::InetBase** -- low-level inet address conversion (mostly XS).
  `inet_aton`, `inet_ntoa`, `ipv6_aton`, `ipv6_ntoa`, `inet_pton`, `inet_ntop`, etc.

- **NetAddr::IP::Util** -- 128-bit math and address utilities (XS with Pure Perl
  fallback). `add128`, `sub128`, `bin2bcd`, `bcd2bin`, `ipv4to6`, `ipv6to4`,
  `naip_gethostbyname`, etc.

- **NetAddr::IP::Lite** -- core IP objects with overloaded operators, basic
  arithmetic, and subnet queries. `new`, `addr`, `mask`, `broadcast`, `network`,
  `contains`, `within`, `first`, `last`, `nth`, `num`, etc.

- **NetAddr::IP** -- advanced operations on subnets. `split`, `rsplit`,
  `hostenum`, `compact`, `compactref`, `coalesce`, `re`, `re6`, `wildcard`,
  `short`, `full`, `full6`.

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

## Methods

### Constructor

    $ip = NetAddr::IP->new($addr, $mask);
    $ip = NetAddr::IP->new6($addr, $mask);
    $ip = NetAddr::IP->new6FFFF($addr, $mask);
    $ip = NetAddr::IP->new_no($addr, $mask);       # filters leading octal zeros
    $ip = NetAddr::IP->new_from_aton($packed);     # from inet_aton output

`$addr` accepts IPv4, IPv6, CIDR notation, prefix notation, FQDN, and several
other formats. See the full documentation in the module POD.

### Accessors

    $ip->addr        # address as string
    $ip->mask        # mask as string
    $ip->masklen     # number of prefix bits
    $ip->bits        # address width (32 or 128)
    $ip->version     # 4 or 6
    $ip->cidr        # addr/masklen
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
    $ip->is_local           # true for 127.x.x.x or ::1

### Host Enumeration

    $ip->first      # first usable host address
    $ip->last       # last usable host address
    $ip->nth($n)    # n-th usable host address
    $ip->num        # count of usable host addresses

### Advanced (NetAddr::IP only)

    NetAddr::IP->split($base, $bits)     # split into subnets
    NetAddr::IP->rsplit($base, $target)  # reverse split
    $ip->splitref($bits)                 # return split as arrayref
    NetAddr::IP->hostenum($ips)          # enumerate hosts across subnets
    NetAddr::IP->compact(@ips)           # merge adjacent subnets
    NetAddr::IP->compactref(\@ips)       # compact returning arrayref
    NetAddr::IP->coalesce(@ips)          # merge overlapping subnets
    $ip->re                              # regex for IPv4 addresses in subnet
    $ip->re6                             # regex for IPv6 addresses in subnet
    $ip->wildcard                        # wildcard mask notation
    $ip->short                           # short address notation
    $ip->full                            # full expanded IPv4
    $ip->full6                           # full expanded IPv6

### Overloaded Operators

`+`, `-`, `++`, `--`, `=`, `""`, `eq`, `ne`, `==`, `!=`, `>`, `>=`, `<`, `<=`,
`cmp`, `<=>`

## Export Tags

    :upper   IPv6 addresses in uppercase (default)
    :lower   IPv6 addresses in lowercase (RFC 5952 recommended)
    :old_nth legacy nth/num behavior
    :nofqdn  disable FQDN resolution

## Authors

Luis E. Munoz <luismunoz@cpan.org>, Michael Robinton <michael@bizsystems.com>

## License

Dual licensed under the GNU GPL v2 and the Artistic License.
See [Copying](Copying) and [Artistic](Artistic) for details.
