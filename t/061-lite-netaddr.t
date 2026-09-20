#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

use NetAddr::IP::Lite ();

sub list2NetAddr {
    my ($inref, $outref) = @_;
    return undef
        unless ref $inref eq 'ARRAY'
        && ref $outref eq 'ARRAY';
    @$outref = ();
    no strict;
    unless ($SKIP_NetAddrIP) {
        require NetAddr::IP::Lite;
        $SKIP_NetAddrIP = 1;
    }
    for my $IP (@$inref) {
        $IP =~ s/\s//g;
        # 11.22.33.44
        if ($IP =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/o) {
            push @$outref, NetAddr::IP::Lite->new($IP), 0;
        }
        # 11.22.33.44 - 11.22.33.49
        elsif ($IP =~ /^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\s*\-\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)$/o) {
            push @$outref, NetAddr::IP::Lite->new($1), NetAddr::IP::Lite->new($2);
        }
        # 11.22.33.44/63
        elsif ($IP =~ m|^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$|) {
            push @$outref, NetAddr::IP::Lite->new($IP), 0;
        }
        # 11.22.33.44/255.255.255.224
        elsif ($IP =~ m|^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$|o) {
            push @$outref, NetAddr::IP::Lite->new($IP), 0;
        }
        # ignore un-matched IP patterns
    }
    return (scalar @$outref) / 2;
}

sub matchNetAddr {
    my ($ip, $naref) = @_;
    return 0 unless $ip && $ip =~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/;
    $ip =~ s/\s//g;
    $ip = NetAddr::IP::Lite->new($ip);
    for (my $i = 0; $i <= $#{$naref}; $i += 2) {
        my $beg = $naref->[$i];
        my $end = $naref->[$i + 1];
        if ($end) {
            return 1 if $ip >= $beg && $ip <= $end;
        }
        else {
            return 1 if $ip->within($beg);
        }
    }
    return 0;
}

## test 2	instantiate netaddr array
subtest 'list2NetAddr builds correct number of objects' => sub {
    my @tstrng = (
        # a single address
        '11.22.33.44',
        # a range of ip's, ONLY VALID WITHIN THE SAME CLASS 'C'
        '22.33.44.55 - 22.33.44.65',
        '45.67.89.10-45.67.89.32',
        # a CIDR range
        '5.6.7.16/28',
        # a range specified with a netmask
        '7.8.9.128/255.255.255.240',
        # this should ALWAYS be here
        '127.0.0.0/8',    # ignore all test entries and localhost
    );
    my @NAobject;
    my $rv = list2NetAddr(\@tstrng, \@NAobject);
    is($rv, 6, 'correct number of NA objects');
};

## test 3-5	check disallowed terms
subtest 'matchNetAddr rejects invalid inputs' => sub {
    ok(!matchNetAddr(), 'rejects null parameter');
    ok(!matchNetAddr('junk'), 'rejects non-numeric parameter');
    ok(!matchNetAddr('1.2.3'), 'rejects short IP segment');
};

## test 6-35	bracket NA objects
my @tstrng = (
    '11.22.33.44',
    '22.33.44.55 - 22.33.44.65',
    '45.67.89.10-45.67.89.32',
    '5.6.7.16/28',
    '7.8.9.128/255.255.255.240',
    '127.0.0.0/8',
);
my @NAobject;
list2NetAddr(\@tstrng, \@NAobject);

my @chkary =    # 5 x 6 tests
    #  out left    in left     middle      in right    out right
    qw(
    11.22.33.43   11.22.33.44   11.22.33.44   11.22.33.44   11.22.33.45
    22.33.44.54   22.33.44.55   22.33.44.60   22.33.44.65   22.33.44.66
    45.67.89.9    45.67.89.10   45.67.89.20   45.67.89.32   45.67.89.33
    5.6.7.15      5.6.7.16      5.6.7.20      5.6.7.31      5.6.7.32
    7.8.9.127     7.8.9.128     7.8.9.138     7.8.9.143     7.8.9.144
    126.255.255.255   127.0.0.0   127.128.128.128   127.255.255.255   128.0.0.0
    );

for (my $i = 0; $i <= $#chkary; $i += 5) {
    ok(
        !matchNetAddr($chkary[$i], \@NAobject),
        "accepted outside left bound $chkary[$i]"
    );
    ok(
        matchNetAddr($chkary[$i + 1], \@NAobject),
        "rejected inside left bound $chkary[$i + 1]"
    );
    ok(
        matchNetAddr($chkary[$i + 2], \@NAobject),
        "rejected inside middle bound $chkary[$i + 2]"
    );
    ok(
        matchNetAddr($chkary[$i + 3], \@NAobject),
        "rejected inside right bound $chkary[$i + 3]"
    );
    ok(
        !matchNetAddr($chkary[$i + 4], \@NAobject),
        "accepted outside right bound $chkary[$i + 4]"
    );
}

done_testing;
