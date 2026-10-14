#!/usr/bin/env perl

use Test2::V1 -ipP;
use Test2::Plugin::NoWarnings;

# load without Socket6, and with a Socket whose AF_INET6 croaks the way Socket's
# does where the platform headers do not define it, so AF_INET6 is the guess.
# Socket is stubbed rather than mocked because an inlinable constant cannot be
# redefined silently before perl 5.16, and perl 5.14 ships Socket 1.94.
BEGIN {
    my $stub = <<'STUB';
package Socket;
sub AF_INET () { 2 }
sub AF_INET6 () { die "Your vendor has not defined Socket macro AF_INET6\n" }
1;
STUB
    local @INC = (
        sub {
            my ( $hook, $file ) = @_;
            die "Socket6 hidden\n" if $file eq 'Socket6.pm';
            return unless $file eq 'Socket.pm';
            open my $fh, '<', \$stub or die "cannot read the Socket stub: $!\n";
            return $fh;
        },
        @INC
    );
    local $^O = 'darwin';
    require NetAddr::IP::InetBase;
}

is( NetAddr::IP::InetBase::AF_INET6(),
    30, 'AF_INET6 is the darwin guess when Socket and Socket6 lack it' );

is( NetAddr::IP::InetBase::fake_AF_INET6(),
    30, 'fake_AF_INET6 returns the guess' );

is(
    unpack( 'H*', NetAddr::IP::InetBase::inet_pton( 30, '2001:db8::1' ) ),
    '20010db8000000000000000000000001',
    'inet_pton takes the guessed AF_INET6'
);

done_testing;
