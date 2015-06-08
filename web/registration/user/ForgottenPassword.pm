package ForgottenPassword;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(
    handleForgottenPassword
);
@EXPORT_OK = qw(
    handleForgottenPassword
);
use lib ".", "..", "../../..", "../..", "user","../../user";

use strict;
use DBI;


use CGI qw(:cgi);
use Defs;
use Utils;
use Lang;
use TTTemplate;
use SystemConfig;
use TemplateEmail;
use SelfUserObj;
use AccountProfile qw(updatePassword);

sub handleForgottenPassword {
    my ($Data, $action) = @_;

    my $email = param('email');
    my $key = param('k');
    my $body = '';
    my @errors = ();
    my $sent = 0;
    my $uID = 0;    
    $uID = checkPWChangeKey($Data->{'db'}, $key) if $key;
    if($action eq 'FORGOT_RESET')   {

        my $userObj = new SelfUserObj(db => $Data->{'db'});
        if( !defined($userObj->load(email => $email)) ){
            push @errors, $Data->{'lang'}->txt("Sorry. The email address you have provided does not exist in our system.");
        }
        else {
            $sent = sendResetEmail($Data, $userObj) || 0;
        }
    }
    if($action eq 'FORGOT_UPDATE' and $uID)   {
        my %DataNew = %$Data;
        $DataNew{'UserID'} = $uID;
        my($continue, $message) = updatePassword(\%DataNew);
        if($continue)   {
            $body .= qq[
    <div class="alert "> 
        <div>
            <span class="fa fa-info fa-exclamation"></span>
                <p>$message</p>
        </div>
    </div>
    <p><a href = "index.cgi">].$Data->{'lang'}->txt('Proceed to the login page') .qq[</a></p>
            ];

        }
        else    {
            push @errors, $message;
            $action = 'FORGOT_CHANGE';
        }
    }
    if($action eq 'FORGOT_CHANGE' and $uID)   {
        $body .= runTemplate(
            $Data,
            {
                PasswordOnly => 1,
                PasswordAction => 'FORGOT_UPDATE',
                PWChangeKey => $key,
                Errors => \@errors,
            },
            'selfrego/user/profile.templ',
        );
    }

    if(!$body)  {
        $body = runTemplate(
            $Data,
            {
                'Errors' => \@errors,
                'sent' => $sent,
            },
            'selfrego/user/forgot_password_form.templ',
        );
    }
    return ($body, $Data->{'lang'}->txt('Forgotten Password'));
}


sub sendResetEmail {
    my ($Data, $user) = @_;

    return if !$user;

    my $templateFileContent = 'emails/registration/passwordreset.templ';
    my $templateWrapper = $Data->{'SystemConfig'}{'EmailNotificationWrapperTemplate'};
    my $key = $user->getPasswdChangeKey();
    my $content = runTemplate(
        $Data,
        {
            RecipientName => $user->FullName(),
            SenderName => $Defs::admin_email_name,
            PasswordResetURL => "$Defs::base_url/registration/?a=FORGOT_CHANGE&k=$key",
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
        \%emailTemplateContent,
        $user->Email(),
        $Data->{'SystemConfig'}{'EmailNotificationSysName'} . ": " . $Data->{'lang'}->txt("Change your password"),
        '',#$email_from,
    );
    return $emailsentOK;
}

sub checkPWChangeKey {
    my($db,$key) = @_;
    my $st = "SELECT intSelfUserId FROM tblSelfUserHash WHERE strPasswordChangeKey = ?";
    my $q = $db->prepare($st);
    $q->execute($key);
    my($uId) = $q->fetchrow_array();
    $q->finish();
    return $uId || 0;
}

1;
