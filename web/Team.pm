#
# $Header: svn://svn/SWM/trunk/web/Team.pm 11548 2014-05-14 00:30:07Z mstarcevic $
#

package Team;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleTeam team_details get_teams updateAssignCompTeam getTeamClubID getTeamHistory getSelectedTeams showTeamComps);
@EXPORT_OK=qw(handleTeam team_details get_teams updateAssignCompTeam getTeamClubID getTeamHistory getSelectedTeams showTeamComps);

use strict;

use lib 'gendropdown';

use Reg_common;
use Utils;
use HTMLForm;
use ListTeams;
use AuditLog;
use CGI qw(unescape param);
use Assoc;
use AssocObj;
use TeamObj;
use ConfigOptions qw(ProcessPermissions);
use Logo;

use Payments;
use TransLog;
use Transactions;
use Seasons;
use GenAgeGroup;
use TTTemplate;

use FormHelpers;
use CustomFields;

use CompNomination;
use GridDisplay;
use InstanceOf;
use FieldCaseRule;
use DefCodes;

use MatchCredits;
use GenDropDown;

require HomeTeam;

sub handleTeam	{
	my ($action, $Data, $teamID, $typeID)=@_;

	my $resultHTML='';
	my $teamName=
	my $title='';
  my $client = setClient($Data->{'clientValues'});
        
  my $res='';
	my $saveMessage = '';
	if ($action eq 'T_STAFFS') {
		$saveMessage= saveStaff($Data, $teamID);
		$action = "T_STAFF";
	}
	if ($action =~/^T_DT/) {
		#Team Details
        ($resultHTML,$title)=team_details($action, $Data, $teamID, $typeID);
	}
	elsif ($action eq 'T_STAFF') {
	    ($resultHTML,$title)=assignStaff($Data,$teamID);
			$resultHTML = $saveMessage . $resultHTML;
		}
	}
	elsif ($action eq 'T_CR') {
		#Remove a Team from a Comp
        ($resultHTML,$title)=unassignComp($Data, $teamID);
	}
	elsif ($action eq 'T_CRU') {
		#Remove a Team from a Comp
			($resultHTML,$title)=UpdateremoveComp($Data, $teamID);
	}
  	## elsif ($action eq 'T_L') {
	elsif ($action =~ /T_L/) {
		#List Team Children
			($resultHTML,$title)=listTeams($Data, $teamID, $typeID, $action); ## EDITED BY TC 31/10/06
        }
    elsif ($action eq 'T_DEL') {
        ($resultHTML,$title)=delete_team($Data, $client);
	}

	if ($action eq 'T_PLs') {
		#Update Team List
        ($res,$title)=updateTeamList($Data, $teamID, $typeID);
        $action = 'T_PL';
        #if $params{'dobFilter'};
	}
	elsif ($action =~/T_TXN_/) {
        ($resultHTML,$title)=handleTransactions($action, $Data, $teamID);
    }
    elsif ($action =~/T_TXNLog/) {
        ($resultHTML,$title)=handleTransLogs($action, $Data, $teamID);
    }
    elsif ($action =~/T_PAY_/) {
        ($resultHTML,$title)=handlePayments($action, $Data,0);
    }
    elsif ($action =~/T_HOME/) {
        ($resultHTML,$title)=HomeTeam::showTeamHome($Data,$teamID);
    }
    elsif ($action =~/T_LOADSELECT/) {
        my $fromCompID = param('fromCompID') || 0;        
        ($resultHTML,$title)=loadTeamsSelect($Data, $client, $fromCompID);
    }
    elsif ($action =~/T_LOADSUBMIT/) {
        my $fromCompID = param('fromCompID') || 0;        
        ($resultHTML,$title)=loadTeamsSubmit($Data, $client, $fromCompID);
    }
    elsif ($action =~/^T_CREDIT_/) {
        ($resultHTML,$title)=handleMatchCredits($action,$Data, $client);
    }
    
    if ($action eq 'T_PL') {
        #List Team Players
        if ($Data->{'SystemConfig'}{'AssocConfig'}{'useAssignPlayersToTeamV2'} or $Data->{'SystemConfig'}{'useAssignPlayersToTeamV2'})  {
            ($resultHTML,$title)=assignPlayersToTeam_v2($Data, $teamID, $client);
        }
        else{
            ($resultHTML,$title)=assignPlayersToTeam($Data, $teamID, $typeID);
        }
    }
    elsif ($action eq 'T_IT') {
        ($resultHTML, $title) = inviteTeammates($Data, $client, $teamID);
    }
    
	$resultHTML=($res||'').$resultHTML;

	return ($resultHTML,$title);
}


