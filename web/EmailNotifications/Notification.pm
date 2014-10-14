package Notification;

use strict;

sub new {
    my ($class, %args) = @_;

    my $self = {
        _realmID            => $args{realmID},
        _entityID           => $args{entityID},
        _notificationType   => $args{entityID},
        _lang               => $args{lang} || undef,
        _htmlTemplatePath   => $args{htmlTemplatePath} || undef,
        _textTemplatePath   => $args{textTemplatePath} || undef,
        _subject            => $args{subject} || undef,
    };

    $self = bless ($self, $class);

    return $self;
}

sub initialise {

}

sub send {

}
