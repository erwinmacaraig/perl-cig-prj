#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/web/ajax/aj_teaminvite.cgi 11593 2014-05-19 02:19:16Z mstarcevic $
#

use strict;
use warnings;
use lib ".","..","../..","../../..","../RegoForm","../sportstats";
use CGI qw(param);
use Defs;
use Reg_common;
use Utils;
use Lang;
use TemplateEmail;
use ServicesContacts;
use RegoForm::RegoForm_MemberFunctions;
use Seasons;
use SystemConfig;
use RegoFormObj;

main(); 

sub main    {
    # GET INFO FROM URL
    my $client       = param('client')       || '';
    my $emails       = param('emails')       || '';
    my $teamID       = param('teamID')       || '';
    my $formID       = param('formID')       || '';
    my $assocID      = param('assocID')      || '';
    my $compID       = param('compID')       || '';
    my $reregemails  = param('reregemails')  || '';
    my $reregmembers = param('reregmembers') || '';
    my $useFormID    = param('useFormID')    || '';
    my $alwaysNew    = param('alwaysNew')    || '';
    my $isTemp       = param('Temp')         || 0;

    my %Data = ();
    my $lang = Lang->get_handle() || die "Can't get a language handle!";
    my $target = 'regoform.cgi';

    $Data{'lang'} = $lang;
    $Data{'target'} = $target;
    $Data{'clientValues'} = {getClient($client)};

    # AUTHENTICATE
    my $db = connectDB();
    $Data{'db'} = $db;
    if ($isTemp){
        my $st_team = qq[
              SELECT
                intRealID
              FROM
                tblTempMember
              WHERE intTempMemberID = ? 
        ];
        my $query_team = $db->prepare($st_team);
        $query_team->execute($teamID);

        my $team_data= $query_team->fetchrow_hashref();
        $teamID = $team_data->{'intRealID'};
    }
  
    $Data{'clientValues'}{'assocID'} = $assocID;
    $Data{'clientValues'}{'compID'} = $compID;
    $Data{'clientValues'}{'teamID'} = $teamID;
    ($Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm(\%Data);
     $Data{'SystemConfig'} = getSystemConfig( \%Data );
    my $body = '';

    my( @reregistrations, @rereg_emails, @rereg_members);
    if ($reregemails and $reregmembers) {
            @rereg_emails  = split /\s*,\s*/, $reregemails;
            @rereg_members = split /\s*,\s*/, $reregmembers;
    }

    my $st = qq[
        SELECT strFirstname, strSurname FROM tblMember 
        WHERE intMemberID = ? 
        LIMIT 1
    ];
    my $query = $db->prepare($st);

    while (@rereg_members) {
        my $rereg_member_data = { 
            email => shift @rereg_emails, 
            mID => shift @rereg_members 
        };

        $query->execute($rereg_member_data->{'mID'});

        my $member_data = $query->fetchrow_hashref();

        $rereg_member_data->{'strFirstname'} = $member_data->{'strFirstname'};
        $rereg_member_data->{'strSurname'}   = $member_data->{'strSurname'};

        push @reregistrations, $rereg_member_data;
    }

    if ($db) {
        my @emails;
        if ($emails) {
            my $emaillist = $emails;
            $emaillist =~s/[\s;]+/,/g;

            @emails = map { {
                    email    => $_,
                    template => 'signup-member.templ',
                    subject  => 'Invitation to join my team',
            } } split /\s*,\s*,*\s*/, $emaillist;
        }

        my $numemails = scalar( grep { $_->{'email'} } @reregistrations) + scalar(@emails);

        if($numemails)  {

            my $teamdata = getTeamEmailData(
                \%Data, 
                $teamID,    
                $compID,    
                $assocID,   
                $formID,
                $useFormID,
                $alwaysNew,
            );

            my $assocEmail = getServicesContactsEmail(\%Data, $Defs::LEVEL_ASSOC, $assocID, $Defs::SC_CONTACTS_REGOS) || $Defs::admin_email;
            $assocEmail = '' if($Data{'SystemConfig'}{'NoAssocOnTeamInvites'});
            my $seasonID = getSeasonID( $db, $assocID, $compID );

            foreach my $rereg_member (@reregistrations) {
                regreg_Member(
                    \%Data,
                    $rereg_member->{'mID'},
                    $seasonID,
                    $teamID,
                    $assocID,
                    $compID
                );

                push @emails, {
                    template => 'rereg-member.templ',
                    subject  => 'Entry for the upcoming season',
                    %$rereg_member,
                };
            }

            for my $i (@emails) {
                my $sent = sendTemplateEmail(
                    \%Data,
                    'regoform/team/' . $i->{'template'},
                    { %$teamdata, %$i },
                    $i->{'email'},
                    $i->{'subject'},
                    "$teamdata->{'AssocName'} <$Defs::null_email>",
                    '',
                    $assocEmail,
                );
                $body .= $i->{'email'} . '<br>';
            }
            my $emailssent = $numemails == 1 ? '1 email' : "$numemails emails";
            $body = qq[
                <p>We sent $emailssent on your behalf:</p>
                $body
                <br>
                <p>Did you forget someone? No problem, just enter more email addresses below and click 'Invite Teammates Now'.
            ];
        }

    }

    print "Content-type: text/html\n\n";
    print $body;

}

sub getTeamEmailData    {
    my($Data, $teamID, $compID, $assocID, $formID, $useFormID, $alwaysNew) = @_;

    my $teamname = '';
    my $teamcontact = '';
    my $compname = '';
    my $assocname = '';
    my $st = '';

    if($teamID) {
      $st = qq[ SELECT strName, strContact FROM tblTeam WHERE intTeamID = ? ];
      my $q= $Data->{'db'}->prepare($st);
      $q->execute($teamID);
      ($teamname, $teamcontact) = $q->fetchrow_array();
    }

    if($compID) {
      $st = qq[ SELECT strTitle FROM tblAssoc_Comp WHERE intCompID = ? ];
      my $q= $Data->{'db'}->prepare($st);
      $q->execute($compID);
      ($compname) = $q->fetchrow_array();
    }

    if($assocID)  {
      $st = qq[ SELECT strName FROM tblAssoc WHERE intAssocID = ? ];
      my $q= $Data->{'db'}->prepare($st);
      $q->execute($assocID);
      ($assocname) = $q->fetchrow_array();
    }

    my $linkedformID = 0;

    if($formID)  {
        if (!$useFormID) {
            $st = qq[ SELECT intLinkedFormID FROM tblRegoForm WHERE intRegoFormID = ? ];
            my $q= $Data->{'db'}->prepare($st);
            $q->execute($formID);
            ($linkedformID) = $q->fetchrow_array();
        }
        else {
            $linkedformID = $formID;
        }
    }

    my $teamcode = $Defs::LEVEL_TEAM.$teamID;
    my $url = qq[$Defs::base_url/$Data->{'target'}?aID=$assocID&amp;fID=$linkedformID&amp;teamcode=$teamcode&amp;compID=$compID];

    if ($linkedformID) {
        my $regoFormObj = RegoFormObj->load(db=>$Data->{'db'}, ID=>$linkedformID);
        if ($regoFormObj->isNodeForm()) {
            my $pwdVal = getRegoPassword($assocID + $linkedformID);
            $url .= qq[&amp;formID=$linkedformID&amp;pKey=$pwdVal];
        }
    }

    $url .= q[&amp;rfp=i] if $alwaysNew and $compID and $teamcode;

    my %TeamData = (
        AssocName => $assocname,
        CompName => $compname,
        TeamName => $teamname,
        TeamContact => $teamcontact,
        TeamCode => $teamcode,
        LinkedFormID => $linkedformID,
        LinkedFormURL => $url,
    );

  return \%TeamData;
}

sub getSeasonID {
    my ($db, $assocID, $compID ) = @_;

    my $statement = qq[
        SELECT
            intNewSeasonID
        FROM
            tblAssoc_Comp
        WHERE
            intAssocID = ? AND intCompID = ?
    ];

    my $query = $db->prepare($statement);
    $query->execute($assocID, $compID);
    my ($seasonID) = $query->fetchrow_array();
    return $seasonID;
}


sub regreg_Member   {
    my ($Data, $memberID, $seasonID, $teamID, $assocID, $compID) = @_;

    my $clubID = getTeamClub($Data->{'db'}, $teamID) || 0;

    my %types = (
        intPlayerStatus => 1,
        intMSRecStatus => 1,

    );

    my $st = qq[
        INSERT IGNORE INTO tblMember_Teams (
            intMemberID, 
            intTeamID, 
            intCompID, 
            intStatus
        )
        VALUES (
            ?, ?, ?, ?
        )
        ON DUPLICATE KEY UPDATE intStatus = 1
    ];
    my $query=$Data->{'db'}->prepare($st);
    $query->execute($memberID, $teamID, $compID, 1);

    my $ageGroupID = 

    RegoForm_MemberFunctions::getAgeGroupID($Data, $Data->{'db'}, $assocID, $memberID);

    Seasons::insertMemberSeasonRecord(
        $Data,
        $memberID,
        $seasonID,
        $assocID,
        0,
        $ageGroupID,
        \%types,
    );

    Seasons::insertMemberSeasonRecord(
        $Data,
        $memberID,
        $seasonID,
        $assocID,
        $clubID,
        $ageGroupID,
        \%types,
    );
}

sub getTeamClub {
    my($db, $teamID) = @_;
    my $st = qq[
        SELECT intClubID
        FROM tblTeam
        WHERE intTeamID = ?
    ];
    my $query = $db->prepare($st);
    $query->execute($teamID);
    my ($clubID) = $query->fetchrow_array();
    return $clubID;
}

