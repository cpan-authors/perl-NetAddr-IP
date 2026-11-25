package Local::CountsText;

# an object whose text is fixed, counting how often its overloading reads it

use strict;
use warnings;

use overload
    q{""}    => sub { my ($self) = @_; $self->{calls}++; return $self->{text} },
    fallback => 1;

sub new {
    my ($class, $text) = @_;
    return bless { calls => 0, text => $text }, $class;
}

1;
