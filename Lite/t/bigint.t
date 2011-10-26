
use strict;
#use diagnostics;
use Test::More;

use NetAddr::IP::Lite;

use Data::Dumper;

BEGIN {
  unless ( eval { require Math::BigInt::Calc }) {
    print "1..1\n";
    print "ok 1	# skip all tests, Math::BigInt::Calc not found!\n";
    exit;
  }
}

# good test results go here
my $build = q|
not ok 1
#   Failed test in test.pl at line 39.
#          got: '4294967294'
#     expected: undef
not ok 2
#   Failed test in test.pl at line 41.
#          got: '255.255.255.254/32'
#     expected: undef
not ok 3
#   Failed test in test.pl at line 39.
#          got: '4294967295'
#     expected: undef
not ok 4
#   Failed test in test.pl at line 41.
#          got: '255.255.255.255/32'
#     expected: undef
not ok 5
#   Failed test in test.pl at line 39.
#          got: '4294967296'
#     expected: undef
not ok 6
#   Failed test in test.pl at line 41.
#          got: '0:0:0:0:0:1:0:0/128'
#     expected: undef
not ok 7
#   Failed test in test.pl at line 39.
#          got: '4294967297'
#     expected: undef
not ok 8
#   Failed test in test.pl at line 41.
#          got: '0:0:0:0:0:1:0:1/128'
#     expected: undef
not ok 9
#   Failed test in test.pl at line 39.
#          got: '4294967298'
#     expected: undef
not ok 10
#   Failed test in test.pl at line 41.
#          got: '0:0:0:0:0:1:0:2/128'
#     expected: undef
not ok 11
#   Failed test in test.pl at line 39.
#          got: '340282366920938463463374607431768211454'
#     expected: undef
not ok 12
#   Failed test in test.pl at line 41.
#          got: 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE/128'
#     expected: undef
not ok 13
#   Failed test in test.pl at line 39.
#          got: '340282366920938463463374607431768211455'
#     expected: undef
not ok 14
#   Failed test in test.pl at line 41.
#          got: 'FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF/128'
#     expected: undef
not ok 15
#   Failed test in test.pl at line 39.
#          got: '340282366920938463463374607431768211456'
#     expected: undef
not ok 16
#   Failed test in test.pl at line 41.
#          got: '0.0.0.0/32'
#     expected: undef
not ok 17
#   Failed test in test.pl at line 39.
#          got: '1'
#     expected: undef
not ok 18
#   Failed test in test.pl at line 41.
#          got: '0.0.0.1/32'
#     expected: undef
not ok 19
#   Failed test in test.pl at line 39.
#          got: '2'
#     expected: undef
not ok 20
#   Failed test in test.pl at line 41.
#          got: '0.0.0.2/32'
#     expected: undef
not ok 21
#   Failed test in test.pl at line 63.
#          got: '2066563929'
#     expected: undef
not ok 22
#   Failed test in test.pl at line 64.
#          got: '4294967295'
#     expected: undef
not ok 23
#   Failed test in test.pl at line 65.
#          got: '123.45.67.89/32'
#     expected: undef
not ok 24
#   Failed test in test.pl at line 63.
#          got: '2066563929'
#     expected: undef
not ok 25
#   Failed test in test.pl at line 64.
#          got: '4294967280'
#     expected: undef
not ok 26
#   Failed test in test.pl at line 65.
#          got: '123.45.67.89/28'
#     expected: undef
not ok 27
#   Failed test in test.pl at line 63.
#          got: '2066563929'
#     expected: undef
not ok 28
#   Failed test in test.pl at line 64.
#          got: '4294967040'
#     expected: undef
not ok 29
#   Failed test in test.pl at line 65.
#          got: '123.45.67.89/24'
#     expected: undef
not ok 30
#   Failed test in test.pl at line 63.
#          got: '2066563929'
#     expected: undef
not ok 31
#   Failed test in test.pl at line 64.
#          got: '4294963200'
#     expected: undef
not ok 32
#   Failed test in test.pl at line 65.
#          got: '123.45.67.89/20'
#     expected: undef
not ok 33
#   Failed test in test.pl at line 63.
#          got: '2066563929'
#     expected: undef
not ok 34
#   Failed test in test.pl at line 64.
#          got: '4294901760'
#     expected: undef
not ok 35
#   Failed test in test.pl at line 65.
#          got: '123.45.67.89/16'
#     expected: undef
not ok 36
#   Failed test in test.pl at line 63.
#          got: '2066563929'
#     expected: undef
not ok 37
#   Failed test in test.pl at line 64.
#          got: '4293918720'
#     expected: undef
not ok 38
#   Failed test in test.pl at line 65.
#          got: '123.45.67.89/12'
#     expected: undef
not ok 39
#   Failed test in test.pl at line 63.
#          got: '2066563929'
#     expected: undef
not ok 40
#   Failed test in test.pl at line 64.
#          got: '4278190080'
#     expected: undef
not ok 41
#   Failed test in test.pl at line 65.
#          got: '123.45.67.89/8'
#     expected: undef
not ok 42
#   Failed test in test.pl at line 63.
#          got: '2066563929'
#     expected: undef
not ok 43
#   Failed test in test.pl at line 64.
#          got: '4026531840'
#     expected: undef
not ok 44
#   Failed test in test.pl at line 65.
#          got: '123.45.67.89/4'
#     expected: undef
not ok 45
#   Failed test in test.pl at line 63.
#          got: '2066563929'
#     expected: undef
not ok 46
#   Failed test in test.pl at line 64.
#          got: '0'
#     expected: undef
not ok 47
#   Failed test in test.pl at line 65.
#          got: '123.45.67.89/0'
#     expected: undef
not ok 48
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 49
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607431768211455'
#     expected: undef
not ok 50
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/128'
#     expected: undef
not ok 51
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 52
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607431768211440'
#     expected: undef
not ok 53
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/124'
#     expected: undef
not ok 54
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 55
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607431768211200'
#     expected: undef
not ok 56
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/120'
#     expected: undef
not ok 57
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 58
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607431768207360'
#     expected: undef
not ok 59
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/116'
#     expected: undef
not ok 60
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 61
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607431768145920'
#     expected: undef
not ok 62
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/112'
#     expected: undef
not ok 63
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 64
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607431767162880'
#     expected: undef
not ok 65
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/108'
#     expected: undef
not ok 66
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 67
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607431751434240'
#     expected: undef
not ok 68
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/104'
#     expected: undef
not ok 69
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 70
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607431499776000'
#     expected: undef
not ok 71
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/100'
#     expected: undef
not ok 72
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 73
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607427473244160'
#     expected: undef
not ok 74
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/96'
#     expected: undef
not ok 75
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 76
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374607363048734720'
#     expected: undef
not ok 77
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/92'
#     expected: undef
not ok 78
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 79
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374606332256583680'
#     expected: undef
not ok 80
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/88'
#     expected: undef
not ok 81
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 82
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374589839582167040'
#     expected: undef
not ok 83
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/84'
#     expected: undef
not ok 84
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 85
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463374325956791500800'
#     expected: undef
not ok 86
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/80'
#     expected: undef
not ok 87
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 88
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463370103832140840960'
#     expected: undef
not ok 89
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/76'
#     expected: undef
not ok 90
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 91
#   Failed test in test.pl at line 64.
#          got: '340282366920938463463302549837730283520'
#     expected: undef
not ok 92
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/72'
#     expected: undef
not ok 93
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 94
#   Failed test in test.pl at line 64.
#          got: '340282366920938463462221685927161364480'
#     expected: undef
not ok 95
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/68'
#     expected: undef
not ok 96
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 97
#   Failed test in test.pl at line 64.
#          got: '340282366920938463444927863358058659840'
#     expected: undef
not ok 98
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/64'
#     expected: undef
not ok 99
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 100
#   Failed test in test.pl at line 64.
#          got: '340282366920938463168226702252415385600'
#     expected: undef
not ok 101
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/60'
#     expected: undef
not ok 102
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 103
#   Failed test in test.pl at line 64.
#          got: '340282366920938458741008124562122997760'
#     expected: undef
not ok 104
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/56'
#     expected: undef
not ok 105
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 106
#   Failed test in test.pl at line 64.
#          got: '340282366920938387905510881517444792320'
#     expected: undef
not ok 107
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/52'
#     expected: undef
not ok 108
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 109
#   Failed test in test.pl at line 64.
#          got: '340282366920937254537554992802593505280'
#     expected: undef
not ok 110
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/48'
#     expected: undef
not ok 111
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 112
#   Failed test in test.pl at line 64.
#          got: '340282366920919120650260773364972912640'
#     expected: undef
not ok 113
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/44'
#     expected: undef
not ok 114
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 115
#   Failed test in test.pl at line 64.
#          got: '340282366920628978453553262363043430400'
#     expected: undef
not ok 116
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/40'
#     expected: undef
not ok 117
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 118
#   Failed test in test.pl at line 64.
#          got: '340282366915986703306233086332171714560'
#     expected: undef
not ok 119
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/36'
#     expected: undef
not ok 120
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 121
#   Failed test in test.pl at line 64.
#          got: '340282366841710300949110269838224261120'
#     expected: undef
not ok 122
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/32'
#     expected: undef
not ok 123
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 124
#   Failed test in test.pl at line 64.
#          got: '340282365653287863235145205935065006080'
#     expected: undef
not ok 125
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/28'
#     expected: undef
not ok 126
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 127
#   Failed test in test.pl at line 64.
#          got: '340282346638528859811704183484516925440'
#     expected: undef
not ok 128
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/24'
#     expected: undef
not ok 129
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 130
#   Failed test in test.pl at line 64.
#          got: '340282042402384805036647824275747635200'
#     expected: undef
not ok 131
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/20'
#     expected: undef
not ok 132
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 133
#   Failed test in test.pl at line 64.
#          got: '340277174624079928635746076935438991360'
#     expected: undef
not ok 134
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/16'
#     expected: undef
not ok 135
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 136
#   Failed test in test.pl at line 64.
#          got: '340199290171201906221318119490500689920'
#     expected: undef
not ok 137
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/12'
#     expected: undef
not ok 138
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 139
#   Failed test in test.pl at line 64.
#          got: '338953138925153547590470800371487866880'
#     expected: undef
not ok 140
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/8'
#     expected: undef
not ok 141
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 142
#   Failed test in test.pl at line 64.
#          got: '319014718988379809496913694467282698240'
#     expected: undef
not ok 143
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/4'
#     expected: undef
not ok 144
#   Failed test in test.pl at line 63.
#          got: '170145699920964442595609400891477785294'
#     expected: undef
not ok 145
#   Failed test in test.pl at line 64.
#          got: '0'
#     expected: undef
not ok 146
#   Failed test in test.pl at line 65.
#          got: '8000:DEAD:BEEF:4:CAFE:BAD:2:FACE/0'
#     expected: undef