sub team_details	{
	my ($action, $Data, $teamID, $typeID, $compulsory)=@_;
	$compulsory ||= undef;

  my $lang = $Data->{'lang'};

  my %textLabels = (
    'Additional Contacts' => $lang->txt('Additional Contacts'),
    'Details' => $lang->txt('Details'),
    'Modify Member List' => $lang->txt('Modify Member List'),
    'Name' => $lang->txt('Name'),
    'No' => $lang->txt('No'),
    'Other Details' => $lang->txt('Other Details'),
    'Please select a competition' => $lang->txt('Please select a competition'),
    'Team' => $lang->txt('Team'),
    'Uniform Colours' => $lang->txt('Uniform Colours'),
    'Yes' => $lang->txt('Yes'),
  );

	my $option='display';
	$option='edit' if($action eq 'T_DTE' and allowedAction($Data, 't_e'));
	$option='add' if($action eq 'T_DTA'  and allowedAction($Data, 't_a'));
  $teamID=0 if $option eq 'add';
	$option='add' if $Data->{'RegoForm'} and ! $teamID;
	my $field=loadTeamDetails($Data->{'db'}, $teamID) || ();

	my $CustomFieldNames=getCustomFieldNames($Data, $field->{'intAssocTypeID'}) || '';	
  my $client=setClient($Data->{'clientValues'}) || '';
    
    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'} || $field->{'intAssocTypeID'},
        assocID    => $Data->{'clientValues'}{'assocID'},
    );

	my %DefVenues=();

    my $aID= $Data->{'clientValues'}{'assocID'} || -1;
    my $subtypeID=$Data->{'RealmSubType'} || $field->{'intAssocTypeID'} || 0;
	  my $statement = qq[
		  SELECT 
			  intDefVenueID, 
			  strName,
        IF(intRecStatus = 0, ' (Inactive)', '')
      FROM 
			  tblDefVenue
		  WHERE 
			  intAssocID = $aID 
        AND intRecStatus <> $Defs::RECSTATUS_DELETED
			  AND intTypeID IN (0, 1)
    ];
    my $query = $Data->{'db'}->prepare($statement);
    $query->execute;
    while (my($intVenueID, $strName, $intRecStatus) = $query->fetchrow_array) {
      $strName .= $intRecStatus if ($intRecStatus);
      $DefVenues{$intVenueID} = $strName || '';
    }

	my $clubID = $field->{intClubID} || $Data->{'clientValues'}{'clubID'} || 0;
	$clubID = 0 if ($clubID == $Defs::INVALID_ID);
  my ($clubs_vals,$clubs_order)=('','');
  my $club_name = '';
	if (! $clubID)	{
	  my $st_clubs=qq[
      SELECT 
				C.intClubID, 
				strName
      FROM 
				tblClub as C
        INNER JOIN tblAssoc_Clubs as AC ON (AC.intClubID = C.intClubID
          AND AC.intAssocID = $Data->{'clientValues'}{'assocID'}
				)
			WHERE 
				C.intRecStatus = $Defs::RECSTATUS_ACTIVE
				AND AC.intRecStatus = $Defs::RECSTATUS_ACTIVE
	    ORDER BY C.strName
    ];
    ($clubs_vals,$clubs_order)=getDBdrop_down_Ref($Data->{'db'},$st_clubs,'');
	}
  else {
    my $st_clubs = qq[
      SELECT
        strName
      FROM
        tblClub
      WHERE
        intClubID = ?
    ];
    my $q = $Data->{'db'}->prepare($st_clubs);
    $q->execute($clubID);
    $club_name = $q->fetchrow_array() || '';
  }

	my $hascomp=0;
    
  my $compID = 0;
  my $intCompStarted = 0;
    
  if ($option eq 'edit') {
    my $st=qq[
			SELECT CT.intCompID,intStarted
			FROM tblComp_Teams AS CT 
			INNER JOIN tblAssoc_Comp AS AC ON AC.intCompID=CT.intCompID 
	   	   	WHERE intTeamID=$teamID 
			AND CT.intRecStatus= $Defs::RECSTATUS_ACTIVE
			AND AC.intRecStatus= $Defs::RECSTATUS_ACTIVE
	  ];
    my $q=$Data->{'db'}->prepare($st);
    $q->execute();
    ($compID,$intCompStarted)=$q->fetchrow_array();
        
    $q->finish();
    $hascomp=1 if $compID;
  } 
    
  my $AssocDetails = loadAssocDetails($Data->{'db'}, $Data->{'clientValues'}{'assocID'});
  my $intAllowSWOL = $AssocDetails->{'intSWOL'};
    
  my $Comps = AssocObj->getComps($Data,$Data->{'clientValues'}{'assocID'},1,0);

  my $field_case_rules = get_field_case_rules({dbh=>$Data->{'db'}, client=>$client, type=>'Team'});
        
  $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} ||= $textLabels{'Team'};

    my %TeamCoaches = ();
    my %TeamManagers= ();

    my $cmJOIN  = '';
    my $cmWHERE = '';
    if ( $clubID ) {
        $cmJOIN  = ' INNER JOIN tblMember_Clubs AS MC ON M.intMemberID=MC.intMemberID ';
        $cmWHERE = " MC.intClubID=$clubID AND MC.intStatus=1 
                     AND MS.intClubID = $clubID";
    }
    else {
        $cmJOIN  = ' INNER JOIN tblMember_Associations AS MA ON M.intMemberID=MA.intMemberID ';
        $cmWHERE = " MA.intAssocID=$aID AND MA.intRecStatus=1 ";
    }
    my $MS_tablename = "tblMember_Seasons_$Data->{'Realm'}";
    my $st = qq[
        SELECT DISTINCT
            M.intMemberID,
            CONCAT( M.strFirstname, ' ', M.strSurname ),
            M.intCoach,
            M.intMisc
        FROM
            tblMember AS M
            INNER JOIN $MS_tablename AS MS ON M.intMemberID=MS.intMemberID
            $cmJOIN
        WHERE
            $cmWHERE
            AND MS.intAssocID=$aID
            AND MS.intSeasonID=$AssocDetails->{'intCurrentSeasonID'}
            AND MS.intMSRecStatus=1
            AND M.intStatus=1
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute();
    while ( my ( $memberID, $memberName, $isCoach, $isManager ) = $q->fetchrow_array() ) {
        $TeamCoaches{$memberID}  = $memberName if ($isCoach);
        $TeamManagers{$memberID} = $memberName if ($isManager);
    }

	my %FieldDefinitions=(
		fields=> {
            intClubID => {
                label => (($Data->{'allowClubSelection'} and ! $clubID) or ($Data->{'clientValues'}{authLevel} >= $Defs::LEVEL_ASSOC and $clubs_vals and (($option eq 'add') or ($teamID and ! $clubID)))) ? "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Name" : '',
                value => $clubID ? $clubID : 0,
                type  => 'lookup',
                options => $clubs_vals,
                firstoption => ['',"Choose $Data->{'LevelNames'}{$Defs::LEVEL_CLUB}"],
                sectionname => 'teamdetails',
                compulsory => (($Data->{'clubMandatory'} and $Data->{'allowClubSelection'} and $clubs_vals and ! $clubID) or (! $Data->{'SystemConfig'}{'ClubNotCompulsory'} and ! $Data->{'RegoFormID'} and $intAllowSWOL and $clubs_vals and $option eq 'add')) ? 1 : 0,
            },
            ClubName => {
                label => $field->{ClubName} ? "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Name" : '',
                value => $field->{ClubName},
                readonly=>1,
                noadd => 1,
                sectionname => 'teamdetails',
			},
            TeamCode => {
                label => 'Code',
                value => $Defs::LEVEL_TEAM . $field->{intTeamID},
                readonly=>1,
                noadd => 1,
                sectionname => 'teamdetails',
			},
			strName => {
				label         => "$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} Name",
				value         => $field->{strName} || $club_name,
				type          => 'text',
				size          => '40',
				maxsize       => '50',
				compulsory    => 1,
				sectionname   => 'teamdetails',
				readonly      => ($teamID  and $Data->{'clientValues'}{authLevel} < $Defs::LEVEL_ASSOC and allowedAction($Data, 'm_ne')) ? 1 : 0,
				Save_readonly => (!$teamID and $Data->{'clientValues'}{authLevel} < $Defs::LEVEL_ASSOC and allowedAction($Data, 'm_ne') and !$Data->{'RegoForm'}) ? 1 : 0,
			},
			intCompID => {
			    label => (($Data->{'clientValues'}{authLevel} >= $Defs::LEVEL_ASSOC or allowedAction($Data, 'ac_a')) and !$intCompStarted) ? $Data->{'LevelNames'}{$Defs::LEVEL_COMP}  : '',
                value => $compID,
                type => 'lookup',
                options => $Comps,
                firstoption => ['',"Please select a competition"],
                sectionname => 'teamdetails',
                SkipProcessing => 1,
                noedit =>1,
            },
            intRecStatus => {
                label => $Data->{'SystemConfig'}{'AllowStatusChange'} ? 'Active?' : '',	
				value => $field->{intRecStatus},
				type => 'checkbox',
				default => 1,
				displaylookup => {1=>'Yes', 0=>'No'},
				noadd => 1,
				sectionname => 'teamdetails',
			},
			strNickname => {
				label => 'Nickname',
				value => $field->{strNickname},
				type  => 'text',
				size  => '20',
				maxsize => '20',
				sectionname => 'teamdetails',
			},
			intCoachID => {
                label => 'Team Coach',
                value => $field->{intCoachID},
                type  => 'lookup',
                options => \%TeamCoaches,
                firstoption => [''," "],
                sectionname => 'teamdetails',
                 readonly => ( $clubID )
                ? 0
                : 1,
            },
			intManagerID => {
                label => 'Team Manager',
                value => $field->{intManagerID},
                type  => 'lookup',
                options => \%TeamManagers,
                firstoption => [''," "],
                sectionname => 'teamdetails',
            },
		 strCode => {
                                label => 'Three Letter Code',
                                value => $field->{strCode},
                                type  => 'text',
                                size  => '5',
                                maxsize => '3',
                                sectionname => 'teamdetails',
		},
			strContactTitle => {
				label => 'Contact Title',
				value => $field->{strContactTitle},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'teamdetails',
			},
			strContact => {
				label => 'Contact Name',
				value => $field->{strContact},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'teamdetails',
				compulsory=>$compulsory->{'strContact'} || 0,
			},
			strAddress1 => {
				label => 'Address Line 1',
				value => $field->{strAddress1},
				type  => 'text',
				size  => '30',
				maxsize => '100',
				sectionname => 'teamdetails',
			},
			strAddress2 => {
				label => 'Address Line 2',
				value => $field->{strAddress2},
				type  => 'text',
				size  => '30',
				maxsize => '100',
				sectionname => 'teamdetails',
			},
			strSuburb => {
				label => 'Suburb',
				value => $field->{strSuburb},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'teamdetails',
			},
			strState => {
				label => 'State',
				value => $field->{strState},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'teamdetails',
			},
			strCountry => {
				label => 'Country',
				value => $field->{strCountry},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'teamdetails',
			},
			strPostalCode => {
				label => 'Postal Code',
				value => $field->{strPostalCode},
				type  => 'text',
				size  => '10',
				maxsize => '10',
				sectionname => 'teamdetails',
			},
			strEmail => {
				label => 'Contact Email',
				value => $field->{strEmail},
				type  => 'text',
				size  => '35',
				maxsize => '200',
				compulsory=>$compulsory->{'strEmail'} || 0,
			        validate => 'EMAIL',
				sectionname => 'teamdetails',
			},
			strPhone1 => {
				label => 'Contact Phone',
				value => $field->{strPhone1},
				type  => 'text',
				size  => '20',
				maxsize => '20',
				compulsory=>$compulsory->{'strPhone1'} || 0,
				sectionname => 'teamdetails',
			},
			strPhone2 => {
				label => 'Contact Phone 2', 
				value => $field->{strPhone2},
				type  => 'text',
				size  => '20',
				maxsize => '20',
				compulsory=>$compulsory->{'strPhone2'} || 0,
				sectionname => 'teamdetails',
			},
			strMobile => {
				label => 'Contact Mobile', 
				value => $field->{strMobile},
				type  => 'text',
				size  => '20',
				maxsize => '20',
				compulsory=>$compulsory->{'strMobile'} || 0,
				sectionname => 'teamdetails',
			},
			strWebURL=> {
				label => 'Website',
				value => $field->{strWebURL},
				type  => 'text',
				size  => '35',
				maxsize => '200',
				sectionname => 'teamdetails',
			},
			strContactTitle2 => {
				label => 'Contact 2 Title',
				value => $field->{strContactTitle2},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'contactdetails',
			},
			strContactName2 => {
				label => 'Contact 2 Name',
				value => $field->{strContactName2},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'contactdetails',
			},
			strContactEmail2 => {
				label => 'Contact 2 Email',
				value => $field->{strContactEmail2},
				type  => 'text',
				size  => '35',
				maxsize => '200',
        			validate => 'EMAIL',
				sectionname => 'contactdetails',
			},
			strContactPhone2 => {
				label => 'Contact 2 Phone', 
				value => $field->{strContactPhone2},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'contactdetails',
			},
			strContactMobile2 => {
				label => 'Contact 2 Mobile', 
				value => $field->{strContactMobile2},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'contactdetails',
			},
			strContactTitle3 => {
				label => 'Contact 3 Title',
				value => $field->{strContactTitle3},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'contactdetails',
			},
			strContactName3 => {
				label => 'Contact 3 Name',
				value => $field->{strContactName3},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'contactdetails',
			},
			strContactEmail3 => {
				label => 'Contact  3 Email',
				value => $field->{strContactEmail3},
				type  => 'text',
				size  => '35',
				maxsize => '200',
        		validate => 'EMAIL',
				sectionname => 'contactdetails',
			},
			strContactPhone3 => {
				label => 'Contact 3 Phone', 
				value => $field->{strContactPhone3},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'contactdetails',
			},
			strContactMobile3 => {
				label => 'Contact 3 Mobile', 
				value => $field->{strContactMobile3},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'contactdetails',
			},
			strUniformTopColour=> {
				label => 'Uniform Top Colour',
				value => $field->{strUniformTopColour},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'colours',
			},
			strUniformBottomColour=> {
				label => 'Uniform Bottom Colour',
				value => $field->{strUniformBottomColour},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'colours',
			},
			strUniformNumber=> {
				label => 'Uniform Number Colour',
				value => $field->{strUniformNumber},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'colours',
			},
			strAltUniformTopColour=> {
				label => 'Alternate Uniform Top Colour',
				value => $field->{strAltUniformTopColour},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'colours',
			},
			strAltUniformBottomColour=> {
				label => 'Alternate Uniform Bottom Colour',
				value => $field->{strAltUniformBottomColour},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'colours',
			},
			strAltUniformNumber=> {
				label => 'Alternate Uniform Number Colour',
				value => $field->{strAltUniformNumber},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'colours',
			},
             intExcludeClubChampionships => {
                                            label => $intAllowSWOL ? 'Exclude from Club Championships' : '',
                                            value => $field->{intExcludeClubChampionships},
                                            type  => 'checkbox',
                                            displaylookup=> {1=> 'Yes', 0 => 'No'},
                                            default => 0,
                                            sectionname => 'otherdetails',
                                        },
			strTeamNotes => {
                                label => 'Notes', 
                                value => $field->{strTeamNotes},
                                type  => 'textarea',
                                sectionname => 'otherdetails',
                                rows => 5,
                                cols=> 45,
                        },
 
			SP1	=> {
				type =>'_SPACE_',
			},
                        strTeamCustomStr1=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr1'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr1'}[0],
                                value => $field->{strTeamCustomStr1},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr2=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr2'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr2'}[0],
                                value => $field->{strTeamCustomStr2},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr3=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr3'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr3'}[0],
                                value => $field->{strTeamCustomStr3},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr4=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr4'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr4'}[0],
                                value => $field->{strTeamCustomStr4},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr5=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr5'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr5'}[0],
                                value => $field->{strTeamCustomStr5},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr6=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr6'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr6'}[0],
                                value => $field->{strTeamCustomStr6},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr7=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr7'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr7'}[0],
                                value => $field->{strTeamCustomStr7},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr8=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr8'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr8'}[0],
                                value => $field->{strTeamCustomStr8},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr9=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr9'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr9'}[0],
                                value => $field->{strTeamCustomStr9},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr10=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr10'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr10'}[0],
                                value => $field->{strTeamCustomStr10},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr11=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr11'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr11'}[0],
                                value => $field->{strTeamCustomStr11},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr12=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr12'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr12'}[0],
                                value => $field->{strTeamCustomStr12},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr13=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr13'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr13'}[0],
                                value => $field->{strTeamCustomStr13},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr14=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr14'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr14'}[0],
                                value => $field->{strTeamCustomStr14},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
                        strTeamCustomStr15=> {
                                label => ($CustomFieldNames->{'strTeamCustomStr15'}[0] =~ /Custom.*Text Field/) ? '' : $CustomFieldNames->{'strTeamCustomStr15'}[0],
                                value => $field->{strTeamCustomStr15},
                                type  => 'text',
                                size  => '30',
                                maxsize => '50',
                                sectionname => 'otherdetails',
			},
			dblTeamCustomDbl1 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl1'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl1'}[0],
                                value => $field->{dblTeamCustomDbl1},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblTeamCustomDbl2 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl2'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl2'}[0],
                                value => $field->{dblTeamCustomDbl2},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblTeamCustomDbl3 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl3'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl3'}[0],
                                value => $field->{dblTeamCustomDbl3},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblTeamCustomDbl4 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl4'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl4'}[0],
                                value => $field->{dblTeamCustomDbl4},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblTeamCustomDbl5 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl5'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl5'}[0],
                                value => $field->{dblTeamCustomDbl5},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblTeamCustomDbl6 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl6'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl6'}[0],
                                value => $field->{dblTeamCustomDbl6},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblTeamCustomDbl7 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl7'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl7'}[0],
                                value => $field->{dblTeamCustomDbl7},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblTeamCustomDbl8 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl8'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl8'}[0],
                                value => $field->{dblTeamCustomDbl8},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblTeamCustomDbl9 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl9'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl9'}[0],
                                value => $field->{dblTeamCustomDbl9},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
			dblTeamCustomDbl10 => {
                                label => ($CustomFieldNames->{'dblTeamCustomDbl10'}[0] =~ /Custom.*Number Field/) ? '' : $CustomFieldNames->{'dblTeamCustomDbl10'}[0],
                                value => $field->{dblTeamCustomDbl10},
                                type  => 'text',
                                size  => '10',
                                maxsize => '15',
                                sectionname => 'otherdetails',
                        },
                        dtTeamCustomDt1 => {
                                label => ($CustomFieldNames->{'dtTeamCustomDt1'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtTeamCustomDt1'}[0],
                                value => $field->{dtTeamCustomDt1},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
                        dtTeamCustomDt2 => {
                                label => ($CustomFieldNames->{'dtTeamCustomDt2'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtTeamCustomDt2'}[0],
                                value => $field->{dtTeamCustomDt2},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
                        dtTeamCustomDt3 => {
                                label => ($CustomFieldNames->{'dtTeamCustomDt3'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtTeamCustomDt3'}[0],
                                value => $field->{dtTeamCustomDt3},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
                        dtTeamCustomDt4 => {
                                label => ($CustomFieldNames->{'dtTeamCustomDt4'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtTeamCustomDt4'}[0],
                                value => $field->{dtTeamCustomDt4},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
                        dtTeamCustomDt5 => {
                                label => ($CustomFieldNames->{'dtTeamCustomDt5'}[0] =~ /Custom.*Date Field/) ? '' : $CustomFieldNames->{'dtTeamCustomDt5'}[0],
                                value => $field->{dtTeamCustomDt5},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'DATE',
                        },
			intTeamCustomLU1 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU1'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU1'}[0],
                                value => $field->{intTeamCustomLU1},
                                type  => 'lookup',
                                options => $DefCodes->{-71},
                                order => $DefCodesOrder->{-71},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomLU2 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU2'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU2'}[0],
                                value => $field->{intTeamCustomLU2},
                                type  => 'lookup',
                                options => $DefCodes->{-72},
                                order => $DefCodesOrder->{-72},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomLU3 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU3'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU3'}[0],
                                value => $field->{intTeamCustomLU3},
                                type  => 'lookup',
                                options => $DefCodes->{-73},
                                order => $DefCodesOrder->{-73},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomLU4 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU4'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU4'}[0],
                                value => $field->{intTeamCustomLU4},
                                type  => 'lookup',
                                options => $DefCodes->{-74},
                                order => $DefCodesOrder->{-74},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomLU5 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU5'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU5'}[0],
                                value => $field->{intTeamCustomLU5},
                                type  => 'lookup',
                                options => $DefCodes->{-75},
                                order => $DefCodesOrder->{-75},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomLU6 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU6'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU6'}[0],
                                value => $field->{intTeamCustomLU6},
                                type  => 'lookup',
                                options => $DefCodes->{-76},
                                order => $DefCodesOrder->{-76},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomLU7 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU7'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU7'}[0],
                                value => $field->{intTeamCustomLU7},
                                type  => 'lookup',
                                options => $DefCodes->{-77},
                                order => $DefCodesOrder->{-77},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomLU8 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU8'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU8'}[0],
                                value => $field->{intTeamCustomLU8},
                                type  => 'lookup',
                                options => $DefCodes->{-78},
                                order => $DefCodesOrder->{-78},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomLU9 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU9'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU9'}[0],
                                value => $field->{intTeamCustomLU9},
                                type  => 'lookup',
                                options => $DefCodes->{-79},
                                order => $DefCodesOrder->{-79},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomLU10 => {
                                label => ($CustomFieldNames->{'intTeamCustomLU10'}[0] =~ /Custom.*Lookup/) ? '' : $CustomFieldNames->{'intTeamCustomLU10'}[0],
                                value => $field->{intTeamCustomLU10},
                                type  => 'lookup',
                                options => $DefCodes->{-80},
                                order => $DefCodesOrder->{-80},
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        }, 
			intTeamCustomBool1=> {
                                label => ($CustomFieldNames->{'intTeamCustomBool1'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intTeamCustomBool1'}[0],
                                value => $field->{intTeamCustomBool1},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			intTeamCustomBool2=> {
                                label => ($CustomFieldNames->{'intTeamCustomBool2'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intTeamCustomBool2'}[0],
                                value => $field->{intTeamCustomBool2},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			intTeamCustomBool3=> {
                                label => ($CustomFieldNames->{'intTeamCustomBool3'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intTeamCustomBool3'}[0],
                                value => $field->{intTeamCustomBool3},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			intTeamCustomBool4=> {
                                label => ($CustomFieldNames->{'intTeamCustomBool4'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intTeamCustomBool4'}[0],
                                value => $field->{intTeamCustomBool4},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			intTeamCustomBool5=> {
                                label => ($CustomFieldNames->{'intTeamCustomBool5'}[0] =~ /Custom.*(?:True|Checkbox)/) ? '' : $CustomFieldNames->{'intTeamCustomBool5'}[0],
                                value => $field->{intTeamCustomBool5},
                                type  => 'checkbox',
                                sectionname => 'otherdetails',
                                displaylookup => {1 => 'Yes', 0 => 'No'},
                        }, 
			strLadderName=> {
				label => 'Ladder Name',
				value => $field->{strLadderName},
				type  => 'text',
				size  => '30',
				maxsize => '50',
				sectionname => 'otherdetails',
			},
			intVenue1ID=> {
                                label => 'Venue 1',
                                value => $field->{intVenue1ID},
                                type  => 'lookup',
                                options => \%DefVenues,
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        },
			intVenue2ID=> {
                                label => 'Venue 2',
                                value => $field->{intVenue2ID},
                                type  => 'lookup',
                                options => \%DefVenues,
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        },
			intVenue3ID=> {
                                label => 'Venue 3',
                                value => $field->{intVenue3ID},
                                type  => 'lookup',
                                options => \%DefVenues,
                                firstoption => [''," "],
                                sectionname => 'otherdetails',
                        },
			dtStartTime1=> {
                                label => 'Venue 1 Start Time',
                                value => $field->{dtStartTime1},
                                type  => 'time',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'TIME',
                        },
			dtStartTime2=> {
                                label => 'Venue 2 Start Time',
                                value => $field->{dtStartTime2},
                                type  => 'time',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'TIME',
            },
dtStartTime3=> {
                                label => 'Venue 3 Start Time',
                                value => $field->{dtStartTime3},
                                type  => 'time',
                                format => 'dd/mm/yyyy',
                                sectionname => 'otherdetails',
                                validate => 'TIME',
                        },

			SPdetails    => { type =>'_SPACE_', sectionname => 'contactdetails'},
			SPteam    => { type =>'_SPACE_', sectionname => 'teamdetails'},
			SPother    => { type =>'_SPACE_', sectionname => 'otherdetails'},
		},
		order => [qw(
			intClubID
			TeamCode
			strName
			ClubName
			intCompID
			intRecStatus
			strNickname
			strCode
            intCoachID
            intManagerID
			strContactTitle
			strContact
			strAddress1
			strAddress2
			strSuburb
			strState
			strCountry
			strPostalCode
			strEmail
			strPhone1
			strPhone2
			strMobile
			strWebURL
			SP1
			strContactTitle2
			strContactName2
			strContactEmail2
			strContactPhone2
			strContactMobile2
			strContactTitle3
			strContactName3
			strContactEmail3
			strContactPhone3
			strContactMobile3
			strUniformTopColour
			strUniformBottomColour
			strUniformNumber
			strAltUniformTopColour
			strAltUniformBottomColour
			strAltUniformNumber
			intExcludeClubChampionships
			strTeamNotes
			strTeamCustomStr1
			strTeamCustomStr2
			strTeamCustomStr3
			strTeamCustomStr4
			strTeamCustomStr5
			strTeamCustomStr6
			strTeamCustomStr7
			strTeamCustomStr8
			strTeamCustomStr9
			strTeamCustomStr10
			strTeamCustomStr11
			strTeamCustomStr12
			strTeamCustomStr13
			strTeamCustomStr14
			strTeamCustomStr15
			dblTeamCustomDbl1
			dblTeamCustomDbl2
			dblTeamCustomDbl3
			dblTeamCustomDbl4
			dblTeamCustomDbl5
			dblTeamCustomDbl6
			dblTeamCustomDbl7
			dblTeamCustomDbl8
			dblTeamCustomDbl9
			dblTeamCustomDbl10
			dtTeamCustomDt1
			dtTeamCustomDt2
			dtTeamCustomDt3
			dtTeamCustomDt4
			dtTeamCustomDt5
			intTeamCustomLU1
			intTeamCustomLU2
			intTeamCustomLU3
			intTeamCustomLU4
			intTeamCustomLU5
			intTeamCustomLU6
			intTeamCustomLU7
			intTeamCustomLU8
			intTeamCustomLU9
			intTeamCustomLU10
			intTeamCustomBool1
			intTeamCustomBool2
			intTeamCustomBool3
			intTeamCustomBool4
			intTeamCustomBool5
			intVenue1ID
			intVenue2ID
			intVenue3ID
			dtStartTime1
			dtStartTime2
			dtStartTime3
		)],
        fieldtransform => {
            textcase => {
                strName => $field_case_rules->{'strName'} || '',
            }
        },
		sections => [
                        ['teamdetails',$textLabels{'Details'}],
                        ['contactdetails',$textLabels{'Additional Contacts'}],
                        ['colours',$textLabels{'Uniform Colours'}],
                        ['otherdetails',$textLabels{'Other Details'}],
                ],
		options => {
			labelsuffix => ':',
			hideblank => 1,
			target => $Data->{'target'},
			formname => 'n_form',
      submitlabel => "Update $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}",
      introtext => 'auto',
      NoHTML => 1,
      updateSQL => qq[
        UPDATE tblTeam
          SET --VAL--
        WHERE intTeamID=$teamID
        ],
      addSQL => qq[
        INSERT INTO tblTeam
          (dtTeamCreatedOnline, intAssocID, --FIELDS-- )
          VALUES (NOW(), $Data->{'clientValues'}{'assocID'}, --VAL-- )
			],
      afteraddFunction => \&postTeamAdd,
      afteraddParams => [$Data,$Data->{'db'}],
      afterupdateFunction => \&postTeamUpdate,
      afterupdateParams => [$teamID,$compID,$Data,$Data->{'db'}],

      auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Team'
      ],
      auditEditParams => [
        $teamID,
        $Data,
        'Update',
        'Team'
      ],

      LocaleMakeText => $Data->{'lang'},
		},
    carryfields =>  {
      client => $client,
      a=> $action,
	    intClubID=> $clubID ? $clubID : 0,
	    OLDintClubID=> $clubID ? $clubID : 0,
    },
  );
	
    if($teamID)	{
		#Check to see if this team is part of an active competition
		my $st=qq[
			SELECT COUNT(*) 
			FROM tblComp_Teams AS CT 
				INNER JOIN tblAssoc_Comp AS AC ON AC.intCompID=CT.intCompID 
			WHERE intTeamID=$teamID 
				AND CT.intRecStatus<> $Defs::RECSTATUS_DELETED
				AND AC.intRecStatus<> $Defs::RECSTATUS_DELETED
				AND AC.intStarted=1
		];
		my $q=$Data->{'db'}->prepare($st);
		$q->execute();
		my($cnt)=$q->fetchrow_array();
		$q->finish();
		if($cnt and $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_ASSOC)	{
			$FieldDefinitions{'fields'}{'strName'}{'readonly'}=1;
			$FieldDefinitions{'fields'}{'strNickname'}{'readonly'}=1;
		}
	}

  my $fieldperms=$Data->{'Permissions'};

  my $teamperms=ProcessPermissions(
    $fieldperms,
    \%FieldDefinitions,
    'Team',
  );
	$teamperms->{'intCompID'} = 1;
	$teamperms->{'intClubID'} = 1;
	$teamperms->{'ClubName'} = 1;
    
    my $resultHTML='';
    my $title=$field->{'strName'};
    $title="Add New $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}" if $option eq 'add';
	return \%FieldDefinitions if $Data->{'RegoForm'};
    ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, $teamperms, $option, '',$Data->{'db'});
   
    my $chgoptions='';
    
		my $logodisplay = '';
    if($option eq 'display')  {
        my $comps = showTeamComps($Data, $teamID);
        $resultHTML .= $comps;
        $chgoptions.=qq[<a href="$Data->{'target'}?client=$client&amp;a=T_DTE"><img src="images/edit_icon.gif" border="0" alt="Edit $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}" title="Edit $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}"></a> ] if allowedAction($Data, 't_e');
        $chgoptions.=qq[<a href="$Data->{'target'}?client=$client&amp;a=T_CA"><img src="images/assigncomp.gif" border="0" alt="Assign to $Data->{'LevelNames'}{$Defs::LEVEL_COMP}" title="Assign to $Data->{'LevelNames'}{$Defs::LEVEL_COMP}"></a> ] if (!$hascomp and !$Data->{'ReadOnlyLogin'} and ($Data->{'clientValues'}{authLevel} >= $Defs::LEVEL_ASSOC or allowedAction($Data, 'ac_a')));
        $chgoptions.=qq[<a href="$Data->{'target'}?client=$client&amp;a=T_CR"><img src="images/assigncomp.gif" border="0" alt="Remove from $Data->{'LevelNames'}{$Defs::LEVEL_COMP}" title="Remove from $Data->{'LevelNames'}{$Defs::LEVEL_COMP}"></a> ] if($hascomp and ($Data->{'clientValues'}{'compID'} and $Data->{'clientValues'}{'compID'} !=$Defs::INVALID_ID) and !$Data->{'ReadOnlyLogin'});
        $chgoptions .=  qq[ <a href="$Data->{'target'}?client=$client&amp;a=T_PL"><img src="images/playlist.gif" border="0" alt="Modify Member List" title="Modify Member List"></a>] if ($Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_CLUB and allowedAction($Data, 't_am') and !$Data->{'ReadOnlyLogin'});
				$logodisplay = showLogo(
					$Data,
					$Defs::LEVEL_TEAM,
					$teamID,
					$client,
					1,
				);

    }
    elsif ($option eq 'edit') {
        my $teamObj = new TeamObj(db=>$Data->{db},ID=>$teamID, assocID=>$Data->{clientValues}{assocID});
        
        my %cvals=getClient($client);
        $cvals{'teamID'}=-1;
        my $nc=setClient(\%cvals);
        
        $chgoptions.=qq[<a href="$Data->{'target'}?client=$nc&amp;a=T_DEL&amp;teamID=$teamID" onclick="return confirm('Are you sure you want to delete this $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}');"><img src="images/delete_icon.gif" border="0" alt="Delete $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}" title="Delete $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}"></a> ]  if $teamObj->canDelete() && allowedAction($Data, 't_d');
    }
    
    $chgoptions=qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
    $title=$chgoptions.$title;
		$resultHTML = $logodisplay.$resultHTML;
   
    return ($resultHTML,$title);
}


sub loadTeamDetails {
  my($db, $id) = @_;
  return {} if !$id;
  my $statement=qq[
    SELECT T.*, A.intAssocTypeID, C.strName as ClubName
    FROM tblTeam as T
	LEFT JOIN tblAssoc as A ON (A.intAssocID = T.intTeamID)
	LEFT JOIN tblClub as C ON (C.intClubID=T.intClubID)
    WHERE intTeamID=$id
  ];
  my $query = $db->prepare($statement);
  $query->execute;
	my $field=$query->fetchrow_hashref();
  $query->finish;
  foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
  return $field;
}

sub showTeamComps	{

	my ($Data, $teamID) = @_;

	return '' if ! $teamID;
	my $st = qq[
		SELECT DISTINCT AC.strTitle, S.strSeasonName, dtStart AS dtStartRAW, DATE_FORMAT(dtStart,"%d/%m/%Y") AS dtStart, strGradeDesc, A.intAllowSeasons, CompType.strName as CompTypeName, CompLevel.strName as CompLevelName, CT.intRecStatus as CompTeamRecStatus, AC.intRecStatus as AssocCompRecStatus
		FROM tblComp_Teams as CT
			INNER JOIN tblAssoc_Comp as AC ON (AC.intCompID = CT.intCompID)
			INNER JOIN tblAssoc as A ON (A.intAssocID = AC.intAssocID)
			LEFT JOIN tblSeasons as S ON (S.intSeasonID = AC.intNewSeasonID)
			LEFT JOIN tblAssoc_Grade as AG ON (AG.intAssocGradeID = AC.intGradeID)
			LEFT JOIN tblDefCodes as CompType ON (AC.intCompTypeID = CompType.intCodeID)	
			LEFT JOIN tblDefCodes as CompLevel ON (AC.intCompTypeID = CompLevel.intCodeID)	
		WHERE CT.intTeamID = $teamID
			AND CT.intRecStatus <> $Defs::RECSTATUS_DELETED
			AND AC.intRecStatus <> $Defs::RECSTATUS_DELETED
		ORDER BY dtStartRAW DESC, strTitle
	];
	
	my $query = $Data->{'db'}->prepare($st);
        $query->execute;

	my $subBody = '';

	my $cnt = 0;
	my $allowSeasons = 0;
	my @rowdata=();
	while(my $dref=$query->fetchrow_hashref())      {
		$allowSeasons = $dref->{intAllowSeasons} || 0;
		my $class = $cnt % 2 == 0 ? 'rowshade' : '';
		my $activeInComp = $dref->{CompTeamRecStatus} == 1 ? 'Yes' : 'No';
		my $activeComp = $dref->{AssocCompRecStatus} == 1 ? 'Yes' : 'No';
		push @rowdata, {
      id => $cnt,
      strTitle=> $dref->{'strTitle'},
      dtStart=> $dref->{'dtStart'},
      strGradeDesc=> $dref->{'strGradeDesc'},
      CompLevelName=> $dref->{'CompLevelName'},
      CompTypeName=> $dref->{'CompTypeName'},
      activeInComp=> $activeInComp,
      activeComp=> $activeComp,
			strSeasonName =>$dref->{'strSeasonName'},
    };
		$cnt++;
	}

    
	my $txt_SeasonName= $Data->{'SystemConfig'}{'txtSeason'} || 'Season';
	my $body='';
	my @headerdata = (
    {
      name => 'Competition Title',
      field => 'strTitle',
    },
    {
      name => 'Date Started',
      field => 'dtStart',
    },
    {
      name => 'Grade',
      field => 'strGradeDesc',
    },
    {
      name => 'Level',
      field => 'CompLevelName',
    },
    {
      name => 'Type',
      field => 'CompTypeName',
    },
    {
      name => 'Team Active in Competition ?',
      field => 'activeInComp',
    },
    {
      name => 'Active Competition ?',
      field => 'activeComp',
    },
  );
	push @headerdata, {
	name=>"$txt_SeasonName", 
		field=>'strSeasonName',
	} if $allowSeasons;

	if ($cnt)	{
		$body .= showGrid(
      Data => $Data,
      columns => \@headerdata,
      rowdata => \@rowdata,
      gridid => 'grid',
      width => '99%',
      height => 400,
			simple => 1,
    );
	}

	return $body;
}

sub assignPlayersToTeam	{
	my ($Data, $teamID) = @_;

	my $db = $Data->{'db'};
	my $q=new CGI;
	my %params=$q->Vars();
	return ('', "Error") if $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_CLUB;

	my $intClubID =$Data->{'clientValues'}{'clubID'} || 0;
	my $intAssocID = getAssocID($Data->{'clientValues'}) || 0;
	my $intCompID =$Data->{'clientValues'}{'compID'} || 0;

	$intCompID = $params{'intCompID'} if $intCompID <= 0 and $params{'intCompID'};
	
	if ($params{'dobFrom'} or $params{'dobTo'}) {
			$params{'dobFromFixed'} = formatDate($params{'dobFrom'});
			$params{'dobToFixed'} = formatDate($params{'dobTo'}) ;
			$params{'dobFrom'} = '' if ! $params{'dobFromFixed'};
			$params{'dobTo'} = '' if ! $params{'dobToFixed'};
	}
	my $body=qq[];
																																																		
	#To do this we need to come up with two lists.
	my %all_players = ();
	my %selected_players = ();

	my $comp_st = qq[
		SELECT tblAssoc_Comp.intCompID, tblAssoc_Comp.strTitle, tblSeasons.strSeasonName
		FROM tblAssoc_Comp
			INNER JOIN tblComp_Teams ON (tblComp_Teams.intCompID = tblAssoc_Comp.intCompID)
			INNER JOIN tblSeasons ON (tblAssoc_Comp.intSeasonID = tblSeasons.intSeasonID)
		WHERE tblComp_Teams.intTeamID = $teamID
			AND tblAssoc_Comp.intRecStatus <> $Defs::RECSTATUS_DELETED
			AND tblComp_Teams.intRecStatus <> $Defs::RECSTATUS_DELETED
	];
	my $comp_qry= $db->prepare($comp_st);
	$comp_qry->execute;
	my $comp_name = '';
	my $season_name = '';
	my $comp_selected = $intCompID ? 'SELECTED' : '';
	my $comp_client = setClient($Data->{'clientValues'}) || '';
	my $complist = qq[
		<form action="$Data->{'target'}" method="post">
			<p><b>Show Members within Competition:</b>
			<input type="hidden" name="activeorder" value="">
			<input type="hidden" name="a" value="T_PL">
			<input type="hidden" name="client" value="$comp_client">
			<select name="intCompID"><option $comp_selected value="">--All--</option>
	];
	my $comp_count=0;
	while (my $dref=$comp_qry->fetchrow_hashref())	{
		$comp_count++;
		$comp_name = $dref->{strTitle};
		$season_name = $dref->{strSeasonName};
		$comp_selected = ($dref->{intCompID} == $intCompID) ? 'SELECTED' : '';
		$complist .= qq[<option $comp_selected value="$dref->{intCompID}">$dref->{strTitle}</option>];	
	}
	$complist .= qq[
		</select>
		<input type="submit" value="Filter" name="submit">
		</p>
		</form><br>
	];
	$complist = '' if $comp_count <= 1 or $Data->{'clientValues'}{'compID'} > 0;
	my $stt=qq[
		SELECT strName, intClubID
		FROM tblTeam
		WHERE intTeamID = ?
		LIMIT 1
	];
	my $query = $db->prepare($stt);
	$query->execute($teamID);
	my($teamname, $DBteamClub) = $query->fetchrow_array();
	$intClubID=$DBteamClub if $DBteamClub;
	$query->finish;
	my $listtype='';
	{
    my $statement = '';

	
	my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
	my $seasonID = param('seasonFilter') || $assocSeasons->{'currentSeasonID'};
	my $ageGroupID = param('ageGroupFilter') || 0;
	my $ageGroup_WHERE = '';
	if ($ageGroupID )	{
		$ageGroup_WHERE = qq[ AND MS.intPlayerAgeGroupID = $ageGroupID];
		if ($ageGroupID== -1)	{
			$ageGroup_WHERE = qq[ AND (MS.intPlayerAgeGroupID = 0 or MS.intPlayerAgeGroupID IS NULL)];
		}
	}
	my $MStablename = "tblMember_Seasons_$Data->{'Realm'}";
                                #AND MS.intSeasonID = $seasonID
				#$ageGroup_WHERE
        my $season_JOIN = qq[
                        LEFT JOIN $MStablename as MS ON (MS.intMemberID = M.intMemberID
                                AND MS.intAssocID = $intAssocID AND MS.intMSRecStatus = 1)
        ];
        my $season_WHERE = '';

        $statement = qq[
            SELECT M.intMemberID, strMemberNo, M.strFirstName, M.strSurname, DATE_FORMAT(M.dtDOB, '%Y%m%d'), MT.intTeamID, MT.intStatus, MS.intSeasonID, MS.intPlayerAgeGroupID, DATE_FORMAT(M.dtDOB, '%d/%m/%Y') as FormattedDOB
			FROM tblMember as M
			$season_JOIN
		];
		if ($intClubID and $intClubID > 0)	{
			$statement .= qq[ INNER JOIN tblMember_Clubs as MC ON (MC.intMemberID = M.intMemberID and MC.intClubID = $intClubID and MC.intStatus = $Defs::RECSTATUS_ACTIVE ) ];
			$listtype=$Defs::LEVEL_CLUB;
			$season_WHERE = qq[ WHERE MS.intClubID = $intClubID];
		}
		if ($intAssocID and $intAssocID > 0)	{
			$statement .= qq[ INNER JOIN tblMember_Associations as MA ON (MA.intMemberID = M.intMemberID and MA.intAssocID = $intAssocID AND MA.intRecStatus=$Defs::RECSTATUS_ACTIVE) ];
			$listtype=$Defs::LEVEL_ASSOC;
		}
		else	{ return qq[UNABLE]; }
		my $comp_where=($intCompID and $intCompID > 0) ? " and (MT.intCompID=$intCompID or MT.intCompID=0) " : '';
		$statement .= qq[
				LEFT JOIN tblMember_Teams as MT ON (MT.intMemberID = M.intMemberID and MT.intTeamID = $teamID $comp_where)
		];
		$statement .= $season_WHERE;
		my $query = $db->prepare($statement) or query_error($statement);
		$query->execute or query_error($statement);

		while(my ($DB_intMemberID, $DB_strMemberNo, $DB_strFirstname,$DB_strSurname, $DB_DOB, $DB_intTeamID, $DB_intStatus, $DB_intSeasonID, $DB_intAgeGroupID, $DB_DOBFormat) = $query->fetchrow_array())  {
			$DB_intSeasonID ||= 0;
			$DB_intAgeGroupID ||= 0;
			if ($DB_intTeamID and $DB_intStatus == $Defs::RECSTATUS_ACTIVE)	{
				$selected_players{$DB_intMemberID} = 1;
			}
			my $mnum=$DB_strMemberNo ? " ($DB_strMemberNo)" : '';
			$DB_DOBFormat = ($DB_DOBFormat and $DB_DOBFormat ne '00/00/0000') ? qq[ - $DB_DOBFormat] : '';
			$all_players{$DB_intMemberID}{'name'}="$DB_strSurname, $DB_strFirstname$mnum$DB_DOBFormat";
			$all_players{$DB_intMemberID}{'dob'} = $DB_DOB;
			$all_players{$DB_intMemberID}{"seasonID_$DB_intSeasonID"} = 1;
			$all_players{$DB_intMemberID}{"ageGroupID_$DB_intAgeGroupID"} = $DB_intSeasonID;
			$all_players{$DB_intMemberID}{'dob'} =~s/\-//g;
		}
		$query->finish;
	}
	my $client = setClient($Data->{'clientValues'}) || '';
	my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
	my $season = param('seasonFilter') || $assocSeasons->{'currentSeasonID'};
	my $ageGroup= param('ageGroupFilter') || 0;
	my $seasonsFilter = '';
	my $ageGroupsFilter = '';
	if ($assocSeasons->{'allowSeasons'})	{
		my ($Seasons, undef) =Seasons::getSeasons($Data);
		my $txt_SeasonName= $Data->{'SystemConfig'}{'txtSeason'} || 'Season';
		$seasonsFilter = qq[<div><label>$txt_SeasonName</label>].drop_down('seasonFilter',$Seasons,undef,$season,1,0) . qq[</div>];

		$Data->{'AllAgeGroups'} = 1;
		$Data->{'BlankAgeGroup'} = 1;
		my ($AgeGroups, undef) =AgeGroups::getAgeGroups($Data);
		my $txt_AgeGroupName= $Data->{'SystemConfig'}{'txtAgeGroup'} || 'Age Group';
		$ageGroupsFilter = qq[<div><label>$txt_AgeGroupName</label>].drop_down('ageGroupFilter',$AgeGroups,undef,$ageGroup,1,0) . qq[</div>];
	}
	my $js = qq[jQuery(".dateinput").datepicker({ dateFormat: 'dd/mm/yy', autoSize: true });];
	$Data->{'AddToPage'}->add('js_bottom','inline',$js);
	

	#warning message.
	my $st = qq[select strTitle, strSeasonName from tblAssoc_Comp
	INNER JOIN tblSeasons on tblSeasons.intSeasonID = tblAssoc_Comp.intNewSeasonID 
	WHERE intCompID = $intCompID LIMIT 1];
 	$query = $db->prepare($st);
        $query->execute();
        my ($compName, $compSeason) =  $query->fetchrow_array();
	my $warningDropin = ''; 
 	if($intCompID>0 and $compName !='' and $compSeason !='') {
                $warningDropin = qq[<p style="color:red">You are modifying the members in the team $teamname for the competition $compName ($compSeason)</p>];
        }

	$body.=qq[
	<p>Use this screen to drag $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER.'_P'} from the box on the left into the $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} (box on the right).  When you have finished press the 'Save' button.</p>
	$warningDropin
	$complist
		<form action="$Data->{'target'}" method="post" name="comboForm" class="mod-team-list">
			<input type="hidden" id = "activeorder" name="activeorder" value="">
			<input type="hidden" name="a" value="T_PLs">
			<input type="hidden" name="client" value="$client">
			<input type="hidden" name="intCompID" value="$intCompID">
    	<div class="dbdata">
				<div class="mod-filter-wrap">
				$seasonsFilter
				$ageGroupsFilter
				<div class="dobfilter">
					<label>DOB From</label><input type="text" name="dobFrom" value="$params{dobFrom}" size="10" class = "dateinput">&nbsp;<span class="format">(dd/mm/yyyy)</span> &nbsp; <b>To</b> &nbsp; <input type="text" name="dobTo" value="$params{dobTo}" size="10" class = "dateinput">&nbsp;<span class="format">(dd/mm/yyyy)</span><br>
					<!--input type="submit" name="dobFilter" value="Filter $Data->{'LevelNames'}{$listtype} Members"  onclick="return update_fn()" class = "button generic-button">&nbsp;-->
				</div></div>
				<input type="submit" value="Update Filters / Save Member List" name="submitbutton" class = "button proceed-button">
				<div style = "clear:both;"></div>
	];

	my @leftbox = ();
	foreach my $key (sort {  uc($all_players{$a}{'name'}) cmp   uc($all_players{$b}{'name'})}  keys %all_players) {
		next if exists $selected_players{$key};
		next if $params{'dobFrom'} and $all_players{$key}{'dob'} < $params{'dobFromFixed'};
		next if $params{'dobTo'} and $all_players{$key}{'dob'} > $params{'dobToFixed'};
		if ($season and $assocSeasons->{'allowSeasons'})	{
			if ($season == -1 and defined $all_players{$key}{"seasonID_$season"} )	{
				next;
			}
			elsif ($season and  ! defined $all_players{$key}{"seasonID_$season"})	{
				next;
			}
		}
		if ($ageGroup and $assocSeasons->{'allowSeasons'})	{
			if ($ageGroup == -1)	{
				next if defined $all_players{$key}{"ageGroupID_$ageGroup"};
			}
			elsif ($ageGroup == -99)	{
				#do nothing
			}
			elsif ($ageGroup)	{
				if ($season)	{
					next if ($all_players{$key}{"ageGroupID_$ageGroup"} != $season);
				}
				else	{
					next if ! defined $all_players{$key}{"ageGroupID_$ageGroup"};
				}
			}
		}
		push @leftbox, [$key, $all_players{$key}{'name'}];
	}
	my $count=0;
	my @rightbox = ();
	foreach my $key (keys %selected_players) {
		$count++;
		next if !$all_players{$key};
		push @rightbox, [$key, $all_players{$key}{'name'}];
	}
	my $boxes = getMoveSelectBoxes($Data, 'choosebox','Available Members','Selected Members',\@leftbox,\@rightbox,400,360, 'activeorder');
	$body.=qq[

		$boxes
			</div>
			</form>
	];
	return ($body, "Modify $teamname Member List");
}

sub inviteTeammates {
    my ($Data, $client, $teamID) = @_;

	my $teamObj = getInstanceOf($Data, 'team', $teamID);
    my $assocID = $teamObj->getValue('intAssocID');

    my ($seasonsDD, $numSeasons) = genDropdownOptions($Data, {optType=>1, teamID=>$teamID, format=>'select'});
    my ($compsDD, $numComps)     = genDropdownOptions($Data, {optType=>2, teamID=>-1, seasonID=>-1, format=>'select'}); #force basic (almost empty) select dropdown
    my ($formsDD, $numForms)     = genDropdownOptions($Data, {optType=>3, assocID=>$assocID, clubID=>-1, formType=>$Defs::REGOFORM_TYPE_MEMBER_TEAM, format=>'select'});

    my $alwaysNew = $Data->{'SystemConfig'}{'rego_AlwaysNew'} || '';

    my %templateData = (
        seasonsDD => $seasonsDD,
        compsDD   => $compsDD,
        formsDD   => $formsDD,
        TeamID    => $teamID,
        AssocID   => $assocID,
        Client    => $client,
        AlwaysNew => $alwaysNew,
    );

    my $templateFile = 'team/invite_teammates.templ';
    my $body = runTemplate($Data, \%templateData, $templateFile);

    return ($body, 'Invite your teammates to join your team');
}

sub updateTeamList	{
	my ($Data, $teamID) = @_;

	my $db = $Data->{'db'};
	my $q=new CGI;
	my %params=$q->Vars();
	return if ! $params{'submitbutton'};
	$teamID ||= 0;
	my %currentPlayers = ();
	my $players=$params{'activeorder'} || '';
	my $intCompID =$Data->{'clientValues'}{'compID'} || 0;
	$intCompID = $params{'intCompID'} if $intCompID <= 0 and $params{'intCompID'};
	my $assocID = $Data->{'clientValues'}{'assocID'};
	my $comp_where=($intCompID and $intCompID > 0) ? " and (intCompID=$intCompID or intCompID=0 or intCompID=-1)" : '';
    ## WARREN, FOR THE MEMBER ROLLOVER, I BELIEVE THIS IS THE LINE THAT NEEDS TO CHANGE.
    ##
    ## I would look at leaving the above, but adding this:
    # if (don't roll over members permission) {
	#$comp_where= qq[and intCompID=$intCompID] if ($intCompID and $intCompID>0);
    # }
    ##
    ## This will then only grab members who are in the comp.


	my $statement=qq[
		SELECT DISTINCT intMemberID, intMemberTeamID, intStatus
		FROM tblMember_Teams
		WHERE intTeamID=$teamID
			$comp_where
		ORDER BY intCompID DESC
	];
	$intCompID = 0 if $intCompID <=0;
	my $query = $db->prepare($statement) or query_error($statement);
	$query->execute or query_error($statement);
	while(my ($DB_intMemberID, $DB_intMemberTeamID, $DB_intStatus) = $query->fetchrow_array())  {
		next if exists $currentPlayers{$DB_intMemberID};
		$currentPlayers{$DB_intMemberID} = [$DB_intMemberTeamID, $DB_intStatus];
	}
	$query->finish;


	my $st = qq[
		SELECT DISTINCT CT.intCompID, intNewSeasonID
		FROM tblComp_Teams as CT
			INNER JOIN tblAssoc_Comp as AC ON (AC.intCompID = CT.intCompID)
		WHERE CT.intTeamID=$teamID
			AND CT.intRecStatus = $Defs::RECSTATUS_ACTIVE
			AND AC.intRecStatus = $Defs::RECSTATUS_ACTIVE
	];
	my $qry_comps = $db->prepare($st);

	$statement=qq[
		INSERT INTO tblMember_Teams (intMemberID, intTeamID, intStatus, intCompID) VALUES (?, $teamID, $Defs::RECSTATUS_ACTIVE, ?)
	];
	$query = $db->prepare($statement);

	my $st_update = qq[
		UPDATE tblMember_Teams
		SET intStatus = $Defs::RECSTATUS_ACTIVE
	];
	#$st_update .= qq[, intCompID = $intCompID] if $intCompID and $intCompID > 0;
	$st_update .= qq[, intCompID = $intCompID]  if $intCompID >= 0;
	$st_update .= qq[
		WHERE intMemberTeamID = ?
	];
	my $query_update = $db->prepare($st_update);

	my @players=split /\|/,$players;
	my $genAgeGroup ||=new GenAgeGroup ($Data->{'db'},$Data->{'Realm'}, $Data->{'RealmSubType'}, $Data->{'clientValues'}{'assocID'});

	my $DB_intNewSeasonID = 0;
	my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
	my %Comp_Seasons = ();
	if ($intCompID)	{
		## We have a CompID, lets get what season its in
		my $st_comp = qq[
			SELECT intNewSeasonID
			FROM tblAssoc_Comp
			WHERE intCompID = $intCompID
				AND intAssocID = $assocID
		];
        	my $qry_compSeason= $db->prepare($st_comp);
        	$qry_compSeason->execute or query_error($st_comp);
        	$DB_intNewSeasonID = $qry_compSeason->fetchrow_array() || $assocSeasons->{'newRegoSeasonID'};
		$Comp_Seasons{$intCompID} = $DB_intNewSeasonID;
	}
	for my $id  (@players)    {
		if (exists $currentPlayers{$id} and $intCompID > 0)	{
			my $intMemberTeamID = $currentPlayers{$id}[0] || 0;
			$query_update->execute($intMemberTeamID);
			delete $currentPlayers{$id};
		}
		else	{ 
			my $comp_counts=0;
			$qry_comps->execute or query_error($st);
			
			if ($intCompID)	{
				$comp_counts++;
				$query->execute($id, $intCompID) if $id>0; 	
				my $st_upd = qq[
					UPDATE tblMember_Teams
					SET intStatus = $Defs::RECSTATUS_ACTIVE 
					WHERE intMemberID =$id
						AND intTeamID = $teamID
						AND intCompID = $intCompID
				]; 
				my $qry_up = $db->prepare($st_upd);
				$qry_up->execute();
			}
			else	{
				while(my ($DB_intCompID, $DB_intNewSeasonID) = $qry_comps->fetchrow_array())  {
					$DB_intNewSeasonID ||= $assocSeasons->{'newRegoSeasonID'};
					$Comp_Seasons{$intCompID} = $DB_intNewSeasonID;
					$comp_counts++;
					$query->execute($id, $DB_intCompID) if $id>0 and $DB_intCompID != $intCompID; 	
					my $st_upd = qq[
						UPDATE tblMember_Teams
						SET intStatus = $Defs::RECSTATUS_ACTIVE 
						WHERE intMemberID =$id
							AND intTeamID = $teamID
							AND intCompID = $DB_intCompID
					]; 
					my $qry_up = $db->prepare($st_upd);
					$qry_up->execute();
				}
			}
			if (! $comp_counts)	{
				if (exists $currentPlayers{$id})	{
					my $intMemberTeamID = $currentPlayers{$id}[0] || 0;
					$query_update->execute($intMemberTeamID);
				}
				$query->execute($id,0) if $id>0 and ! $comp_counts; 	
			}
			delete $currentPlayers{$id}; ### BAFF LOOK HERE AS WELL
		}
	}   
	$query_update->finish;
	$query->finish;
	my $compwhere=($intCompID and $intCompID > 0)? qq[AND (intCompID = $intCompID or intCompID=0 or intCompID=-1)] : '';
	#my $compwhere=qq[AND (intCompID = $intCompID or intCompID=0 or intCompID=-1)]; ### COMMENTED OUT 14/3/2008
	### BAFF CHECK THIS - WR 3/11/06
	$statement = qq[
		UPDATE tblMember_Teams
		SET intStatus = $Defs::RECSTATUS_DELETED
		WHERE intMemberID = ? 
						AND intTeamID = $teamID
						AND intStatus = $Defs::RECSTATUS_ACTIVE
		$compwhere
	];
	$query = $db->prepare($statement);
	foreach my $values (keys %currentPlayers)	{
		$query->execute($values);
	}
	$query->finish;

	$statement = qq[
		UPDATE tblMember_Teams
		SET intStatus = $Defs::RECSTATUS_DELETED
		WHERE intTeamID = $teamID
			AND intStatus = $Defs::RECSTATUS_ACTIVE
			AND intCompID = -1
	];
	$query = $db->prepare($statement);
	$query->execute();
																							
	foreach my $compID (keys %Comp_Seasons)	{
        $Data->{'memberListIntoComp'}=1 if ($intCompID and $compID == $intCompID);
		## For all the Comp_Team records lets check the members Season records
		checkForMemberSeasonRecord($Data, $compID, $teamID, 0);
	}
  auditLog($teamID, $Data, 'Update Member List','Team');
	return qq[<div class="OKmsg">$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} updated successfully</div>];
}
sub formatDate  {
  my($date)=@_;
	my ($day, $month, $year)=split /\//,$date;

	if(defined $year and $year ne '' and defined $month and $month ne '' and defined $day and $day ne '
') {
		return '' if $day!~/^\d+$/;
		return '' if $month!~/^\d+$/;
		return '' if $year!~/^\d+$/;
		$month='0'.$month if length($month) ==1;
		$day='0'.$day if length($day) ==1;
		if($year > 20 and $year < 100)  {$year+=1900;}
		elsif($year <=20) {$year+=2000;}
		$date="$year$month$day";
	}
	else  { $date='';}
	return $date;
}


sub postTeamUpdate {
    my($id,$params, $teamID, $existingCompID, $Data,$dbh)=@_;

    return (0,undef) if !$dbh;

	my $clubID = $params->{'d_intClubID'} || 0;
	my $OLDclubID = $params->{'OLDintClubID'} || 0;
	$teamID ||= 0;

  $Data->{'cache'}->delete('swm',"TeamObj-$teamID") if $Data->{'cache'};

	if ($clubID and $teamID)	{
		my $st = qq[
			SELECT DISTINCT MT.intMemberID
			FROM tblMember_Teams as MT
				LEFT JOIN tblMember_Clubs as MC ON (
					MC.intMemberID = MT.intMemberID
					AND MC.intClubID = $clubID
					AND MC.intStatus = $Defs::RECSTATUS_ACTIVE
				)
			WHERE MT.intTeamID = $teamID
				AND MT.intStatus=$Defs::RECSTATUS_ACTIVE
				AND MC.intMemberClubID IS NULL
		];
    		my $query = $Data->{'db'}->prepare($st);
                $query->execute;

    		while (my($intMemberID) = $query->fetchrow_array) {
			my $insert_st = qq[
				INSERT IGNORE INTO tblMember_Clubs (intMemberID, intClubID , intStatus)
				VALUES ($intMemberID, $clubID, 1)
			];
			$dbh->do($insert_st);
        }
		
        if ($Data->{'SystemConfig'}{'allowTeamIntoComp_MembersRollover'} or ($OLDclubID ==0 and $clubID>0))	{
    			my $compID = 0;
					$compID = $Data->{'clientValues'}{'compID'} if ($Data->{'clientValues'}{'compID'} and $Data->{'clientValues'}{'compID'}>0);
            $Data->{'memberListIntoComp'}=1;
		    checkForMemberSeasonRecord($Data, $compID, $teamID, 0);
        }
	}	
	return ;

    my $compID = $params->{'d_intCompID'};
    
    # Check if the comp has started.
    my $query = qq[SELECT intStarted FROM tblAssoc_Comp WHERE intCompID = $compID];
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my($intStarted) = $sth->fetchrow_array();
    
    return (0,undef) if $intStarted;
    
    my $result ;
    
    if ($existingCompID) {
        ($result,undef) = &removeTeamFromComp($Data,$teamID,$existingCompID);
    }       

    # No problem removing team from comp, add to comp if selected.
    if ($result !~/problem/i && $teamID) {
        $result .= &updateAssignCompTeam($Data,$compID,[$teamID]) if $compID;
    }
    
    my $cl=setClient($Data->{'clientValues'}) || '';
    my %cv=getClient($cl);
    $cv{'teamID'}=$teamID;
    $cv{'currentLevel'} = $Defs::LEVEL_TEAM;
    my $clm=setClient(\%cv);

    return (0,$result . qq[<div class="OKmsg"> ] . $Data->{'lang'}->txt('[_1] updated successfully', $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}) . qq[</div><br>
                           <a href="$Data->{'target'}?client=$clm&amp;a=T_HOME">] . $Data->{'lang'}->txt('Display details for [_1]', $params->{'d_strName'}) . qq[</a><br><br>]);
}


sub postTeamAdd	{
  my($id,$params, $Data,$db)=@_;

  return (0,undef) if !$db;
  my $compAddResult;
  
	if($id) {
		if($Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'clubID'} !=$Defs::INVALID_ID) {
			my $st = qq[
				UPDATE
					tblTeam
				SET 
					intClubID = $Data->{'clientValues'}{'clubID'}
				WHERE
					intTeamID = $id
				LIMIT 1;
			];
			$db->do($st);
		}
		my $compID;
        
        #if($Data->{'clientValues'}{'compID'} and $Data->{'clientValues'}{'compID'} !=$Defs::INVALID_ID) {
        #    $compID = $Data->{'clientValues'}{'compID'};
        #}
        #elsif ($params->{'d_intCompID'}) {
        #    $compID = $params->{'d_intCompID'};
        #} 
 
        if ($params->{'d_intCompID'}) {
            $compID = $params->{'d_intCompID'};
        }
        elsif($Data->{'clientValues'}{'compID'} and $Data->{'clientValues'}{'compID'} !=$Defs::INVALID_ID) {
            $compID = $Data->{'clientValues'}{'compID'};
        }

       
        $compAddResult = &updateAssignCompTeam($Data,$compID,[$id]) if $compID;
                       
        #my $st=qq[INSERT INTO tblComp_Teams (intTeamID,intCompID) VALUES ($id,?)];
        #if ($compID) {
        #    my $sth = $db->prepare($st);
        #    $sth->bind_param(1,$compID);
        #    $sth->execute();
        #}
		
		## BAFF - DO WE NEED TO ADD NEW tblMember_Teams records here
        my $st=qq[UPDATE tblTeam SET intRecStatus = $Defs::RECSTATUS_ACTIVE WHERE intTeamID = $id];
        $Data->{'db'}->do($st);
        insertDefaultRegoTXN($db, $Defs::LEVEL_TEAM, $id, $Data->{'clientValues'}{'assocID'});
    }

	{
		my $cl=setClient($Data->{'clientValues'}) || '';
		my %cv=getClient($cl);
		$cv{'teamID'}=$id;
		$cv{'currentLevel'} = $Defs::LEVEL_TEAM;
		my $clm=setClient(\%cv);
	
        return (0,$compAddResult . qq[
			<div class="OKmsg"> $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} added successfully</div><br>
			<a href="$Data->{'target'}?client=$clm&amp;a=T_HOME">Display details for $params->{'d_strName'}</a><br><br>
			<b>or</b><br><br>
			<a href="$Data->{'target'}?client=$cl&amp;a=T_DTA&amp;l=$Defs::LEVEL_TEAM">Add another $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}</a>
		]);
    }

	return (1,'');
}

sub assignComp {
  my ($Data, $teamID)=@_;
  my $body=qq[
    <p>To assign this $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} to a $Data->{'LevelNames'}{$Defs::LEVEL_COMP} choose from the options below and press the 'Assign' button.</p><p> <b>Note:</b>$Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'} cannot be assigned to a $Data->{'LevelNames'}{$Defs::LEVEL_COMP} that has already started.</p>
	];

	my $statusWhere = $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_CLUB ? qq[ AND AC.intRecStatus= $Defs::RECSTATUS_ACTIVE ] : '';
	my $st =qq[
		SELECT AC.strTitle ,AC.intCompID, strSeasonName
		FROM tblAssoc_Comp AC
		LEFT JOIN tblSeasons S ON S.intSeasonID=AC.intNewSeasonID
		WHERE AC.intAssocID=$Data->{'clientValues'}{'assocID'}
			AND AC.intStarted=0
			AND AC.strTitle <> ''
			$statusWhere
		ORDER BY strSeasonName DESC, AC.strTitle
	];
	my $comps='';
	my $q=$Data->{'db'}->prepare($st);
	$q->execute();
	while (my($name, $cID, $strSeasonName)=$q->fetchrow_array())	{
		$comps.=qq[<option value="$cID">$strSeasonName - $name</option>];
	}
	my $unesc_cl=unescape(setClient($Data->{'clientValues'})) || '';
	if($comps)	{
		$comps=qq[
			<form action="$Data->{'target'}" method="POST">
				<select name="newcompID" size="1">$comps</select><br><br>
				<input type="hidden" name="a" value="T_CAU">
				<input type="hidden" name="client" value="$unesc_cl">
				<input type="submit" value="Assign">
			</form>
		];
	}
	else	{
		$comps=qq[<div class="warningmsg">No available $Data->{'LevelNames'}{$Defs::LEVEL_COMP.'_P'}  could be found</div>];
	}
	$body.=$comps;
	my $title=qq[Assign $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} to a $Data->{'LevelNames'}{$Defs::LEVEL_COMP}];
  return ($body,$title);
}


# New version of UpdateassignComp, thats excepts a list of teams.
sub updateAssignCompTeam {
  my ($Data, $compID, $Teams, $multi) = @_;
  if(!$compID or $compID!~/^\d+$/)	{
		return "ERROR:You must select a $Data->{'LevelNames'}{$Defs::LEVEL_COMP}";
	}
  my $dbh = $Data->{'db'}; 
  # Get comp data for checking if the comp has started and number of teams.
  my $query = qq[
    SELECT 
      intStarted, 
      intNumTeams,
      intSWOL,
      intNominations
    FROM 
      tblAssoc_Comp
      INNER JOIN tblAssoc USING(intAssocID)
    WHERE 
      intCompID = $compID
    ];
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my ($DBstarted, $DB_numTeams, $swol, $team_nominations) = $sth->fetchrow_array();
    # Check if the comp has started.
    if($DBstarted)	{
      return "<p class=\"warningmsg\">ERROR:This $Data->{'LevelNames'}{$Defs::LEVEL_COMP} has started already and can't be joined.</p>";
    }
    my $noTeams = scalar(@{$Teams});

    my $st = qq[
      SELECT
        intTeamID,
        intRecStatus
      FROM 
        tblComp_Teams 
      WHERE 
        intCompID = ? 
        AND intTeamID != 0
    ];
    my $q = $dbh->prepare($st) or query_error($st);
    $q->execute($compID);
    my %ExistingTeams = ();
    my $noTeamsInComp = 0;
    while (my $href = $q->fetchrow_hashref()) {
      $ExistingTeams{$href->{'intTeamID'}} = $href->{'intRecStatus'};
      $noTeamsInComp++ if $href->{'intRecStatus'} == 1;
    }
    my $totalTeams = $noTeams > 1 ? $noTeams : $noTeamsInComp + 1;
    if ($totalTeams > $DB_numTeams) {
      my $err_msg = qq [
        <p class="warningmsg">
        ERROR:You have selected more $Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'} than this $Data->{'LevelNames'}{$Defs::LEVEL_COMP} allows.<br />
        Maximum number of teams for this $Data->{'LevelNames'}{$Defs::LEVEL_COMP} is $DB_numTeams.<br />
        Please adjust the $Data->{'LevelNames'}{$Defs::LEVEL_COMP} setup if you wish to add additional  $Data->{'LevelNames'}{$Defs::LEVEL_TEAM . '_P'}.</p>
      ];
      return $err_msg;
    }
    my $st_update_team = qq[
      UPDATE IGNORE 
        tblComp_Teams 
      SET 
        intRecStatus = $Defs::RECSTATUS_ACTIVE, 
        intTeamNum = ? 
      WHERE 
        intCompID = ? 
        AND intTeamID = ?
    ];
    my $q_update_team = $dbh->prepare($st_update_team) or query_error($st_update_team);
    my $st_insert_team = qq[
      INSERT IGNORE INTO tblComp_Teams (
        intCompID, 
        intTeamID,
        intTeamNum
      ) 
      VALUES (
        ?, 
        ?,
        ?
      )
    ];
    my $q_insert_team = $dbh->prepare($st_insert_team) or query_error($st_insert_team);
    my $st_update_member_teams_status = qq[
      UPDATE IGNORE 
        tblMember_Teams 
      SET 
        intStatus = $Defs::RECSTATUS_ACTIVE 
      WHERE 
        intCompID = ? 
        AND intTeamID = ?
    ]; 
    my $q_update_member_teams_status = $dbh->prepare($st_update_member_teams_status) or query_error($st_update_member_teams_status);
    my $st_update_member_teams_compID = qq[
      UPDATE IGNORE 
        tblMember_Teams 
      SET 
        intCompID = ?  
      WHERE 
        (intCompID=0 or intCompID = -1) 
        AND intTeamID = ?
        AND intStatus = $Defs::RECSTATUS_ACTIVE
    ];
    my $q_update_member_teams_compID = $dbh->prepare($st_update_member_teams_compID) or query_error($st_update_member_teams_compID);
    my $st_regrade_log = qq[
      INSERT INTO tblRegradeLog (
        intAssocID,
        intTeamID,
        intCompID,
        strAction,
        tTimeStamp,
        intCompPoolID,
        intCompStageID
      )
      VALUES (
        ?,
        ?,
        ?,
        ?,
        now(),
        ?,
        ?
      )
    ];
    my $q_regrade_log = $dbh->prepare($st_regrade_log) or query_error($st_regrade_log);
    my $teamNum = $noTeams > 1 ? 1 : $noTeamsInComp + 1;

    foreach my $teamID ( @{$Teams} ) {
        if($teamID < 0)	{
            $teamNum++;
            next;
        }
        if ($team_nominations) {
            # Has nomination been processed and set to approved.
            my $nomination_status = CompNomination->check_for_nomination($Data, $compID, $teamID);

            if ($nomination_status == $Defs::TEAM_ENTRY_STATUS_PENDING) { # Nominations hasn't been processed.
                next;
            }
            elsif ($nomination_status == $Defs::TEAM_ENTRY_STATUS_REJECTED) { # Nomination rejected.
                next;
            }
            elsif (!$nomination_status) { # Team hasn't been nominated to the comp, so we should do so now.
                my $comp_nomination_obj = new CompNomination('db'=>$Data->{'db'}, 'assocID'=>$Data->{'clientValues'}{'assocID'});
                my %data = ('intCompID'=>$compID, intTeamID=>$teamID, intStatus=>1);
                $comp_nomination_obj->load(\%data);
                $comp_nomination_obj->write();
                next;
            }
        }
        

      if ($ExistingTeams{$teamID}) {
        $q_update_team->execute($teamNum, $compID, $teamID);
        $q_regrade_log->execute($Data->{'clientValues'}{'assocID'}, $teamID, $compID, 'Team Added', 0, 0) if ($ExistingTeams{$teamID} < 1);
        $ExistingTeams{$teamID} = 10;
      }
      else {
        $q_insert_team->execute($compID, $teamID, $teamNum);
        $ExistingTeams{$teamID} = 10;
        $q_regrade_log->execute($Data->{'clientValues'}{'assocID'}, $teamID, $compID, 'Team Added', 0, 0);
      }
      if ($Data->{'SystemConfig'}{'allowTeamIntoComp_MembersRollover'}) {
        $Data->{'memberListIntoComp'} = 1;
        $q_update_member_teams_status->execute($compID, $Data->{'clientValues'}{'teamID'});
        $q_update_member_teams_compID->execute($compID, $teamID);
        checkForMemberSeasonRecord($Data, $compID, $teamID, 0);
      }
      my $error='Database problem' if $DBI::err;
      my $result;
      if($error)  {
        $result = 'ERROR:';
        $result .= qq[
          <p>There was a problem attempting to assign this $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} to this $Data->{'LevelNames'}{$Defs::LEVEL_COMP}.</p>
          <div class="warningmsg">$error</div>
          <p>Please use your browser&#146;s back button and choose another  $Data->{'LevelNames'}{$Defs::LEVEL_COMP} or contact your $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC}.</p>
        ];
      }
      $teamNum++;
    }
    if ($multi) {
      my $st_delete_team = qq[
        UPDATE IGNORE 
          tblComp_Teams 
        SET 
          intRecStatus = $Defs::RECSTATUS_DELETED 
        WHERE 
          intCompID = ?
          AND intTeamID = ?
      ];
      my $q_delete_team = $dbh->prepare($st_delete_team) or query_error($st_delete_team);
      foreach my $teamID (keys %ExistingTeams) {
        next if $ExistingTeams{$teamID} == 10 or $ExistingTeams{$teamID} == -1;
        $q_delete_team->execute($compID, $teamID);
        $q_regrade_log->execute($Data->{'clientValues'}{'assocID'}, $teamID, $compID, 'Team Removed', 0, 0);
      }
    }
    if ($swol) {
      require LadderFactory;
      my $ladder = LadderFactory->create('Data'=>$Data,'CompetitionID' => $compID);
      $ladder->rebuild();
    }
    auditLog($compID, $Data, 'Assign to Comp', 'Team');
    return qq[ <p class="OKmsg">$Data->{'LevelNames'}{$Defs::LEVEL_TEAM}(s) in $Data->{'LevelNames'}{$Defs::LEVEL_COMP} successfully modified.</p>];
}


