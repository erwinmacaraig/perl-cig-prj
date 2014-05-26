#
# $Header: svn://svn/SWM/trunk/web/Tribunal.pm 9406 2013-09-02 04:07:37Z mstarcevic $
#

package Tribunal;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleTribunal);
@EXPORT_OK=qw(handleTribunal);

use strict;
use Reg_common;
use HTMLForm;
use AuditLog;
use FormHelpers;
use CGI qw(param unescape escape);
use DefCodes;


sub handleTribunal	{
	my ($action, $Data, $tribunalID)=@_;

	$tribunalID ||= 0;
	my $resultHTML='';
	my $title='';
	$tribunalID=param('tID') || 0;
	if ($action =~/^TB_DT/) {
		($resultHTML,$title)=tribunal_details($action, $Data, $tribunalID);
	}
	if ($action =~/^TB_DEL/) {
		($resultHTML,$title)=deleteTribunal($Data, $tribunalID);
	}

	return ($resultHTML,$title);
}

sub deleteTribunal	{
	my ($Data, $tribunalID) = @_;
  my $txt_Tribunal= $Data->{'SystemConfig'}{'txtTribunal'} || 'Tribunal'; 
	my $st = qq[
		DELETE FROM
			tblTribunal
		WHERE
			intAssocID= $Data->{'clientValues'}{'assocID'}
			AND intTribunalID = $tribunalID
		LIMIT 1
	];
	$Data->{'db'}->do($st);
  my $log = new AuditLogObj(db => $Data->{'db'});
  $log->log(
    id => $tribunalID,
    username => $Data->{'clientValues'}{'userName'},
    type => 'Delete',
    section => 'Tribunal',
    login_entity_type => $Data->{'clientValues'}{'authLevel'},
    login_entity => $Data->{'clientValues'}{'_intID'},
    entity_type => $Data->{'clientValues'}{'currentLevel'},
    entity => getID($Data->{'clientValues'}) || 0
  );
  return (qq[<div class="OKmsg">You have successfully deleted this $txt_Tribunal record</div>],"$txt_Tribunal record deleted");	
			
}
sub tribunal_details	{
	my ($action, $Data, $tribunalID)=@_;

	my $option='display';
	$option='edit' if $action eq 'TB_DTE' and allowedAction($Data, 'tb_e');
	$option='add' if $action eq 'TB_DTA' and allowedAction($Data, 'tb_a');
	$tribunalID=0 if $option eq 'add';
	my $field=loadTribunalDetails($Data->{'db'}, $tribunalID,$Data->{'clientValues'}{'assocID'}) || ();
  	my $client=setClient($Data->{'clientValues'}) || '';

	my $clubID = $Data->{clientValues}{clubID} ||= 0;
	$clubID = 0 if ($clubID == $Defs::INVALID_ID);
	my $compID = $Data->{clientValues}{compID} ||= 0;
	$compID = 0 if ($compID== $Defs::INVALID_ID);
	my $teamID = $Data->{clientValues}{teamID} ||= 0;
	$teamID = 0 if ($teamID== $Defs::INVALID_ID);

	if (! $clubID)	{
		my $st=qq[
        	        SELECT intClubID
        	        FROM tblTeam
        	        WHERE intTeamID=$teamID
        	];
	        my $query = $Data->{'db'}->prepare($st);
	        $query->execute;
        	$clubID = $query->fetchrow_array() || 0;
	}

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'} || $field->{'intAssocTypeID'},
        assocID    => $Data->{'clientValues'}{'assocID'},
    );

	my %TeamComps=();
  	{
        	my $aID= $Data->{'clientValues'}{'assocID'} || -1;
    		my $statement = qq[
        		SELECT 	
				intMemberTeamID, 
				CONCAT(S.strSeasonName , "- ", T.strName, " ", AC.strTitle) as Name
      			FROM tblMember_Teams as MT
				INNER JOIN tblTeam as T ON (T.intTeamID = MT.intTeamID and T.intAssocID= $aID)
				LEFT JOIN tblAssoc_Comp as AC ON (AC.intCompID = MT.intCompID)
				LEFT JOIN tblSeasons as S ON (S.intSeasonID = AC.intNewSeasonID)
      			WHERE MT.intMemberID = $Data->{'clientValues'}{'memberID'}
				AND MT.intStatus <> -1
				AND T.intRecStatus <> -1
				AND AC.intStatus <> -1
    		];
    		my $query = $Data->{'db'}->prepare($statement);
                $query->execute;
    		while (my($intID, $Name) = $query->fetchrow_array) {
      			$TeamComps{$intID}=$Name || '';
    		}
  	}

