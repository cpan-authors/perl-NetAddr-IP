# I know this does not look like -*- perl -*-, but I swear it is...

use NetAddr::IP;
use strict;

$| = 1;

our @badnets = (
		'10.10.10.10/255.255.0.255',
		'10.10.10.10/255.0.255.255',
		'10.10.10.10/0.255.255.255',
		'10.10.10.10/128.255.0.255',
		'10.10.10.10/255.128.0.255',
		'10.10.10.10/255.255.255.129',
		'10.10.10.10/255.255.129.0',
		'10.10.10.10/255.255.255.130',
		'10.10.10.10/255.255.130.0',
		'10.10.10.10/255.0.0.1',
		'10.10.10.10/255.129.0.1',
		'10.10.10.10/0.255.0.255',
		);

our @goodnets = ();

push @goodnets, "10.0.0.1/$_" for (0 .. 32);
push @goodnets, "10.0.0.1/255.255.255.255";

print '1..', (scalar @badnets + scalar @goodnets) , "\n";

my $count = 1;

for my $bad (@badnets) {

    if (defined NetAddr::IP->new($bad)) {
	print "not ok $count # $bad should fail but succeeded\n";
    }
    else {
	print "ok $count # $bad must fail\n";
    }

    ++ $count;
}

for my $good (@goodnets) {

    if (defined NetAddr::IP->new($good)) {
	print "ok $count # $good should not fail\n";
    }
    else {
	print "not ok $count # $good must not fail\n";
    }

    ++ $count;
}