sub unassignComp {
  my ($Data, $teamID)=@_;
	my $comp_where = $Data->{'clientValues'}{'compID'} > 0 ? qq[ AND tblAssoc_Comp.intCompID = $Data->{'clientValues'}{'compID'}] : '';
	my $st =qq[
		SELECT intStarted, strTitle
		FROM tblAssoc_Comp 
			INNER JOIN tblComp_Teams ON tblAssoc_Comp.intCompID=tblComp_Teams.intCompID
		WHERE intAssocID=$Data->{'clientValues'}{'assocID'}
			AND intTeamID=$teamID
			AND tblComp_Teams.intRecStatus = $Defs::RECSTATUS_ACTIVE
			$comp_where
	];
	my $comps='';
	my $q=$Data->{'db'}->prepare($st);
	$q->execute();
	my($started, $compname)=$q->fetchrow_array();
	$started||=0;
  my $body=qq[
    <p>To remove this $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} from this $Data->{'LevelNames'}{$Defs::LEVEL_COMP} ($compname) press the 'Remove' button.</p>
	];

	if(!$started and !$Data->{'SystemConfig'}{'AssocConfig'}{'AlwaysAllowManageTeamsInComp'})	{
		my $unesc_cl=unescape(setClient($Data->{'clientValues'})) || '';
		$comps=qq[
			<form action="$Data->{'target'}" method="POST">
				<input type="hidden" name="a" value="T_CRU">
				<input type="hidden" name="client" value="$unesc_cl">
				<input type="submit" value="Remove">
			</form>
		];
	}
	else	{
		$comps=qq[<div class="warningmsg">The $Data->{'LevelNames'}{$Defs::LEVEL_COMP} has already started and cannot be modified.</div>];
	}
	$body.=$comps;
	my $title=qq[Remove $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} from a $Data->{'LevelNames'}{$Defs::LEVEL_COMP}];

  return ($body,$title);
}