my %Comps=();
    {
          my $aID= $Data->{'clientValues'}{'assocID'} || -1;
        my $statement = qq[
            SELECT
              AC.intCompID,
              AC.strTitle
            FROM
              tblAssoc_Comp as AC
              INNER JOIN tblAssoc as A ON (A.intAssocID=AC.intAssocID)
            WHERE AC.intAssocID=?
              AND AC.intNewSeasonID=A.intCurrentSeasonID
              AND AC.intRecStatus =1
        ];
        my $query = $Data->{'db'}->prepare($statement);
        $query->execute($aID);
        while (my($intID, $Name) = $query->fetchrow_array) {
            $Comps{$intID}=$Name || '';
        }
    }



	my %TeamCompMatch=();
  	{
        	my $aID= $Data->{'clientValues'}{'assocID'} || -1;
    		my $statement = qq[
        		SELECT 
				intMatchID, 
				DATE_FORMAT(dtMatchTime, "%d/%m/%y") as dtMatchTime, 
				T1.strName as HomeTeam, 
				intHomeTeamID, 
				T2.strName as AwayTeam, 
				intAwayTeamID
      			FROM 
				tblCompMatches as M 
				INNER JOIN tblTeam as T1 ON (T1.intTeamID = M.intHomeTeamID)
				INNER JOIN tblTeam as T2 ON (T1.intTeamID = M.intAwayTeamID)
      			WHERE 
				M.intAssocID = $aID
				AND M.intCompID = $compID
				AND (intHomeTeamID = $teamID 
					OR intAwayTeamID = $teamID
				)
			ORDER BY 
				dtMatchTime DESC
			LIMIT 5
    		];
    		my $query = $Data->{'db'}->prepare($statement);
                $query->execute;
    		while (my($intID, $MatchTime, $HomeTeam, $intHomeTeamID, $AwayTeam, $intAwayTeamID) = $query->fetchrow_array) {
			my $versusTeam = qq[$HomeTeam];
			$versusTeam = qq[$AwayTeam] if ($intHomeTeamID == $teamID);
      			$TeamCompMatch{$intID}=qq[$MatchTime - $versusTeam];
    		}
  	}
	my $st_ageGroups =qq[ SELECT intAgeGroupID, strAgeGroupDesc FROM tblAgeGroups WHERE intRealmID = $Data->{'Realm'} and (intAssocID=$Data->{'clientValues'}{'assocID'} or intAssocID=0) and (intRealmSubTypeID = $Data->{'RealmSubType'} OR intRealmSubTypeID = 0)  AND intRecStatus = $Defs::RECSTATUS_ACTIVE ];
        my ($ageGroups_vals,$ageGroups_order)=getDBdrop_down_Ref($Data->{'db'},$st_ageGroups,'');

    my $txt_Tribunal= $Data->{'SystemConfig'}{'txtTribunal'} || 'Tribunal';
    #$field->{intPenalty}= sprintf("%02s", $field->{intPenalty});

	my %FieldDefinitions=(
		fields=>	{
			intRecStatus => {				## ADDED TC 31/10/06
        			label => $Data->{'SystemConfig'}{'AllowStatusChange'} ? 'Active?' : '',
				value => $field->{'intRecStatus'},
				type => 'checkbox',
				default => 1,
				displaylookup => {1=>'Yes', 0=>'No'},
				noadd =>1,
				sectionname => 'clubdetails',
			},
			dtCharged => {
                                label => 'Charge Date',
                                value => $field->{dtCharged},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'details',
				compulsory=>1,
                                validate => 'DATE',
                        },
			intMatchID=> {
                                label => ($compID and $teamID and ! $tribunalID)  ? "Match" : '',
				addonly=>1,
                                type  => 'lookup',
                                options => \%TeamCompMatch,
                                sectionname => 'comp',
                                firstoption => [''," "],
                        },
			intMemberTeamID=> {
                                label => "$Data->{'LevelNames'}{$Defs::LEVEL_TEAM}/$Data->{'LevelNames'}{$Defs::LEVEL_COMP} of $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}", 
				readonly => ($option eq 'add' and (! $compID or ! $teamID))  ? 0 : 1,
                                type  => 'lookup',
                                options => \%TeamComps,
                                sectionname => 'comp',
                                SkipAddProcessing => 1,
                                firstoption => [''," "],
                        },
		intCompAddID=> {
                                label => "OR select a current $Data->{'LevelNames'}{$Defs::LEVEL_COMP}",
        readonly => ($option eq 'add' and (! $compID or ! $teamID))  ? 0 : 1,
                                type  => 'lookup',
                                options => \%Comps,
                                sectionname => 'comp',
                                firstoption => [''," "],
                                SkipAddProcessing => 1,
                        },

			intTribunalAgeGroupID=> { 
        	                label => "Grade",
	                        value => $field->{intTribunalAgeGroupID},
                            	type  => 'lookup',
                            	options => $ageGroups_vals,
                            	firstoption => ['',"Choose Grade"],
                                compulsory => 1,
                            	sectionname => 'comp',
                                 },
                     
			intClubID=> {
                                label => $tribunalID ? "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB}" : '',
                                value => $field->{ClubName},
                                sectionname => 'comp',
				readonly =>1,
                        },
			intTeamID => {
                                label => $tribunalID ? "$Data->{'LevelNames'}{$Defs::LEVEL_TEAM}" : '',
                                value => $field->{TeamName},
                                sectionname => 'comp',
				readonly =>1,
                        },
			intCompID => {
                                label => $tribunalID ? "$Data->{'LevelNames'}{$Defs::LEVEL_COMP}" : '',
                                value => $field->{CompTitle},
                                sectionname => 'comp',
				readonly =>1,
                        },
			intChargeID=> {
                                label => 'Charge/Offence',
                                value => $field->{intChargeID},
                                type  => 'lookup',
                                options => $DefCodes->{-13},
                                order => $DefCodesOrder->{-13},
                                firstoption => [''," "],
				compulsory=>1,
                                sectionname => 'details',
                        },
			intCharge2ID=> {
                                label => 'Charge/Offence 2',
                                value => $field->{intCharge2ID},
                                type  => 'lookup',
                                options => $DefCodes->{-13},
                                order => $DefCodesOrder->{-13},
                                firstoption => [''," "],
                                sectionname => 'details',
                        },
			intCharge3ID=> {
                                label => 'Charge/Offence 3',
                                value => $field->{intCharge3ID},
                                type  => 'lookup',
                                options => $DefCodes->{-13},
                                order => $DefCodesOrder->{-13},
                                firstoption => [''," "],
                                sectionname => 'details',
                        },
			strOffence=> {
        			label => 'Charge/Offence (Other)',
                                value => $field->{strOffence},
                                type  => 'text',
                                size  => '20',
                                maxsize => '50',
                                sectionname => 'details',
                        },
			strChargeGrading=> {
        			label => 'Charge Grading',
                                value => $field->{strChargeGrading},
                                type  => 'text',
                                size  => '20',
                                maxsize => '50',
                                sectionname => 'details',
                        },
			strOutcome=> {
                                label => 'Outcome',
                                value => $field->{strOutcome},
                                type  => 'lookup',
                                options => $DefCodes->{-94},
                                order => $DefCodesOrder->{-94},
                                firstoption => [''," "],
                                sectionname => 'outcome',
                        },
			strWitness=> {
        			label => 'Witness',
                                value => $field->{strWitness},
                                type  => 'text',
                                size  => '20',
                                maxsize => '50',
                                sectionname => 'details',
                        },
			strReporter=> {
        			label => 'Reporter',
                                value => $field->{strReporter},
                                type  => 'text',
                                size  => '20',
                                maxsize => '50',
				compulsory=>1,
                                sectionname => 'details',
                        },
			dtHearing=> {
                                label => 'Hearing Date',
                                value => $field->{dtHearing},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'hearing',
                                validate => 'DATE',
                        },
			tHearing=> {
                                label => 'Hearing Time',
                                value => $field->{tHearing},
                                type  => 'time',
                                format => 'hh:mm',
                                sectionname => 'hearing',
                                validate => 'TIME',
                        },
			intHearingVenueID=> {
                                label => 'Hearing Venue',
                                value => $field->{intHearingVenueID},
                                type  => 'lookup',
                                options => $DefCodes->{-95},
                                order => $DefCodesOrder->{-95},
                                firstoption => [''," "],
                                sectionname => 'hearing',
                        },
			dtPenaltyStartDate=> {
                                label => 'Penalty Start Date',
                                value => $field->{dtPenaltyStartDate},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'outcome',
                                validate => 'DATE',
                        },
			intPenalty=> {
                                label => 'Penalty (Units)',
                                value => $field->{intPenalty},
                                type  => 'text',
                                size  => '15',
                                maxsize => '15',
                                validate => 'FLOAT',
                                sectionname => 'outcome',
                        },
			strPenaltyType=> {
        			label => 'Penalty (Type)',
                                value => $field->{strPenaltyType},
                                type  => 'lookup',
                                options => \%Defs::TribunalTypes,
                                firstoption => [''," "],
                                sectionname => 'outcome',
                        },
			intCarryOverPts=> {
                                label => $Data->{'SystemConfig'}{'TribunalCarryOverPts'} ? 'Carry Over Points' : '',
                                value => $field->{intCarryOverPts},
                                type  => 'text',
                                size  => '15',
                                maxsize => '15',
                                validate => 'NUMBER',
                                sectionname => 'outcome',
                        },
			dtPenaltyExp=> {
                                label => 'Penalty Expiry Date',
                                value => $field->{dtPenaltyExp},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'outcome',
                                validate => 'DATE',
                        },
			intSuspendedPenalty=> {
                                label => 'Suspended Penalty (Units)',
                                value => $field->{intSuspendedPenalty},
                                type  => 'text',
                                size  => '15',
                                maxsize => '15',
                                validate => 'FLOAT',
                                sectionname => 'outcome',
                        },
			strSuspendedPenaltyType=> {
        			label => 'Suspended Penalty (Type)',
                                value => $field->{strSuspendedPenaltyType},
                                type  => 'lookup',
                                options => \%Defs::TribunalTypes,
                                firstoption => [''," "],
                                sectionname => 'outcome',
                        },
			dtSuspPenExpDate=> {
                                label => 'Suspended Penalty Expiry Date',
                                value => $field->{dtSuspPenExpDate},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'outcome',
                                validate => 'DATE',
                        },
            		intAppealed=> {
                		label => 'Appealed ?',
                		value => $field->{intAppealed},
                		type => 'checkbox',
				displaylookup => {1 => 'Yes', 0 => 'No'},
				sectionname => 'appeal',
            		},
			intAppealedOutcomeID=> {
        			label => 'Appeal Outcome',
                                value => $field->{intAppealedOutcomeID},
                                type  => 'lookup',
                                options => \%Defs::TribunalAppeal,
                                firstoption => [''," "],
                                sectionname => 'appeal',
                        },
			dtAppeal=> {
                                label => 'Appeal Date',
                                value => $field->{dtAppeal},
                                type  => 'date',
                                format => 'dd/mm/yyyy',
                                sectionname => 'appeal',
                                validate => 'DATE',
                        },
            		intPublicView=> {
                		label => 'Allow Public View ?',
                		value => $field->{intPublicView},
                		type => 'checkbox',
				displaylookup => {1 => 'Yes', 0 => 'No'},
				sectionname => 'other',
            		},
                        strNotes => {
                                label => 'Notes',
                                value => $field->{strNotes},
                                type => 'textarea',
                                rows => '8',
                                cols => '40',
				validate => 'NO HTML',
				sectionname => 'other',
                        },
			SPdetails    => { type =>'_SPACE_', sectionname => 'contactdetails'},
                        SPclub    => { type =>'_SPACE_', sectionname => 'clubdetails'},
                        SPother    => { type =>'_SPACE_', sectionname => 'otherdetails'},
		},
		order => [qw(intRecStatus intChargeID intCharge2ID intCharge3ID intMatchID intMemberTeamID intCompAddID intTeamID intCompID intClubID intTribunalAgeGroupID dtCharged strOffence strChargeGrading strWitness strReporter dtHearing tHearing intHearingVenueID strOutcome intPenalty strPenaltyType intCarryOverPts dtPenaltyStartDate dtPenaltyExp intSuspendedPenalty strSuspendedPenaltyType dtSuspPenExpDate intAppealed intAppealedOutcomeID dtAppeal intPublicView strNotes)],
		 sections => [
                        ['comp',"Competition Details"],
                        ['details',"Incident Details"],
                        ['hearing',"Hearing Details"],
                        ['outcome',"Outcome Details"],
                        ['appeal',"Appeal Details"],
                        ['other',"Other"],
                ],
	options => {
		labelsuffix => ':',
		hideblank => 1,
		target => $Data->{'target'},
		formname => 'n_form',
      		submitlabel => "Update $txt_Tribunal Record",
      		introtext => 'auto',
		NoHTML => 1,
      		updateSQL => qq[
        		UPDATE tblTribunal
          		SET --VAL--
        		WHERE intTribunalID=$tribunalID
				AND intAssocID=$Data->{'clientValues'}{'assocID'}
        	],
      		addSQL => qq[
        		INSERT INTO tblTribunal
        	  	(intRealmID, intAssocID, intClubID, intMemberID, intTeamID, intCompID, dtCreated, --FIELDS-- )
			VALUES ($Data->{'Realm'}, $Data->{'clientValues'}{'assocID'}, $clubID, $Data->{'clientValues'}{'memberID'}, $teamID, $compID, CURRENT_DATE(), --VAL-- )
        	],
		afterupdateFunction => \&postTribunalUpdate,
                afterupdateParams => [$option,$Data,$Data->{'db'}, $tribunalID],
		afteraddFunction => \&postTribunalUpdate,
                afteraddParams => [$option,$Data,$Data->{'db'}],

                auditFunction=> \&auditLog,
                auditAddParams => [
                        $Data,
                        'Add',
                        'Tribunal'
                ],
                auditEditParams => [
                        $tribunalID,
                        $Data,
                        'Update',
                        'Tribunal'
                ],
   
      		LocaleMakeText => $Data->{'lang'},
	},
    	carryfields =>  {
      		client => $client,
      		a=> $action,
		tID=>$tribunalID,
    	},
  );
  my $resultHTML='';
  ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, '',$Data->{'db'});
  my $title=$field->{'strName'} || '';
  if($option eq 'display')  {
    my $chgoptions='';
    $chgoptions.=qq[<a href="$Data->{'target'}?client=$client&amp;a=TB_DTE"><img src="images/edit.png" border="0" alt="Edit $txt_Tribunal" title="Edit $txt_Tribunal"></a> ] if (allowedAction($Data, 'tb_e') and $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ASSOC);
    $chgoptions=qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
    $title=$chgoptions.$title;
	}
	$title="Add New $txt_Tribunal Record" if $option eq 'add';

	return ($resultHTML,$title);
}

