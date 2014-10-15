package EmailNotifications::WorkFlow;

use strict;
use lib '.', '..';
use parent 'EmailNotifications::Notification';

sub new {
    my $class = shift;
    my (%args) = @_;

    return $class->SUPER::new(@_); 
}

1;