# Modified version of UpdateremoveComp, called when changing team comp assignment via team details.
# Much requested feature for VCFL. Keep seperate for now!
sub removeTeamFromComp {
    my ($Data, $teamID,$compID)=@_;

    my $dbh = $Data->{db};
  
    $dbh->do("UPDATE IGNORE tblMember_Teams SET intCompID = 0 WHERE intCompID = $compID and intTeamID = $teamID");
   
    $dbh->do("UPDATE IGNORE tblMember_Teams SET intStatus = $Defs::RECSTATUS_DELETED WHERE intCompID = $compID AND intTeamID = $teamID");
    
    $dbh->do("UPDATE tblComp_Teams set intRecStatus=$Defs::RECSTATUS_DELETED, intTeamNum = 0 WHERE intCompID = $compID AND intTeamID = $teamID");
    
    require LadderFactory;
    my $ladder = LadderFactory->create('Data'=>$Data,'CompetitionID' => $compID);
    $ladder->rebuild();
    
    my $error='Database problem' if $DBI::err;

	my $body='';
	if($error)	{
		$body=qq[
			<p>There was a problem attempting to remove this $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} from this $Data->{'LevelNames'}{$Defs::LEVEL_COMP}.</p>
			<div class="warningmsg">$error</div>
		];
	}
	else	{
		$body=qq[ <p class="OKmsg">The $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} has been successfuly removed from this $Data->{'LevelNames'}{$Defs::LEVEL_COMP}.</p>];
	}
	my $title=qq[Remove $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} from a $Data->{'LevelNames'}{$Defs::LEVEL_COMP}];

  return ($body,$title);
}


