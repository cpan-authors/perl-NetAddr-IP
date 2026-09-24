#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;
use Test2::Tools::Exception qw(lives);

# the module must compile where the resolver answers nothing, for example
# the broken BSD gethostbyname noted in Util.pm, or any program that hooks
# the resolver

BEGIN { *CORE::GLOBAL::gethostbyname = sub { return wantarray ? () : undef } }

ok(lives { require NetAddr::IP; 1 }, 'NetAddr::IP loads with a resolver that answers nothing')
    or BAIL_OUT("NetAddr::IP did not load: $@");

is(NetAddr::IP->new('loopback')->cidr, '127.0.0.1/8',
    'the loopback mask built at load time is still 255.0.0.0');

done_testing;