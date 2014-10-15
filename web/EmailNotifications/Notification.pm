package EmailNotifications::Notification;

use strict;
use lib '.', '..';
use Email;
use parent 'EmailNotifications::Template';
use Data::Dumper;

sub new {
    my $class = shift;
    my (%args) = @_;

    return $class->SUPER::new(@_); 
}

sub initialise {
    my ($self) = shift;

    $self->SUPER::retrieve();
    return $self;
}

sub send {

}

1;