sub postTribunalUpdate	{

        my($id,$params, $action,$Data,$db, $tribunalID)=@_;
$tribunalID ||=0;
        $id||=$tribunalID;
        return (0,undef) if !$db;

	my $memberteamID = $params->{'d_intMemberTeamID'} || 0;
	my $matchID = $params->{'d_intMatchID'} || 0;
	 my $compAddID= $params->{'d_intCompAddID'} || 0;
	my $memberID = $Data->{'clientValues'}{'memberID'} || 0;
	return if ! $memberID;

	my ($teamID, $compID, $clubID) = (0,0,0);
	if ($memberteamID)	{
		my $st = qq[
			SELECT 
				MT.intTeamID, 
				intCompID, 
				intClubID
			FROM tblMember_Teams as MT
				LEFT JOIN tblTeam as T ON (T.intTeamID = MT.intTeamID)
			WHERE intMemberID = $memberID
				AND intMemberTeamID = $memberteamID
		];
  		my $qry = $db->prepare($st);
  		$qry->execute;
		($teamID, $compID, $clubID) = $qry->fetchrow_array();
		$teamID ||= 0;
		$compID ||= 0;
		$st = qq[
			UPDATE tblTribunal
			SET 
				intTeamID = $teamID, 
				intCompID = $compID, 
				intClubID = $clubID
			WHERE intMemberID = $memberID
				AND intTribunalID = $id
		];
  		$qry = $db->prepare($st);
  		$qry->execute;
	}
	elsif ($compAddID)  {
    my $st = qq[
      UPDATE tblTribunal
      SET
        intCompID = ?
      WHERE intMemberID = ?
        AND intTribunalID = ?
        LIMIT 1
      ];
      my $qry = $db->prepare($st);
      $qry->execute($compAddID, $memberID, $id);
  }

	my $st = qq[
		UPDATE tblMember
		SET dtSuspendedUntil = "$params->{'d_dtPenaltyExp'}"
		WHERE intMemberID = $memberID
			AND (dtSuspendedUntil = '0000-00-00' 
				OR dtSuspendedUntil IS NULL 
				OR dtSuspendedUntil < "$params->{'d_dtPenaltyExp'}"
			)
	];
  	my $qry = $db->prepare($st);
  	$qry->execute;

}

