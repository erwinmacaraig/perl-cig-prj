package EmailNotifications::Notification;

use strict;
use lib '.', '..';
#use Email;
use TemplateEmail;
use EmailNotifications::Template;
use Data::Dumper;

sub new {
    my $class = shift;
    my (%args) = @_;

    my $self = {
        _realmID            => $args{realmID},
        _subRealmID         => $args{subRealmID},
        _fromEntityID       => $args{fromEntityID} || undef,
        _fromSelfUserID     => $args{fromSelfUserID} || undef,
        _toEntityID         => $args{toEntityID} || undef,
        _notificationType   => $args{notificationType},
        _dbh                => $args{dbh},
        _defsEmail          => $args{defsEmail},
        _defsName           => $args{defsName},
        _subject            => $args{subject} || undef,
        _lang               => $args{lang} || undef,
        _htmlTemplatePath   => $args{htmlTemplatePath} || undef,
        _textTemplatePath   => $args{textTemplatePath} || undef,
        _data               => $args{data} || undef,
        _workTaskDetails    => $args{workTaskDetails} || undef,
        _toOriginLevel      => $args{OriginLevel} || undef,
        _fromLevel      => $args{fromLevel} || undef,
    };

    $self = bless ($self, $class);

    return $self;
    #return $class->SUPER::new(@_); 
}

sub getRealmID {
    my ($self) = shift;
    return $self->{_realmID};
}

sub getSubRealmID {
    my ($self) = shift;
    return $self->{_subRealmID};
}

sub getFromEntityID {
    my ($self) = shift;
    return $self->{_fromEntityID};
}

sub getFromSelfUserID {
    my ($self) = shift;
    return $self->{_fromSelfUserID};
}

sub getToEntityID {
    my ($self) = shift;
    return $self->{_toEntityID};
}

sub getNotificationType {
    my ($self) = shift;
    return $self->{_notificationType};
}

sub getDefsEmail {
    my ($self) = shift;
    return $self->{_defsEmail};
}

sub getDefsName {
    my ($self) = shift;
    return $self->{_defsName};
}

sub getDbh {
    my ($self) = shift;
    return $self->{_dbh};
}

sub getSubject {
    my ($self) = shift;
    return $self->{_subject};
}

sub getLang {
    my ($self) = shift;
    return $self->{_lang};
}

sub getHtmlTemplatePath {
    my ($self) = shift;
    return $self->{_htmlTemplatePath};
}

sub getTextTemplatePath {
    my ($self) = shift;
    return $self->{_textTemplatePath};
}

sub getData {
    my ($self) = shift;
    return $self->{_data};
}

sub getWorkTaskDetails {
    my ($self) = shift;
    return $self->{_workTaskDetails};
}

sub getFromEntityLevel {
    my ($self) = shift;
    return $self->{_fromLevel} || 100;
}


sub getToOriginLevel {
    my ($self) = shift;
    return $self->{_toOriginLevel} || 100;
}

sub initialise {
    my ($self) = shift;

    $self->SUPER::retrieve();
    return $self;
}

sub initialiseTemplate {
    my ($self) = shift;

    my $template = new EmailNotifications::Template($self);
    return $template;
}

sub send {
    my ($self) = shift;
    my ($template) = @_;
    my $content = $template->build()->getContent();

    my $templateData = $template->getTemplateData();
    my $config = $template->getConfig();

    my $Data = $self->getData();
    #TODO: send text template if no wrapper

    my ($emailsentOK, $message)  = sendTemplateEmail(
        $Data,
        $Data->{'SystemConfig'}{'EmailNotificationWrapperTemplate'},
        $templateData,
        $templateData->{'To'}{'email'},
        $config->{'strSubjectPrefix'} . $self->getSubject(),
        $templateData->{'From'}{'email'},
        $templateData->{'CC'}{'email'},
    );
}

sub setRealmID {
    my $self = shift;
    my ($realmID) = @_;
    $self->{_realmID} = $realmID if defined $realmID;
}

sub setSubRealmID {
    my $self = shift;
    my ($subRealmID) = @_;
    $self->{_subRealmID} = $subRealmID if defined $subRealmID;
}

sub setFromEntityID {
    my $self = shift;
    my ($fromEntityID) = @_;
    $self->{_fromEntityID} = $fromEntityID if defined $fromEntityID;
}
sub setFromSelfUserID {
    my $self = shift;
    my ($fromSelfUserID) = @_;
    $self->{_fromSelfUserID} = $fromSelfUserID if defined $fromSelfUserID;
}
sub setToEntityID {
    my $self = shift;
    my ($toEntityID) = @_;
    $self->{_toEntityID} = $toEntityID if defined $toEntityID;
}

sub setNotificationType {
    my $self = shift;
    my ($notificationType) = @_;
    $self->{_notificationType} = $notificationType if defined $notificationType;
}

sub setDefsEmail {
    my $self = shift;
    my ($defsEmail) = @_;
    $self->{_defsEmail} = $defsEmail if defined $defsEmail;
}

sub setDefsName {
    my $self = shift;
    my ($defsName) = @_;
    $self->{_defsName} = $defsName if defined $defsName;
}

sub setDbh {
    my $self = shift;
    my ($dbh) = @_;
    $self->{_dbh} = $dbh if defined $dbh;
}

sub setSubject {
    my $self = shift;
    my ($subject) = @_;
    $self->{_subject} = $subject if defined $subject;
}

sub setLang {
    my $self = shift;
    my ($lang) = @_;
    $self->{_lang} = $lang if defined $lang;
}

sub setHtmlTemplatePath {
    my $self = shift;
    my ($htmlTemplatePath) = @_;
    $self->{_htmlTemplatePath} = $htmlTemplatePath if defined $htmlTemplatePath;
}

sub setTextTemplatePath {
    my $self = shift;
    my ($textTemplatePath) = @_;
    $self->{_textTemplatePath} = $textTemplatePath if defined $textTemplatePath;
}

sub setData {
    my $self = shift;
    my ($Data) = @_;
    $self->{_data} = $Data if defined $Data;
}

sub setWorkTaskDetails {
    my $self = shift;
    my ($workTaskDetails) = @_;
    $self->{_workTaskDetails} = $workTaskDetails if defined $workTaskDetails;
}

sub setFromEntityLevel {
    my $self = shift;
    my ($fromLevel) = @_;
    $self->{_fromLevel} = $fromLevel if defined $fromLevel;
}
sub setToOriginLevel {
    my $self = shift;
    my ($originLevel) = @_;
    $self->{_toOriginLevel} = $originLevel if defined $originLevel;
}

1;
