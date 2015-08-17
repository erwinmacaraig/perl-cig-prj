package AccountActivation;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleAccountActivation
);

use strict;
use lib '.', '..', '../..', "../../..", "../user", "user";

use TTTemplate;
use CGI qw(param);
use Defs;
use Utils;
use Lang;
use SelfUserObj;

use Switch;

sub handleAccountActivation {
    my ($Data, $action) = @_;

    my $resultHTML  = q{};
    my $pageHeading = $Data->{'lang'}->txt("Account Activation");

    switch($action){
        case "activate" {
            ($resultHTML) = activateAccount($Data);
        }
        else {
            return;
        }
    }

    return ($resultHTML, $pageHeading);
}

sub activateAccount {
    my ($Data) = @_;

    my $query = new CGI;
    my $userID = safe_param('id', 'number') || '';
    my $confirmationKey = safe_param('key','word') || '';
    
    return displayResult($Data, "invalidparam", "") if !$userID or !$confirmationKey;

    my $user = new SelfUserObj(db => $Data->{'db'}, id => $userID);
    return displayResult($Data, "invalidparam", "") if !$user->Email();

    if($user->Status() eq 2) {
        #$Data->{'RedirectTo'} = "$Defs::base_url/registration/index.cgi";
        return displayResult($Data, "success", $Data->{'lang'}->txt('Your account has already been confirmed'));
    }
    elsif($user->ConfirmKey() eq $confirmationKey) {
        my %userdata = (
            strStatus => $Defs::USER_STATUS_CONFIRMED,
        ); 
 
        $user->update(\%userdata);
        return displayResult($Data, "success", "");
    }
    else {
        return displayResult($Data, "invalidkey", "");
    }
}

sub displayResult {
    my ($Data, $type, $message) = @_;

    my $result = runTemplate(
        $Data,
        {
            ResultMessage => $message,
            Type => $type,
        },
        'registration/sr_account_activation_result.templ',
    );

    return $result;
}

1;

