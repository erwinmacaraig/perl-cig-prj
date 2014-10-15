package EmailNotifications::Template;

use strict;
use lib '.', '..';
use TTTemplate;
use Data::Dumper;

sub new {
    my $class = shift;
    my (%args) = @_;

    my $self = {
        _realmID            => $args{realmID},
        _subRealmID         => $args{subRealmID},
        _fromEntityID       => $args{fromEntityID} || undef,
        _toEntityID         => $args{toEntityID} || undef,
        _notificationType   => $args{notificationType},
        _dbh                => $args{dbh},
        _subject            => $args{subject} || undef,
        _lang               => $args{lang} || undef,
        _htmlTemplatePath   => $args{htmlTemplatePath} || undef,
        _textTemplatePath   => $args{textTemplatePath} || undef,
    };

    $self = bless ($self, $class);

    return $self;

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

sub getToEntityID {
    my ($self) = shift;
    return $self->{_toEntityID};
}

sub getNotificationType {
    my ($self) = shift;
    return $self->{_notificationType};
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

sub retrieve {
    my ($self) = shift;

    #LANG should be identified already
    my $st = qq[
        SELECT
            r.strRealmName,
            ett.strTemplateType,
            ett.strFileNamePrefix,
            et.strHTMLTemplatePath,
            et.strTextTemplatePath,
            et.strSubjectPrefix,
            et.intLanguageID,
            tl.strLocale,
            toEntity.strEmail as toEntityEmail,
            toEntity.strContactEmail as toEntityContactEmail,
            fromEntity.strEmail as fromEntityEmail,
            fromEntity.strContactEmail as fromEntityContactEmail,
            totc.strContactEmail as toClubContactEmail,
            frtc.strContactEmail as fromClubContactEmail
        FROM tblEmailTemplateTypes ett
            INNER JOIN tblRealms r ON (r.intRealmID = ett.intRealmID)
            INNER JOIN tblEmailTemplates et ON (et.intEmailTemplateTypeID = ett.intEmailTemplateTypeID)
            INNER JOIN tblLanguages tl ON (tl.intLanguageID = et.intLanguageID AND tl.intRealmID = ett.intRealmID)
            INNER JOIN tblEntity toEntity ON (toEntity.intRealmID = ett.intRealmID AND toEntity.intEntityID = ?)
            INNER JOIN tblEntity fromEntity ON (fromEntity.intRealmID = ett.intRealmID AND fromEntity.intEntityID = ?)
            LEFT JOIN tblContacts totc ON (totc.intRealmID = ett.intRealmID AND totc.intClubID = toEntity.intEntityID)
            LEFT JOIN tblContacts frtc ON (frtc.intRealmID = ett.intRealmID AND frtc.intClubID = fromEntity.intEntityID)
        WHERE
            ett.intRealmID = ?
            AND ett.intSubRealmID = ?
            AND ett.strTemplateType = ?
            AND ett.intActive = 1

    ];

    #ADD LOCALE CHECK ON tblLanguages or SystemConfig->DefaultLocale or Cookie_Locale
    my $q = $self->getDbh()->prepare($st);
    $q->execute(
        $self->getToEntityID(),
        $self->getFromEntityID(),
        $self->getRealmID(),
        $self->getSubRealmID(),
        $self->getNotificationType()
    ) or query_error($st);

    print STDERR Dumper $q->fetchrow_hashref();

    #TODO: populate recipient details
    #TODO: populate sender details
    #TODO: identify correct template by using ett.strFilenamePrefix and replaced __REALMNAME__ by r.strRealmName
    #emails/notification/__REALMNAME__/workflow/html
    return $self;
}

sub build {

    #call after retrieveTemplate
    return 1;
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

1;