|;

my @exp;

my @build = split("\n",$build);
foreach (@build) {
  next unless $_ =~ /got:\s+'(.+)'/;
  push @exp, $1;
}

my $ptr = 0;
my $max = @exp;
plan tests => $max || 1;

my $ip = new NetAddr::IP::Lite('255.255.255.253');

sub run {
  foreach(1..5) {
    my $mbi = $ip->bigint();
    $mbi++;
    is($mbi, $exp[$ptr++]);
    $ip = new NetAddr::IP::Lite($mbi);
    is($ip, $exp[$ptr++]);
  }
}

run();
$ip = new NetAddr::IP::Lite('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFD');
run();

sub mrun {
  my ($jump) = @_;
  my($mbia,$mbim) = $ip->bigint();

#print $ip,"\n";
#print Dumper $mbia;
#print Dumper $mbim;

  $ip = new NetAddr::IP::Lite($mbia,$mbim);

  while(1) {
    ($mbia,$mbim) = $ip->bigint();
    my($ary,$msk,$eip) = @exp[$ptr,$ptr+1,$ptr+2];
    $ptr += 3;
    is($mbia, $ary);
    is($mbim, $msk);
    is($ip, $eip);
    my $len = $ip->masklen();
    last unless $len;
    last if $ptr > $max + 200;		# loop stop, just in case
    $mbim *= $jump;
    $ip = new NetAddr::IP::Lite($mbia,$mbim);
  }
}

$ip = new NetAddr::IP::Lite('123.45.67.89');
mrun(16);

$ip = new NetAddr::IP::Lite('8000:dead:beef:4:cafe:bad:2:face');

mrun(16);
