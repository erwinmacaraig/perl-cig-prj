package ConfirmationEmail;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(
    sendConfirmationEmail
);
@EXPORT_OK = qw(
    sendConfirmationEmail
);
use lib ".", "..", "../../..", "../..", "user","../../user";

use strict;
use DBI;


use Defs;
use Utils;
use Lang;
use TTTemplate;
use SystemConfig;
use TemplateEmail;

sub sendConfirmationEmail {
    my ($Data, $user) = @_;

    return if !$user;

    my $templateFileContent = 'emails/registration/activate.templ';
    my $templateWrapper = $Data->{'SystemConfig'}{'EmailNotificationWrapperTemplate'};
    my $activationURL = $Defs::selfreg_activation_url . "&id=" . $user->ID() . "&key=" . $user->ConfirmKey();

    my $content = runTemplate(
        $Data,
        {
            RecipientName => $user->FullName(),
            SenderName => $Defs::admin_email_name,
            ActivationURL => $activationURL,
            SystemName => $Data->{'SystemConfig'}{'EmailNotificationSysName'},
        },
        $templateFileContent,
    );

    my %emailTemplateContent = (
        content => $content,
        MA_PhoneNumber => $Data->{'SystemConfig'}{'ma_phone_number'},
        MA_HelpDeskPhone => $Data->{'SystemConfig'}{'help_desk_phone_number'},
        MA_HelpDeskEmail => $Data->{'SystemConfig'}{'help_desk_email'},
        MA_Website => $Data->{'SystemConfig'}{'ma_website'},
        MA_HeaderName => $Data->{'SystemConfig'}{'EmailNotificationSysName'},
        LoginURL => $Defs::base_url . "/registration",
    );

    my ($emailsentOK, $message)  = sendTemplateEmail(
        $Data,
        $templateWrapper,
        #$userData,
        \%emailTemplateContent,
        $user->Email(),
        $Data->{'lang'}->txt("Confirm your email with ") . $Data->{'SystemConfig'}{'EmailNotificationSysName'},
        '',#$email_from,
    );

}
