use NetAddr::IP;

my @addr = ( [ '10.0.0.0', 20, 32, 4096 ],
	     [ '10.0.0.0', 22, 32, 1024 ],
	     [ '10.0.0.0', 24, 32, 256 ],
	     [ '10.0.0.0', 19, 32, 8192 ]
	    );

my $count = $| = 1;
print "1..", (scalar @addr), "\n";

for my $a (@addr) {
    my $ip = new NetAddr::IP $a->[0], $a->[1];
    my $r = $ip->splitref($a->[2]);

    if (scalar @$r == $a->[3]) {
	print "ok ", $count++, "\n";
    }
    else {
	print "not ok ", $count++, " (number $a)\n";
    }

}
