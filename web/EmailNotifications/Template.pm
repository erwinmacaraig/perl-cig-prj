package Template;

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

sub getRealmID {
    my ($self) = shift;
    return $self->{_realmID};
}

sub getEntityID {
    my ($self) = shift;
    return $self->{_entityID};
}

sub getNotificationType {
    my ($self) = shift;
    return $self->{_notificationType};
}

sub getLang {
    my ($self) = shift;
    return $self->{_lang};
}

sub retrieveTemplate {

    #method chain
    return $self;
}

sub compose {

    #call after retrieveTemplate
    return;
}

sub setRealmID {
    my ($self, $realmID) = @_;
    $self->{_realmID} = $realmID if defined $realmID;
}

sub setEntityID {
    my ($self, $entityID) = @_;
    $self->{_entityID} = $entityID if defined $entityID;
}

sub setNotificatonType {
    my ($self, $notificationType) = @_;
    $self->{_notificationType} = $notificationType if defined $notificationType;
}

sub setLang {
    my ($self, $lang) = @_;
    $self->{_lang} = $lang if defined $lang;
}
