package EmailNotifications::Template;
require Exporter;

use strict;
use lib '.', '..', '../..';
use Defs;
use TTTemplate;
use Data::Dumper;

sub new {
    my $class = shift;
    my ($args) = @_;

    my $self = {
        _notificationObj    => $args,
        _config             => undef,
        _content            => undef,
        _templateData       => undef,
    };

    $self = bless ($self, $class);

    #print STDERR Dumper $self->{_notificationObj}->getRealmID();
    return $self;
}

sub getConfig {
    my $self = shift;
    my ($field) = @_;

    if($field) {
        return $self->{_config}{$field};
    }
    else {
        return $self->{_config};
    }
}

sub getContent {
    my $self = shift;
    return $self->{_content};
} 

sub getTemplateData {
    my $self = shift;
    return $self->{_templateData};
}

sub retrieve {
    my ($self) = shift;

    #LANG should be identified already
    my $st = qq[
        SELECT
            r.strRealmName,
            ett.strTemplateType,
            ett.strFileNamePrefix,
            ett.strStatus,
            et.strHTMLTemplatePath,
            et.strTextTemplatePath,
            et.strSubjectPrefix,
            et.intLanguageID,
            tl.strLocale,
            toEntity.strEmail as toEntityEmail,
            toEntity.strContactEmail as toEntityContactEmail,
            toEntity.strLocalName as toEntityName,
            toEntity.intNotifications as toEntityNotification,
            fromEntity.strEmail as fromEntityEmail,
            fromEntity.strContactEmail as fromEntityContactEmail,
            fromEntity.strLocalName as fromEntityName,
            fromEntity.intNotifications as fromEntityNotification,
            totc.strContactEmail as toClubContactEmail,
            frtc.strContactEmail as fromClubContactEmail
        FROM tblEmailTemplateTypes ett
            INNER JOIN tblRealms r ON (r.intRealmID = ett.intRealmID)
            INNER JOIN tblEmailTemplates et ON (et.intEmailTemplateTypeID = ett.intEmailTemplateTypeID)
            INNER JOIN tblLanguages tl ON (tl.intLanguageID = et.intLanguageID AND tl.intRealmID = ett.intRealmID)
            INNER JOIN tblEntity toEntity ON (toEntity.intRealmID = ett.intRealmID AND toEntity.intEntityID = ?)
            INNER JOIN tblEntity fromEntity ON (fromEntity.intRealmID = ett.intRealmID AND fromEntity.intEntityID = ?)
            LEFT JOIN tblContactRoles tcrs ON (tcrs.intRealmID = ett.intRealmID AND tcrs.strRoleName = 'Secretary')
            LEFT JOIN tblContactRoles tcrp ON (tcrp.intRealmID = ett.intRealmID AND tcrp.strRoleName = 'President')
            LEFT JOIN tblContacts totc ON (totc.intRealmID = ett.intRealmID AND totc.intClubID = toEntity.intEntityID AND (totc.intContactRoleID = tcrs.intRoleID OR totc.intContactRoleID = tcrp.intRoleID) AND totc.strContactEmail != '')
            LEFT JOIN tblContacts frtc ON (frtc.intRealmID = ett.intRealmID AND frtc.intClubID = fromEntity.intEntityID AND (frtc.intContactRoleID = tcrs.intRoleID OR frtc.intContactRoleID = tcrp.intRoleID) AND frtc.strContactEmail != '')
        WHERE
            ett.intRealmID = ?
            AND ett.intSubRealmID IN (0, ?)
            AND ett.strTemplateType = ?
            AND ett.intActive = 1
        LIMIT 1

    ];

    #ADD LOCALE CHECK ON tblLanguages or SystemConfig->DefaultLocale or Cookie_Locale
    my $q = $self->{_notificationObj}->getDbh()->prepare($st);
    $q->execute(
        $self->{_notificationObj}->getToEntityID(),
        $self->{_notificationObj}->getFromEntityID(),
        $self->{_notificationObj}->getRealmID(),
        $self->{_notificationObj}->getSubRealmID(),
        $self->{_notificationObj}->getNotificationType()
    ) or query_error($st);

    my $config = $q->fetchrow_hashref();
    $self->setConfig($config);

    return $self;
}