sub UpdateremoveComp {
    my ($Data, $teamID,$compID)=@_;
    
   	my $st=qq[UPDATE IGNORE tblMember_Teams SET intCompID = 0 WHERE intCompID = $Data->{'clientValues'}{'compID'} and intTeamID = $Data->{'clientValues'}{'teamID'}];
	$Data->{'db'}->do($st);
	
    $st=qq[UPDATE IGNORE tblMember_Teams SET intStatus = $Defs::RECSTATUS_DELETED WHERE intCompID = $Data->{'clientValues'}{'compID'} and intTeamID = $Data->{'clientValues'}{'teamID'}];
	$Data->{'db'}->do($st);
	
    $st=qq[UPDATE tblComp_Teams set intRecStatus=$Defs::RECSTATUS_DELETED, intTeamNum = 0 WHERE intCompID=$Data->{'clientValues'}{'compID'} AND intTeamID=$Data->{'clientValues'}{'teamID'}];
    $Data->{'db'}->do($st);
  
    require LadderFactory;
    my $ladder = LadderFactory->create('Data'=>$Data,'CompetitionID' => $compID);
    $ladder->rebuild();
    
	my $error='Database problem' if $DBI::err;

	my $body='';
	if($error)	{
		$body=qq[
			<p>There was a problem attempting to remove this $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} from this $Data->{'LevelNames'}{$Defs::LEVEL_COMP}.</p>
			<div class="warningmsg">$error</div>
		];
	}
	else	{
		$body=qq[ <p class="OKmsg">The $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} has been successfuly removed from this $Data->{'LevelNames'}{$Defs::LEVEL_COMP}.</p>];
	}
	my $title=qq[Remove $Data->{'LevelNames'}{$Defs::LEVEL_TEAM} from a $Data->{'LevelNames'}{$Defs::LEVEL_COMP}];

  return ($body,$title);
}




