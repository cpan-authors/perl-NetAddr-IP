
use NetAddr::IP;

push @ips, (
    new NetAddr::IP("200.44.0.0/24"),
    new NetAddr::IP("200.44.1.0/24"),
    new NetAddr::IP("200.44.2.0/24"),
    new NetAddr::IP("200.44.2.0/23"),
    new NetAddr::IP("200.44.4.0/24"),
    new NetAddr::IP("10.0.0.0/24"),
    new NetAddr::IP("200.44.5.0/24"),
    new NetAddr::IP("200.44.6.0/24"),
    new NetAddr::IP("200.44.7.0/24"),
    new NetAddr::IP("200.44.8.0/26"),
    new NetAddr::IP("200.44.8.64/26"),
    new NetAddr::IP("200.44.8.128/26"),
    new NetAddr::IP("200.44.8.192/26"),
);
    
my @compacted = NetAddr::IP::compact(@ips);

foreach $net (@compacted) {
    print $net->to_string, "\n";
}

print "BECOMES\n";

my @expanded = NetAddr::IP::expand(25, @ips);

foreach $net (@expanded) {
    print $net->to_string, "\n";
}

print "Another Range\n";

foreach $net (new NetAddr::IP("10.0.0.0/24")->expand(28)) {
    print $net->to_string, "\n";
}





