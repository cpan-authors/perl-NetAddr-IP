
# Test if the module will load correctly

# $Id: 00-load.t,v 1.2 2002/10/31 04:30:35 lem Exp $

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use NetAddr::IP;
$loaded = 1;
print "ok 1\n";