sub build {
    my $self = shift;

    my $config = $self->getConfig();

    if(defined $config) {
        my $content = undef;
        #my $realmName = $config->{'strRealmName'} || 'generic';
        my $realmID = $self->{_notificationObj}->getRealmID() || 'generic';
        my $replace = "__REALMNAME__";
        my $templatePath = (defined $config->{'strHTMLTemplatePath'} and $config->{'strHTMLTemplatePath'}) ? $config->{'strHTMLTemplatePath'} : $config->{'strTextTemplatePath'};
        #$templatePath =~ s/\Q$replace/\E$realmID/g;
        #my $templateFile = $templatePath . '/' . $config->{'strFileNamePrefix'} . '.templ';
        my $templateFile = $templatePath . $config->{'strFileNamePrefix'} . '.templ';

        #print STDERR Dumper "TEMPLATE FILE " . $templateFile;
        my %Data = (
            lang => $self->{_notificationObj}->getLang(),
            Realm => $self->{_notificationObj}->getRealmID(),
        );

        #print STDERR Dumper $self->{_notificationObj}->getWorkTaskDetails();
        my %TemplateData = (
            To => {
                email => $config->{'toEntityContactEmail'} ? $config->{'toEntityContactEmail'} : $config->{'toEntityEmail'} ? $config->{'toEntityEmail'} : $config->{'toClubContactEmail'},
                name => $config->{'toEntityName'},
            },
            From => {
                email => $self->{_notificationObj}->getDefsEmail() ? $self->{_notificationObj}->getDefsEmail() : $config->{'fromEntityEmail'} ? $config->{'fromEntityEmail'} : $config->{'fromEntityContactEmail'},
                name => $self->{_notificationObj}->getDefsName() ? $self->{_notificationObj}->getDefsName() : $config->{'fromEntityName'},
            },
            CC => {
                email => $self->{_notificationObj}->getWorkTaskDetails()->{'CC'} || '',
                name => undef,
            },
            RecipientName => $config->{'toEntityName'},
            WorkTaskType => $self->{_notificationObj}->getWorkTaskDetails()->{'WorkTaskType'},
            Person => $self->{_notificationObj}->getWorkTaskDetails()->{'Person'},
            Club => $self->{_notificationObj}->getWorkTaskDetails()->{'Club'},
            Venue => $self->{_notificationObj}->getWorkTaskDetails()->{'Venue'},
            PersonRegisterTo => $self->{_notificationObj}->getWorkTaskDetails->{'PersonRegisterTo'},
            ClubRegisterTo => $self->{_notificationObj}->getWorkTaskDetails()->{'ClubRegisterTo'},
            VenueRegisterTo => $self->{_notificationObj}->getWorkTaskDetails()->{'VenueRegisterTo'},

            Originator => $config->{'fromEntityName'},
            SenderName => $config->{'fromEntityName'} || $self->{_notificationObj}->getDefsName() || 'Admin',
            TemplateFile => $templateFile,
            Reason => $self->{_notificationObj}->getWorkTaskDetails()->{'Reason'},
            Status => $config->{'strStatus'},
            RegistrationType => $self->{_notificationObj}->getWorkTaskDetails->{'RegistrationType'},
            MA_HeaderName => $self->{_notificationObj}->getData()->{'SystemConfig'}{'EmailNotificationSysName'},
            SysName => $self->{_notificationObj}->getData()->{'SystemConfig'}{'EmailNotificationSysName'},

            MA_PhoneNumber => $self->{_notificationObj}->getData()->{'SystemConfig'}{'ma_phone_number'},
            MA_HelpDeskPhone => $self->{_notificationObj}->getData()->{'SystemConfig'}{'help_desk_phone_number'},
            MA_HelpDeskEmail => $self->{_notificationObj}->getData()->{'SystemConfig'}{'help_desk_email'},
            MA_Website => $self->{_notificationObj}->getData()->{'SystemConfig'}{'ma_website'},

            #Person Request below
            CurrentClub => $self->{_notificationObj}->getWorkTaskDetails()->{'CurrentClub'},
            RequestingClub => $self->{_notificationObj}->getWorkTaskDetails()->{'RequestingClub'} || $config->{'fromEntityName'},
            MA => $self->{_notificationObj}->getWorkTaskDetails()->{'MA'} || '',
        );

        $content = runTemplate(
            $self->{_notificationObj}->getData(),
            \%TemplateData,
            'emails/' . $templateFile
        );

        $TemplateData{'content'} = $content;

        $self->setContent($content);
        $self->setTemplateData(\%TemplateData);
    }

    return $self;
}

sub setConfig {
    my $self = shift;
    my ($configHash) = @_;
    $self->{_config} = $configHash if defined $configHash;
}

sub setContent {
    my $self = shift;
    my ($content) = @_;
    $self->{_content} = $content if defined $content;
}

sub setTemplateData {
    my $self = shift;
    my ($templateData) = @_;
    $self->{_templateData} = $templateData if defined $templateData;
}

1;