sub getSelectedTeams {
    my ($Data, $Teams) = @_;
 
    my @TeamData = ();
    
		my %teams = ();
    if (scalar (@{$Teams})) {
        my $teams = join(',', @{$Teams});
        my $dbh = $Data->{db};
        
        my $query = qq[
                   SELECT tblTeam.* FROM tblTeam
                   WHERE tblTeam.intTeamID IN ($teams) 
                   ];
        
        my $sth = $dbh->prepare($query);
        $sth->execute();
        
        while (my $dref = $sth->fetchrow_hashref()) {
            my %team = ();
            foreach my $field( keys %{$dref}) {
                $team{$field} = $dref->{$field};
            }
						$teams{$dref->{'intTeamID'}} = \%team;
        }
				for my $id (@{$Teams})	{
					push @TeamData, $teams{$id};
				}
    }
    
    return \@TeamData;
}

sub getTeamHistory {
    my ($dbh,$team, $only_name) = @_;
    
    $only_name ||= 0;

    my $query = qq[SELECT strAgeGroupDesc, strSeasonName
                   FROM tblComp_Teams 
                   INNER JOIN tblAssoc_Comp USING (intCompID)
                   INNER JOIN tblAgeGroups ON (tblAgeGroups.intAgeGroupID = tblAssoc_Comp.intAgeGroupID)
                   INNER JOIN tblSeasons ON (tblSeasons.intSeasonID = tblAssoc_Comp.intNewSeasonID)
                   WHERE intTeamID = ?
                   AND tblComp_Teams.intRecStatus != $Defs::RECSTATUS_DELETED
                   ORDER BY tblAssoc_Comp.intSeasonID DESC LIMIT 3];
    
    my $sth = $dbh->prepare($query);
    
    $sth->execute($team->{intTeamID});
    my $team_history = '';
    
    while (my ($age_group, $season) = $sth->fetchrow_array()) {
        $team_history .= ',' if $team_history;
        $team_history .= qq[$age_group $season];
    }
    my $team_name = $team->{strName};
    $team_name .= " ($team_history)" if $team_history and ! $only_name;
 
    return $team_name;
}

