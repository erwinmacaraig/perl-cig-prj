package AccountProfile;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
    handleAccountProfile
);
@EXPORT_OK = qw(
    handleAccountProfile
    updatePassword
);

use strict;
use lib '.', '..', '../..', "../../..", "../user", "user";

use TTTemplate;
use CGI qw(param);
use Defs;
use Utils;
use Lang;
use SelfUserObj;
use ConfirmationEmail;
use PasswordFormat;

use Switch;

sub handleAccountProfile {
    my ($Data, $action) = @_;

    my $resultHTML  = q{};
    my $pageHeading = $Data->{'lang'}->txt("User Profile");

    my $result = 0;
    if($action eq 'P_u')    {
        ($result, $resultHTML) = updateProfilePage($Data);
    }
    elsif($action eq 'P_pu')    {
        ($result, $resultHTML) = updatePassword($Data);
    }
    if($resultHTML) {
        my $type = $result ? 'fa-info' : '';
        if($result) {
            $resultHTML = qq[
    <div class="alert "> 
        <div>
            <span class="fa $type fa-exclamation"></span>
                <p>$resultHTML</p>
        </div>
    </div>
            ];
        }
    }
    $action = 'P_';
    if($action eq 'P_')    {
        $resultHTML .= displayProfilePage($Data);
    }

    return ($resultHTML, $pageHeading);
}

sub displayProfilePage {
    my ($Data) = @_;

    my $us = $Data->{'User'};
    my $result = runTemplate(
        $Data,
        {
            User => $Data->{'User'},
            FirstName => $us->{'Info'}{'FirstName'},
            FamilyName => $us->{'Info'}{'FamilyName'},
            Email => $us->{'Info'}{'Email'},
        },
        'selfrego/user/profile.templ',
    );

    return $result;
}

sub updateProfilePage {
    my ($Data) = @_;

    my $user = new SelfUserObj(db => $Data->{'db'}, id => $Data->{'UserID'});
    my $body = '';
    if($user->ID()) {
        my $email = $user->Email();
        my %updateData = (
            strFirstName => param('firstname') || '',
            strFamilyName => param('familyname') || '',
            strEmail => param('email') || '',
        );
        if(
            !$updateData{'strFirstName'} 
            or !$updateData{'strFamilyName'} 
            or !$updateData{'strEmail'} 
        )   {
            return (0,$Data->{'lang'}->txt('All fields must be entered'));
        }
        $user->update(\%updateData);
        $Data->{'User'}->reload();

        if($updateData{'strEmail'} ne $email) {
            $user->setStatus($Defs::USER_STATUS_NOTCONFIRMED);
            sendConfirmationEmail($Data, $user);
            $body = $Data->{'lang'}->txt(qq[You have been sent an email to confirm your new email address.  You must click the link in the email to confirm your account.]);
        }
    }
    $body ||= $Data->{'lang'}->txt("Your profile has been updated");
    return (1,$body);
}

sub updatePassword {
    my ($Data) = @_;

    my $user = new SelfUserObj(db => $Data->{'db'}, id => $Data->{'UserID'});
    if($user->ID()) {
        my %updateData = (
            pw1 => param('password') || '',
            pw2 => param('password2') || '',
        );
        if(
            !$updateData{'pw1'} 
            or !$updateData{'pw2'} 
            or $updateData{'pw1'} ne $updateData{'pw2'} 
        )   {
            return (0,$Data->{'lang'}->txt('Both fields must be the same'));
        }
        if(!isValidPasswordFormat($Data, $updateData{'pw1'}))   {
            return (0,$Data->{'lang'}->txt("New password doesn't meet requirements"));
        }
        $user->setPassword($updateData{'pw1'});
    }
    return (1,$Data->{'lang'}->txt("Password updated"));
}
1;

