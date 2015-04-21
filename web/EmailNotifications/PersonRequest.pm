package EmailNotifications::PersonRequest;

use strict;
use lib '.', '..';
use Defs;
use Switch;
use Data::Dumper;
use parent 'EmailNotifications::Notification';

sub new {
    my $class = shift;
    my (%args) = @_;

    return $class->SUPER::new(@_); 
}

sub setNotificationType {
    my $self = shift;
    my ($requestType, $action) = @_;

    switch($requestType) {
        case "$Defs::PERSON_REQUEST_TRANSFER" {
            $self->SUPER::setNotificationType('NOTIFICATION_REQUESTTRANSFER_' . $action);
        }
        case "$Defs::PERSON_REQUEST_ACCESS" {
            $self->SUPER::setNotificationType('NOTIFICATION_REQUESTACCESS_' . $action);
        }
        case "$Defs::PERSON_REQUEST_LOAN" {
            $self->SUPER::setNotificationType('NOTIFICATION_REQUESTLOAN_' . $action);
        }
        else {
        }
    }
}

1;