sub delete_team {
    my ($Data,$client) = @_;
    
    my $teamID = param('teamID');
    
    my $assocID = $Data->{clientValues}{assocID};
    my $dbh = $Data->{db};

    my $teamObj = new TeamObj(db=>$dbh,ID=>$teamID, assocID=>$assocID);
    my $result = $teamObj->delete();
   
    my $resultHTML = '';
    if ($result && $result !~/^ERROR/) {
        $resultHTML = qq[<p class="OKmsg">Successfully removed $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}</p>];
        auditLog($teamID, $Data, 'Delete Team', 'Team');
    }
    else {
        $resultHTML = qq[<p class="warningmsg">Unable to delete this $Data->{'LevelNames'}{$Defs::LEVEL_TEAM}.</p>];
    }
    
    return $resultHTML;
}

sub  getTeamClubID  {

    my ($db, $teamID) = @_;
      
    $teamID ||= 0;
    my $st = qq[
        SELECT
            intClubID
        FROM
            tblTeam
        WHERE intTeamID = ?
    ];
    my $qry = $db->prepare($st);
    $qry->execute($teamID);
    my $clubID = $qry->fetchrow_array() || 0;

    $clubID= 0 if (! $clubID or $clubID == $Defs::INVALID_ID);
    return $clubID;

}

sub assignStaff	{

	my ($Data, $teamID) = @_;

	my $assocID = $Data->{'clientValues'}{'assocID'} || 0;
	my $compID = $Data->{'clientValues'}{'compID'} || 0;
	my $clubID = $Data->{'clientValues'}{'clubID'} || 0;
	$clubID = 0 if ($clubID == $Defs::INVALID_ID);
	if (! $clubID or $clubID == $Defs::INVALID_ID)	{
		$clubID = getTeamClubID($Data->{'db'}, $teamID);
	}
	my $realmID = $Data->{'Realm'} || 0;


my $st= qq[
      SELECT
        AssocStaff.intAssocStaffID,
        strStaffDesc,
        intTeamID,
        strGroup,
        TeamStaff.intMemberID,
        intTeamStaffID,
        M.strNationalNum
      FROM
        tblResults_AssocStaff as AssocStaff
        LEFT JOIN tblTeam_Staff as TeamStaff ON (
          AssocStaff.intAssocStaffID=TeamStaff.intAssocStaffID
          AND TeamStaff.intTeamID=?
          AND TeamStaff.intCompID = ?
        )
        LEFT JOIN tblMember as M ON (
          M.intMemberID = TeamStaff.intMemberID
        )
      WHERE
        AssocStaff.intRealmID = ?
        AND AssocStaff.intAssocID IN(0, ?)
      ORDER by strGroup ASC, intOrder ASC
  ];
  my $query = $Data->{'db'}->prepare($st);
  $query->execute($teamID, $compID, $realmID, $assocID);
  my $lastgroup='';

  my $staff_members = _getClubStaffMembers($Data, $clubID, $teamID);

  my @TeamStaff=();

  while(my $dref= $query->fetchrow_hashref()) {
    my %Official=();
    $Official{'StaffID'}=$dref->{'intAssocStaffID'} || next;
    $Official{'Group'}=$dref->{'strGroup'} || '';
    $Official{'staffDesc'}=$dref->{'strStaffDesc'} || '';
    $Official{'nationalNumber'}=$dref->{'strNationalNum'} || '';

    my $SELECTED = (! $dref->{intMemberID}) ? 'SELECTED' : '';
    my $select_name = "teamstaffID_$dref->{intAssocStaffID}";
    my $selectmember = qq[
      <select name="$select_name" class = "chzn-select">
      <option $SELECTED value="0">--Select Club official--</option>
      <option value="0">(no official)</option>
    ];
    foreach my $member  (@{$staff_members}) {
      my $memberID = $member->[0] || next;
      my $name= $member->[2] || next;
      my $SELECTED = ($memberID and $dref->{intMemberID} and $memberID == $dref->{intMemberID}) ? 'SELECTED' : '';
      $selectmember .= qq[<option $SELECTED value="$memberID">$name</option>];
    }
    $selectmember .= qq[</select>];

    $Official{'staffSelectBox'}=$selectmember;
    push @TeamStaff, \%Official;
  }
	my %TemplateData=();
	$TemplateData{'data_TeamStaff'} = \@TeamStaff;
	my $cl  = setClient($Data->{'clientValues'});
	my $unesc_cl=unescape($cl);
	$TemplateData{'client'} = $unesc_cl;

	my $body = runTemplate( $Data, \%TemplateData, "team/team_staff.templ");
  return ($body, 'Team Staff');
}

sub _getClubStaffMembers  {


  my ($Data, $clubID, $teamID) = @_;

	my $assocID = $Data->{'clientValues'}{'assocID'} || 0;
	my $compID = $Data->{'clientValues'}{'compID'} || 0;
	$clubID = 0 if ($clubID == $Defs::INVALID_ID);
	my $seasonID=0;

 if ($compID and $compID != $Defs::INVALID_ID) {
		my $st_comp = qq[
			SELECT 
				intNewSeasonID
			FROM 
				tblAssoc_Comp
			WHERE 
				intCompID = ?
				AND intAssocID = ?
		];
		my $qry_compSeason= $Data->{'db'}->prepare($st_comp);
		$qry_compSeason->execute($compID, $assocID);
		$seasonID = $qry_compSeason->fetchrow_array() || 0;
	}

  my $MStablename = "tblMember_Seasons_$Data->{'Realm'}";
  my $st = qq[
      SELECT DISTINCT
        M.intMemberID,
        M.strNationalNum,
        CONCAT(strSurname, ', ', strFirstname) as Name
      FROM
        tblMember as M
        INNER JOIN tblMember_Associations as MA ON (MA.intMemberID = M.intMemberID)
        INNER JOIN tblMember_Clubs as MC ON (MC.intMemberID = M.intMemberID)
        INNER JOIN $MStablename as MS ON (
          MS.intMemberID = M.intMemberID
          AND MS.intMSRecStatus=1
          AND MS.intAssocID = MA.intAssocID
          AND MS.intClubID=MC.intClubID
          AND MS.intSeasonID = $seasonID
        )
      WHERE 
				MC.intStatus=1
  			AND (MS.intCoachStatus =1 OR M.intOfficial=1)
        AND MC.intClubID = $clubID
        AND MA.intRecStatus = 1
        AND MA.intAssocID = $assocID
       ORDER BY 
					strSurname, 
					strFirstname
    ];
    my $qry = $Data->{'db'}->prepare($st);
    $qry->execute;
    my @Staff_Members = ();

    while (my $dref=$qry->fetchrow_hashref()) {
      push @Staff_Members, [$dref->{'intMemberID'}, $dref->{'strNationalNum'}, $dref->{'Name'}];
    }

    return \@Staff_Members;
}

