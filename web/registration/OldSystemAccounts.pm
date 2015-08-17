package OldSystemAccounts;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    linkOldAccount
);

use strict;
use lib '.', '..', '../..', "../../..", "../user", "user";

use TTTemplate;
use CGI qw(param);
use Defs;
use Utils;
use Lang;
use SelfUserObj;
use PersonUtils;
use InstanceOf;

sub linkOldAccount{
    my ($Data, $usession) = @_;

    my $userID = $Data->{'UserID'} || 0;
    my $error = '';
    my $username = param('un') || '';
    my $password = param('pw') || '';
    if(!$username or !$password)    {
        $error = $Data->{'lang'}->txt('You must supply both credentials to link to your old system account');
    }
    if($userID) {
        my $st = qq[
            SELECT
                intPersonID
            FROM 
                tblOldSystemAccounts
            WHERE
                strUsername = ?
                AND strPassword = ?

        ];
        my $q = $Data->{'db'}->prepare($st);
        $q->execute(
            $username,
            $password,
        );
        my ($personID) = $q->fetchrow_array();
        $q->finish();

        if($personID)   {
            my $pu = getPersonUserAccount($Data, $personID);            
            if(!$pu) {
                my $linkMinor = linkAge($Data, $personID) || 0;
                my $adultLinks = numAdultLinks($Data, $userID) || 0;
                if($linkMinor or (!$linkMinor and !$adultLinks))    {
                    updatePersonLink($Data, $personID, $userID, $linkMinor);
                }
                else    {
                    $error = $Data->{'lang'}->txt("The person you are trying to link is an adult and there is already an adult linked to this account");
                }
            }
            else    {
                $error = $Data->{'lang'}->txt("This person is already linked to another account");
            }
        }
        else    {
            $error = $Data->{'lang'}->txt("We can't seem to find your old account");
        }
    }
    else    {
        $error = $Data->{'lang'}->txt('Invalid UserID');
    }
    my $info = '';
    my $msg = '';
    if($error)  {
        $msg = $error;
    }
    else    {
        $info = 'fa-info';
        $msg = $Data->{'lang'}->txt('Account linked successfully');
    }
    my $body = qq[
<div class="alert"> 
    <div>
        <span class="fa $info fa-exclamation"></span>
        <p>$msg</p>
    </div>
</div>

    ];
    return $body;
}

sub updatePersonLink    {
    my ($Data, $personID, $userID, $minor) = @_;

    my $st = qq[
        INSERT INTO tblSelfUserAuth (
            intSelfUserID,
            intEntityTypeID,
            intEntityID,
            intMinor
        )
        VALUES (
            ?,
            $Defs::LEVEL_PERSON,
            ?,
            ?
        )
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $userID,
        $personID,
        $minor || 0,
    );
    $q->finish();
    return 1;
}

sub getPersonUserAccount    {
    my ($Data, $personID) = @_;

    my $st = qq[
        SELECT
            intSelfUserID
        FROM 
            tblSelfUserAuth
        WHERE
            intEntityID = ?
            AND intEntityTypeID = $Defs::LEVEL_PERSON
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $personID,
    );
    my ($pID) = $q->fetchrow_array();
    $q->finish();
    return $pID || 0;
}

sub numAdultLinks {
    my ($Data, $userID) = @_;
    #my $st = qq[ SELECT COUNT(*) FROM tblSelfUserAuth WHERE intSelfUserID = ? AND intMinor = 0 ];
    my $st = qq[SELECT COUNT(*) from tblSelfUserAuth INNER JOIN tblPersonRegistration_$Data->{'Realm'} on tblSelfUserAuth.intEntityID = tblPersonRegistration_$Data->{'Realm'}.intPersonID where tblSelfUserAuth.intSelfUserID = ? and tblPersonRegistration_$Data->{'Realm'}.strStatus NOT IN ('','REJECTED') AND tblSelfUserAuth.intMinor = 0];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $userID,
    );
    my ($count) = $q->fetchrow_array();
    $q->finish();
    
    
    return $count || 0;
}

sub linkAge {
    my ($Data, $pID) = @_;

    my $person =  getInstanceOf($Data, 'person', $pID);
    return '' if !$person;
    my $dob = $person->getValue('dtDOB') || '';
    return '' if !$dob;
    my $minor = personIsMinor($Data, $dob);
    return $minor || 0;

}

1;