sub loadTribunalDetails {
	my($db, $id, $assocID) = @_;
  	return {} if !$id;
  	my $statement=qq[
   		SELECT 
			T.*, 
			DATE_FORMAT(dtCharged,'%d/%m/%Y') AS dtCharged, 
			DATE_FORMAT(dtHearing,'%d/%m/%Y') AS dtHearing, 
			DATE_FORMAT(dtPenaltyExp,'%d/%m/%Y') AS dtPenaltyExp, 
			DATE_FORMAT(dtSuspPenExpDate,'%d/%m/%Y') AS dtSuspPenExpDate, 
			Team.strName as TeamName, 
			AssocComp.strTitle as CompTitle, 
			Club.strName as ClubName
    		FROM tblTribunal as T
			LEFT JOIN tblTeam as Team ON (Team.intTeamID = T.intTeamID)
			LEFT JOIN tblClub as Club ON (Club.intClubID = T.intClubID)
			LEFT JOIN tblAssoc_Comp as AssocComp ON (AssocComp.intCompID = T.intCompID)
    		WHERE intTribunalID=$id
			AND T.intAssocID=$assocID
  	];
  	my $query = $db->prepare($statement);
  	$query->execute;
	my $field=$query->fetchrow_hashref();
  	$query->finish;
                                                                                                        
  	foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
  	return $field;
}

1;