sub saveStaff	{

	my ($Data, $teamID) = @_;

  my $assocID = $Data->{'clientValues'}{'assocID'} || 0;
  my $compID = $Data->{'clientValues'}{'compID'} || 0;
  my $realmID = $Data->{'Realm'} || 0;

	my $q=new CGI;
	my %params=$q->Vars();


	my $st_del = qq[
		DELETE FROM
			tblTeam_Staff
		WHERE
			intAssocID = ?
			AND intCompID = ?
			AND intTeamID = ?
	];
  my $qry_del = $Data->{'db'}->prepare($st_del);
  $qry_del->execute($assocID, $compID, $teamID);

	my $st = qq[
		SELECT
    	intAssocStaffID
    FROM
      tblResults_AssocStaff
    WHERE
      intRealmID = ?
      AND intAssocID IN(0, ?)
  ];

  my $qry= $Data->{'db'}->prepare($st);
  $qry->execute($realmID, $assocID);

	my $st_ins = qq[
		INSERT INTO tblTeam_Staff
		(intAssocStaffID, intAssocID, intCompID, intTeamID, intMemberID)
		VALUES (?,?,?,?,?)
	];
  my $qry_ins= $Data->{'db'}->prepare($st_ins);

	while (my $dref = $qry->fetchrow_hashref())	{
		my $key = "teamstaffID_$dref->{'intAssocStaffID'}";
		my $memberID = $params{$key} || next;
  	$qry_ins->execute($dref->{'intAssocStaffID'}, $assocID, $compID, $teamID, $memberID);
	}
	return qq[<div class="OKmsg">$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} Staff updated successfully</div>];
}

sub loadTeamsSelect	{

	my ($Data, $client, $fromCompID) = @_;
	$fromCompID ||= 0;

	return qq[<div class="warningmsg">You must select a $Data->{'LevelNames'}{$Defs::LEVEL_COMP}</div>] if (! $fromCompID);

	my $fromComp_obj= getInstanceOf($Data, 'comp', $fromCompID);
	my $toComp_obj= getInstanceOf($Data, 'comp', $Data->{'clientValues'}{'compID'});

	my $st = qq[
		SELECT
			DISTINCT
			CT.intTeamID,
			T.strName as TeamName,
			C.strName as ClubName
		FROM
			tblComp_Teams as CT
			INNER JOIN tblAssoc_Comp as Comp ON (Comp.intCompID=CT.intCompID)
			INNER JOIN tblTeam as T ON (T.intTeamID=CT.intTeamID)
			LEFT JOIN tblComp_Teams as CT_Already ON (
				CT_Already.intTeamID=CT.intTeamID
				AND CT_Already.intCompID=?
			)
			LEFT JOIN tblClub as C ON (C.intClubID=T.intClubID)
		WHERE
			CT.intCompID=?
			AND Comp.intAssocID=?
			AND CT.intRecStatus=1
			AND CT_Already.intCompID IS NULL
	];
  my $qry= $Data->{'db'}->prepare($st);
  $qry->execute(
		$Data->{'clientValues'}{'compID'},
		$fromCompID, 
		$Data->{'clientValues'}{'assocID'}
	);

	my $teams=qq[
		<table class="listTable">
			<tr>
				<th>Load</th>
				<th>$Data->{'LevelNames'}{$Defs::LEVEL_TEAM}</th>
				<th>$Data->{'LevelNames'}{$Defs::LEVEL_CLUB}</th>
			</tr>
	];
	my $count=0;
	while (my $dref=$qry->fetchrow_hashref())	{
		$dref->{'TeamName'} || next;
		$dref->{'ClubName'} ||= '';
		$teams .= qq[
			<tr>
				<td><input type="checkbox" name="team_$dref->{'intTeamID'}" value="1"></td>
				<td>$dref->{'TeamName'}</td>
				<td>$dref->{'ClubName'}</td>
			</tr>
		];
		$count++;
	}
	$teams .= qq[</table>];

	my $members = qq[
      <div>Bring $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER."_P"} across with $Data->{'LevelNames'}{$Defs::LEVEL_TEAM."_P"} ? <input type="checkbox" name="bringMembers" value="1"></div>
			<p>&nbsp;</p>
	];
	$members = '' if (! $Data->{'SystemConfig'}{'AssocConfig'}{'loadTeams_allowMembersCopy'} and ! $Data->{'SystemConfig'}{'loadTeams_allowMembersCopy'});
	if (! $count)	{
		$teams = qq[<div class="warningmsg">No $Data->{'LevelNames'}{$Defs::LEVEL_TEAM."_P"} exist for this $Data->{'LevelNames'}{$Defs::LEVEL_COMP}</div>] if (! $count);
		$members='';
	}
	my $body = qq[
		<div class="sectionheader">Load $Data->{'LevelNames'}{$Defs::LEVEL_TEAM."_P"} into $Data->{'LevelNames'}{$Defs::LEVEL_COMP}</div>
 		<form action="$Data->{'target'}" method="post" name="selectTeams">
				<div>Please select which $Data->{'LevelNames'}{$Defs::LEVEL_TEAM."_P"} from ] . $fromComp_obj->getValue('strTitle') . qq[ you wish to load into the current $Data->{'LevelNames'}{$Defs::LEVEL_COMP} (]. $toComp_obj->getValue('strTitle') . qq[)</div>
				$teams
			<input type="hidden" name="fromCompID" value="$fromCompID">
			<input type="hidden" name="a" value="T_LOADSUBMIT">
      <input type="hidden" name="client" value="$client">
			<p>&nbsp;</p>
				$members
			<input type="submit" value="Load $Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'}" name="submitbutton" class="button proceed-button">
 		</form>
	];

	return $body;
}

sub loadTeamsSubmit	{

	my ($Data, $client, $fromCompID) = @_;
	$fromCompID ||= 0;

	return qq[<div class="warningmsg">You must select a $Data->{'LevelNames'}{$Defs::LEVEL_COMP}</div>] if (! $fromCompID);

	my $q=new CGI;
	my %params=$q->Vars();
	my $bringMembers = $params{'bringMembers'} || 0;

	my $body = '';

	my $stTeams = qq[
		SELECT
			CT.intTeamID,
			CT.intTeamNum
		FROM
			tblComp_Teams as CT
			INNER JOIN tblAssoc_Comp as Comp ON (Comp.intCompID=CT.intCompID)
		WHERE
			CT.intCompID=?
			AND Comp.intAssocID=?
			AND CT.intRecStatus=1
	];
  my $qryTeams= $Data->{'db'}->prepare($stTeams);
  $qryTeams->execute($fromCompID, $Data->{'clientValues'}{'assocID'});

	my $stInsTeams = qq[
		INSERT IGNORE INTO tblComp_Teams
		(intCompID, intTeamID, intRecStatus, intTeamNum)
		VALUES (?,?,1,?)
	];
  my $qryInsTeams= $Data->{'db'}->prepare($stInsTeams);

	my $stInsMembers= qq[
		INSERT IGNORE INTO tblMember_Teams
			(intMemberID, intTeamID, intStatus, intCompID)
		SELECT DISTINCT 
			intMemberID, intTeamID, 1, ?
		FROM 
			tblMember_Teams
		WHERE
			intCompID=?
			AND intTeamID=?
	];
  my $qryInsMembers= $Data->{'db'}->prepare($stInsMembers);

	my $count=0;
	while (my $dref=$qryTeams->fetchrow_hashref())	{
		my $key = "team_$dref->{'intTeamID'}";
		next unless ($params{$key} == 1);
  	$qryInsTeams->execute($Data->{'clientValues'}{'compID'}, $dref->{'intTeamID'}, $dref->{'intTeamNum'});
  	$qryInsMembers->execute($Data->{'clientValues'}{'compID'}, $fromCompID, $dref->{'intTeamID'}) if ($bringMembers);
		$count++;
	}
	
	my $members = $bringMembers ? " (and $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER.'_P'})" : '';
	my $team = $count>1 ? $Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'} : $Data->{'LevelNames'}{$Defs::LEVEL_TEAM};

	my $toComp_obj= getInstanceOf($Data, 'comp', $Data->{'clientValues'}{'compID'});
	my $msg = qq[<div class="OKmsg">$count $team$members have been loaded into the $Data->{'LevelNames'}{$Defs::LEVEL_COMP} (] . $toComp_obj->getValue('strTitle') .qq[)</div>];

	return $msg;
}

sub assignPlayersToTeam_v2 {
    my ($Data, $teamID, $client) = @_;

    my $db = $Data->{'db'};
    my $q=new CGI;
    my %params=$q->Vars();

    return ('', "Error") if $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_CLUB;

    my $intAssocID = getAssocID($Data->{'clientValues'}) || 0;
    my $intCompID = $Data->{'clientValues'}{'compID'} || 0;
    
    # Find the club
    my $stt=qq[
        SELECT strName, intClubID
        FROM tblTeam
        WHERE intTeamID = ?
        LIMIT 1
    ];
    my $query = $db->prepare($stt);
    $query->execute($teamID);
    my($teamname, $DBteamClub) = $query->fetchrow_array();
    
    my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
    my $current_season = $assocSeasons->{'currentSeasonID'};
    my $seasons;
    my $age_groups;
    my $age_restrictions;
    my $current_gender;
    my $comp_name;
    my $season_name;
    
    if ($assocSeasons->{'allowSeasons'})    {
        ($seasons, undef) = Seasons::getSeasons($Data, 1);
        $Data->{'AllAgeGroups'} = 1;
        $Data->{'BlankAgeGroup'} = 1;
        ($age_groups, undef) = AgeGroups::getAgeGroups($Data);
    }
    
    my $js = qq[jQuery(".dateinput").datepicker({ dateFormat: 'dd/mm/yy', autoSize: true, constrainInput: true});];
    $Data->{'AddToPage'}->add('js_bottom','inline',$js);
    $Data->{'AddToPage'}->add('css','file','results/css/style.css');
    if ( $intCompID>0 ) {
        # get comp obj
        my $comp_obj = new CompObj( 'db'=>$db, 'ID'=>$intCompID, 'assocID'=>$intAssocID );
        $comp_obj->load();
        
        $age_restrictions = $comp_obj->get_dob_restrictions();
        
        $current_gender = $comp_obj->{'DBData'}->{'intCompGender'} || 0;
        
        # Comp title and season name.
        my $comp_details_sql = qq[
            SELECT strTitle,
                   strSeasonName
            FROM tblAssoc_Comp
            INNER JOIN tblSeasons ON tblSeasons.intSeasonID = tblAssoc_Comp.intNewSeasonID
            WHERE intCompID = $intCompID LIMIT 1
        ];
        my $comp_details_stmt = $db->prepare($comp_details_sql);
        $comp_details_stmt->execute();
        ($comp_name, $season_name) =  $comp_details_stmt->fetchrow_array();
    }
   $intCompID = 0 if($intCompID<0); 
    my %availableComps =();
    if (!$intCompID){
         my $st = qq[
            SELECT CT.intCompID, AC.strTitle
            FROM tblComp_Teams as CT
                    INNER JOIN tblAssoc_Comp as AC ON (AC.intCompID = CT.intCompID)
                    INNER JOIN tblSeasons on tblSeasons.intSeasonID = AC.intNewSeasonID
            WHERE CT.intTeamID=$teamID
                AND CT.intRecStatus = $Defs::RECSTATUS_ACTIVE
                AND AC.intRecStatus = $Defs::RECSTATUS_ACTIVE
        ];
        my $qry_comps = $db->prepare($st);
        $qry_comps->execute or query_error($st);
        while(my ($DB_intCompID, $DB_compName) = $qry_comps->fetchrow_array()){
            $availableComps{$DB_intCompID} = $DB_compName;
        }
    }
    my %TemplateData = (
        'client' => $client,
        'assocID' => $intAssocID,
        'teamID' => $teamID,
        'compID' => $intCompID,
        'team_name' => $teamname, 
        'comp_name' => $comp_name,
        'season_name' => $season_name,
#        'age_groups' => {
#            'list' => $age_groups,
#            'current' => '', #TODO: find current age group of comp?
#            'text' => $Data->{'SystemConfig'}{'txtAgeGroup'} || 'Age Group',
#        },
        'seasons' => {
            'list' => $seasons,
            'current' => $current_season,
            'text' => $Data->{'SystemConfig'}{'txtSeason'} || 'Season',
        },
        'genders' => {
            'list' => \%Defs::genderInfo,
            'current' => $current_gender,
            'text' => 'Gender',
        },
        'lock_dob_if_set'    => $Data->{'SystemConfig'}{'AssocConfig'}{'LockdownDOBIfSetOnTeamEdit'} || 0,
        'lock_gender_if_set' => $Data->{'SystemConfig'}{'AssocConfig'}{'LockdownGenderIfSetOnTeamEdit'} || 0,
        
        'availableComps'    =>{ 
                'list'  =>  \%availableComps,
                'current' => 0,
                }
    );
    
    if ($age_restrictions){
        foreach my $date_field ( 'dtMaxDOB', 'dtMinDOB' ) {
            next if (!defined $age_restrictions->{$date_field});
            next if ($age_restrictions->{$date_field} !~ /^\d{4}-\d{2}-\d{2}$/);
            
            # next to convert format
            my ($year, $month, $day) = split ('-', $age_restrictions->{$date_field});
            
            # Save to template
            $TemplateData{$date_field} = join ( '/', ($day, $month, $year));
        }  
    }

    my $body = runTemplate( $Data, \%TemplateData, "team/teamedit.templ");
    return ($body, "Modify $teamname Member List");
}


1;

