
use NetAddr::IP;

print <<EOF;
		Serializing IP Addresses
EOF
    ;

$addr[0] = "10.1.2.3/24";
$addr[1] = "161.196.66.2/20";
$addr[2] = "200.44.32.12/30";
$addr[3] = "200.11.128.1/24";
$addr[4] = "224.16.5.172/16";
$addr[5] = "255.255.255.255";
$addr[6] = "0.0.0.0";
$addr[7] = "1.0.0.0";
$addr[8] = "0.1.0.0";
$addr[9] = "0.0.1.0";
$addr[10] = "0.0.0.1";

foreach $i (@addr) {
    my $ip = new NetAddr::IP ($i);
    my @num = $ip->to_numeric;
    my $nip = new NetAddr::IP (@num);
    print ( "$i: ", $ip->to_string, " == ", $nip->to_string, " == ", 
	    join('/', ($ip->to_numeric)), "\n" );
}

