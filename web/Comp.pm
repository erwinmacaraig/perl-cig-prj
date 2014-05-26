#
# $Header: svn://svn/SWM/trunk/web/Comp.pm 10572 2014-01-31 06:33:08Z dhanslow $
#

package Comp;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleComp loadCompDetails getCompTeams viewStagesPools listComps);
@EXPORT_OK=qw(handleComp loadCompDetails getCompTeams viewStagesPools listComps);

use strict;

use Reg_common;
use Utils;
use HTMLForm;
use lib "..","comp","sportstats";

use CGI qw(param unescape);

use FormHelpers;
use AuditLog;
use Ladder;
use LadderStats;
use PlayerCompStats;
use PlayerRoundStats;
use Assoc;
use CompObj;

use Seasons;
use FixtureTemplate;
use WizardBubbles qw(addBubble);
use InstanceOf;
use FieldLabels;
use GridDisplay;
use RecordTypeFilter;
use HomeComp;
use FieldCaseRule;
use DefCodes;

use ConfigDefs;
use MatchCredits;

require Comp_PoolsStages;

sub handleComp	{
	my ($action, $Data, $compID, $typeID)=@_;

	my $resultHTML='';
	my $compName=
	my $title='';
    my $client = setClient($Data->{'clientValues'});
    
	if ($action =~/^CO_DT/) {
		#Comp Details
        ($resultHTML,$title)=comp_details($action, $Data, $compID, $typeID);
	}
	elsif ($action eq 'CO_L') {
		#List Comp Children
        ($resultHTML,$title)=listComps($Data, $compID, $typeID);
	}
	elsif ($action eq 'CO_S') {
		#List Comp Stats
	}
    elsif ($action eq 'CO_AT') {
        # Assignement of team to competition
        ($resultHTML,$title)=assignCompTeams($Data, $compID,$client);
    }
    elsif ($action eq 'CO_AT_S') {
        ($resultHTML,$title)=saveAssignedCompTeams($Data, $compID,$client);
    }
    elsif ($action eq 'CO_DEL') {
        ($resultHTML,$title)=deleteComp($Data, $compID,$client);
    }
    elsif ($action eq 'CO_SP') {
        ($resultHTML,$title)=viewStagesPools($Data, $compID,$client);
    }
    elsif ($action eq 'CO_ADD') {
        ($resultHTML,$title)=newCompPage($Data, $client);
    }
    elsif ($action eq 'CO_HOME') {
        ($resultHTML,$title)=showCompHome($Data, $compID);
    }

	return ($resultHTML,$title);
}

sub viewStagesPools   {

    my ($Data, $compID, $client) = @_;

    $compID ||= 0;

    my $st = qq[
        SELECT
            S.intCompStageID,
            S.intStageNumber,
            S.intStageType,
            S.strStageName,
            S.intRecStatus as StageStatus,
            P.intStageID,
            P.intCompPoolID,
            P.intPoolNumber,
            P.intPoolType,
            P.strPoolName,
            P.intPoolLocked,
            P.intRecStatus as PoolStatus,
            COUNT(CTP.intTeamID) as CountTeams,
            COUNT(CM.intMatchID) as CountMatches
        FROM
            tblComp_Stages as S
            LEFT JOIN tblComp_Pools as P ON (
                P.intStageID = S.intCompStageID
            )
            LEFT JOIN tblComp_Teams_Pools as CTP ON (
                CTP.intPoolID = P.intCompPoolID
                AND CTP.intCompID = P.intCompID
                AND CTP.intRecStatus<>$Defs::RECSTATUS_DELETED
            )
            LEFT JOIN tblComp_Teams_Pools as CT ON (
                CT.intTeamID = CTP.intTeamID
                AND CT.intCompID = CTP.intCompID
                AND CT.intRecStatus<>$Defs::RECSTATUS_DELETED
            )
            LEFT JOIN tblCompMatches as CM ON (
                CM.intCompPoolID>0 
                AND (
                    CM.intHomePoolID = P.intCompPoolID
                    OR CM.intAwayPoolID = P.intCompPoolID
                )
            )
        WHERE 
            S.intCompID = ?
            AND (CTP.intTeamID IS NULL or (CTP.intTeamID>0 AND CT.intTeamID>0))
        GROUP BY 
            P.intCompPoolID
        ORDER BY
            S.intStageNumber,
            P.intPoolNumber
     ];


    my $query = $Data->{'db'}->prepare($st);
	$query->execute($compID);
	$Data->{'clientValues'}{'compID'} = $compID;
	$Data->{'clientValues'}{'currentLevel'} = $Defs::LEVEL_COMP;
    Reg_common::setClientValue($Data->{'clientValues'},$Defs::LEVEL_COMP, $Data->{'clientValues'}{'compID'});
    my $url_client = Reg_common::setClient($Data->{clientValues});
    my $body = qq[
			<div class="hint">Note: $Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'} must be added to the $Data->{'LevelNames'}{$Defs::LEVEL_COMP} before they can be assigned to a pool. <a href="$Data->{'target'}?client=$client&amp;a=T_L">Click here to add/edit $Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'}</a> </div>
            <table id="ltable" class="listTable" >
    ];
    my $count=0;
    my $currentStageID=0;
       
    my $cgi = new CGI;
    my $add_stage = $cgi->url()."?a=COPS_SDTA&amp;client=$url_client"; 
    my $add_pool = $cgi->url()."?a=COPS_PDTA&amp;client=$url_client"; 
    my $option_add_stage = qq[<a href="$add_stage">Add Phase</a>];
    my $option_add_pool= qq[<a href="$add_pool">Add Pool</a>];
    while (my $dref = $query->fetchrow_hashref()) {
        my $url_editStage= $cgi->url()."?stageID=$dref->{intCompStageID}&amp;a=COPS_SDTE&amp;client=$url_client"; 
        $dref->{'strStageName'} ||= '-';
		if ($currentStageID != $dref->{'intCompStageID'} and $currentStageID)	{
			$body .= qq[
				<tr>
					<td colspan="8">
						$option_add_pool
					</td>
				</tr>
			];
		}
		my $name = qq[&nbsp;<span style="color:red;"><b>($Defs::CompStageType{$dref->{'intStageType'}})</b></span>];
		$name='' if $dref->{'intStageType'} != 3;
        $body .= qq[
            <tr>
                <td colspan="8">
                    <div>
                        <br>
<a href="$url_editStage" class = "sectionheader">$dref->{'strStageName'}$name</a><br>
                    </div>
                </td>
            </tr>

        ] if ($currentStageID != $dref->{'intCompStageID'});
        if ($dref->{intCompPoolID}) {
            my $progression_rules = '';
            my $url_progression= $cgi->url()."?poolID=$dref->{intCompPoolID}&amp;a=COPR_L&amp;client=$url_client"; 
            $progression_rules = qq[<a href="$url_progression">Add/Edit Progression Rules...</a><br>] if ($dref->{intStageType} and $dref->{intStageType}>1);
            #$progression_rules='';
            my $run_rules = '';
            my $url_runrules= $cgi->url()."?stageID=$dref->{intCompStageID}&amp;poolID=$dref->{intCompPoolID}&amp;a=COPR_Run&amp;client=$url_client"; 
            $run_rules = qq[<a href="$url_runrules">Run Progression Rules</a><br>] if ($dref->{intStageType} and $dref->{intStageType}>1);
            $run_rules='Rules Disabled (Pool has Teams)' if ($dref->{CountTeams} > 0 and $dref->{intStageType} and $dref->{intStageType}>1);
            my $url_editPool= $cgi->url()."?poolID=$dref->{intCompPoolID}&amp;a=COPS_PDTE&amp;client=$url_client"; 
            my $url_teams= $cgi->url()."?stageID=$dref->{intCompStageID}&amp;poolID=$dref->{intCompPoolID}&amp;a=COPS_T&amp;client=$url_client"; 
            my $url_fixture= $cgi->url()."?stageID=$dref->{intCompStageID}&amp;poolID=$dref->{intCompPoolID}&amp;a=FIX_COMP&amp;client=$url_client"; 
            my $url_finals= $cgi->url()."?stageID=$dref->{intCompStageID}&amp;poolID=$dref->{intCompPoolID}&amp;a=FIX_FINALS&amp;client=$url_client"; 
            my $url_ladder= $cgi->url()."?stageID=$dref->{intCompStageID}&amp;poolID=$dref->{intCompPoolID}&amp;a=LDR_D&amp;client=$url_client"; 
            my $url_del_pool= $cgi->url()."?stageID=$dref->{intCompStageID}&amp;poolID=$dref->{intCompPoolID}&amp;a=COPS_DEL&amp;client=$url_client"; 

            my $lock_pool= '';
            my $url_unlockpool= $cgi->url()."?stageID=$dref->{intCompStageID}&amp;poolID=$dref->{intCompPoolID}&amp;a=COPS_UNLOCKS&amp;client=$url_client"; 
            my $url_lockpool= $cgi->url()."?stageID=$dref->{intCompStageID}&amp;poolID=$dref->{intCompPoolID}&amp;a=COPS_LOCKP&amp;client=$url_client"; 
            $lock_pool= qq[<a href="$url_lockpool">Lock Pool</a><br>] if (! $dref->{intPoolLocked});
            $lock_pool= qq[<a href="$url_unlockpool">Unlock Pool</a><br>] if ($dref->{intPoolLocked});

            $dref->{'strPoolName'} .= qq[&nbsp;<i>(Inactive)</i>] if (! $dref->{PoolStatus});
            $body .= qq[
                <tr>
                    <td>&nbsp;</th>
                    <td>$dref->{'intPoolNumber'}</td>
                    <td><a href="$url_editPool">$dref->{'strPoolName'}</a></td>
            ];
            if ($dref->{intPoolLocked}) {
                $body .= qq[
                    <td>Teams (locked)</td>
                ];
             }
             else   {
                $body .= qq[
                    <td><a href="$url_teams">Teams</a></td>
                ];
             }
             my $del_pool = ($dref->{'CountMatches'} or $dref->{'CountTeams'}) ? qq[&nbsp;] : qq[<span class = "button-small generic-button"><a href="$url_del_pool">Delete</a></span>];
			if ($dref->{'intStageType'} == 3)	{
				$body .= qq[<td>&nbsp;</td>];
			}
			else	{
             $body .= qq[
                    <td><a href="$url_fixture">Fixture</a></td>
			];
			}
			if ($dref->{'intStageType'} == 3)	{
				$body .= qq[
                    <td><a href="$url_finals">Finals</a></td>
				];
			}
			else	{
				$body .= qq[<td></td>];
			}
			$body .= qq[
                    <td><a href="$url_ladder">Ladder</a></td>
                    <td>$lock_pool</td>
                    <td>$progression_rules</td>
                    <td>$run_rules</td>
                    <td>$del_pool</td>
                </tr>
            ];
        }
        $count++;
        $currentStageID = $dref->{'intCompStageID'};

    }

    $body .= qq[
				<tr>
					<td colspan="8">
						$option_add_stage<br>
						$option_add_pool
					</td>
				</tr>
		</table>
	];

    my $runWizard = $cgi->url()."?a=COPS_WIZARD&amp;nextstep=1&amp;client=$url_client&amp;compID=$compID"; 
    $body .= qq[No configurations have been found.<br><a href="$runWizard">Run Setup Wizard</a>] if ! $count;

    my $header = qq[
        <div class="pageHeading">$Data->{'LevelNames'}{$Defs::LEVEL_COMP} Phase & Pool Structure</div>
    ];
    $body = $header . $body;
            

    return $body;
}

sub comp_details	{
	my ($action, $Data, $compID, $typeID)=@_;
    
	my $option = 'display';
	$option = 'edit' if $action eq 'CO_DTE';
	$option = 'add' if $action eq 'CO_DTA';
	$compID = 0 if $option eq 'add';
	my $field = loadCompDetails($Data->{'db'}, $compID) || ();
    
  my $AssocDetails = loadAssocDetails($Data->{'db'}, $Data->{'clientValues'}{'assocID'});
    
  my $compObj = new CompObj(
    'db' => $Data->{'db'},
    'ID' => $compID,
    'assocID' => $Data->{'clientValues'}{'assocID'}
  );
  my $hasStarted = $compObj->hasStarted();
  my $isCompleted = $compObj->isCompleted();
    
  my $intAllowSWOL = $AssocDetails->{'intSWOL'};
  my $sportID = $AssocDetails->{'intSWOL_SportID'};
    
  $option = 'display' if $field->{'intStarted'} && !$intAllowSWOL;
    
    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        assocID    => $Data->{'clientValues'}{'assocID'},
    );

  my %CourtsideConfig = ();
  {
    if ($compID) {
      my $statement = qq[
        SELECT
          strKey,
          strValue
        FROM
          tblAssoc_Comp_Courtside
        WHERE
          intCompID = ?
      ];
      my $query = $Data->{'db'}->prepare($statement);
		  $query->execute($compID);
      while (my ($strKey, $strValue) = $query->fetchrow_array()) {
        $CourtsideConfig{$strKey} = $strValue || '';
      }
    }
  }

  my $fixtureType = param('ftype') || $field->{'intFixtureType'} || 0;
		
	my $st_grades = qq[ 
    SELECT 
      intAssocGradeID,
      strGradeDesc 
    FROM 
      tblAssoc_Grade 
    WHERE 
      intAssocID = $Data->{'clientValues'}{'assocID'} 
      AND intRecStatus = $Defs::RECSTATUS_ACTIVE
  ]; 
	my ($grades_vals,$grades_order) = getDBdrop_down_Ref($Data->{'db'},$st_grades,'');
    
	my $st_ageGroups = qq[ 
    SELECT 
      intAgeGroupID, 
      strAgeGroupDesc 
    FROM 
      tblAgeGroups 
    WHERE 
      intRealmID = $Data->{'Realm'} 
      AND (intAssocID = $Data->{'clientValues'}{'assocID'} or intAssocID=0) 
      AND intRealmSubTypeID IN (0, $Data->{'RealmSubType'}) 
      AND intRecStatus = $Defs::RECSTATUS_ACTIVE 
  ];
	my ($ageGroups_vals,$ageGroups_order) = getDBdrop_down_Ref($Data->{'db'},$st_ageGroups,'');

	my $txt_AgeGroupName = $Data->{'SystemConfig'}{'txtAgeGroup'} || 'Age Group';
 my $subTypeSeasonOnly = $Data->{'SystemConfig'}->{'OnlyUseSubRealmSeasons'} ? '' : 'OR intRealmSubTypeID= 0';

	my $st_seasons = qq[ 
		SELECT 
      intSeasonID, 
      strSeasonName
    FROM 
      tblSeasons 
    WHERE 
      intRealmID = $Data->{'Realm'}
      AND (intAssocID = $Data->{'clientValues'}{'assocID'} OR intAssocID = 0)
      AND (intRealmSubTypeID = $Data->{'RealmSubType'} $subTypeSeasonOnly)
    ORDER BY 
      intSeasonOrder
	];
	my ($seasons_vals,$seasons_order) = getDBdrop_down_Ref($Data->{'db'},$st_seasons,'');
	my $txt_SeasonName = $Data->{'SystemConfig'}{'txtSeason'} || 'Season';

	my $assocSeasons = getDefaultAssocSeasons($Data);


	my $st_mdr = qq[
		SELECT 
			intMatchDayReportID,
			strName
		FROM
			tblMatchDayReports 
		WHERE
			intAssocID = $Data->{'clientValues'}{'assocID'}
			AND intStatus = 1
	];

	my ($matchdayreports_vals,$matchdayreports_order) = getDBdrop_down_Ref($Data->{'db'},$st_mdr,'');

  my $client = setClient($Data->{'clientValues'}) || '';
  my $submitLabel = qq[Update $Data->{'LevelNames'}{$Defs::LEVEL_COMP}];
  my $compulsory = qq[<img src="images/compulsory.gif" alt="Compulsory Field" title="Compulsory Field"/>];
  
  my $editIntroText = qq[
    <p class="introtext">To modify this information change the information in the boxes below and when you have finished press the <b>$submitLabel</b> button.  <br><b>Note:</b> All boxes marked with a $compulsory are compulsory and must be filled in.</p>
  ];
    
  $hasStarted = 0 if($option eq 'add');
  $isCompleted = 0 if($option eq 'add');
  $editIntroText = qq[<div class="warningmsg">As this $Data->{'LevelNames'}{$Defs::LEVEL_COMP} has already started or is completed, not all options can be modified.</div>$editIntroText] if $hasStarted || $isCompleted;
  my $posttext_tmDefaultStartTime = '';
	my $st_umpires = qq[
    SELECT 
      COUNT(intComp_AssocID) as CountAssoc
    FROM 
      tblUmpireLevelConfig
    WHERE
      intComp_AssocID = $Data->{'clientValues'}{'assocID'}
  ];
  my $qry_umpires = $Data->{'db'}->prepare($st_umpires);
  $qry_umpires->execute;
  my $umpireAllocation = $qry_umpires->fetchrow_array() || 0;
  my $st_ec = qq[
	  SELECT 
		  *
	  FROM
		  tblUmpireExpRealmConfig
	  WHERE 
		  intRealmID = $Data->{'Realm'}
	];
  my $qry_ec = $Data->{'db'}->prepare($st_ec);
  $qry_ec->execute;
	my %ExpenseCode = ();
  my $dref = $qry_ec->fetchrow_hashref();
	for my $i (1 .. 15) {
    my $expCode = "strExpense$i";
		$ExpenseCode{$i} = '';
		$ExpenseCode{$i} = $dref->{$expCode} ? qq[$dref->{$expCode} - Override code] : '';
	}
  ## ONLY SHOW COURTSIDE FIELDS IF SWOL IS TURNED ON
  ## CAN ADD EXTRA TESTS FOR AssocConfig IF REQUIRED TO TURN
  ## ON BY ASSOC
  unless ($intAllowSWOL) {
      @{$ConfigDefs::CourtsideRealmFields{$sportID}} = ();
    }
         my @ConfigDefsArray = ($ConfigDefs::CourtsideRealmFields{$sportID}) ? @{$ConfigDefs::CourtsideRealmFields{$sportID}} : ();
 
  my $field_case_rules = get_field_case_rules({dbh=>$Data->{'db'}, client=>$client, type=>'Comp'});
	my (undef, $matchCreditType) = getMatchCreditTypes($Data, $dref->{'intMatchCreditType'});
	my $st_prods=qq[ SELECT intProductID, strName FROM tblProducts WHERE intProductType NOT IN ($Defs::PROD_TYPE_MINFEE) AND intMatchCreditType > 0 AND intRealmID = $Data->{'Realm'} and (intAssocID =0 or intAssocID=$Data->{'clientValues'}{'assocID'}) AND intInactive = 0 AND intProductSubRealmID IN (0, $Data->{'RealmSubType'})];
	my ($prods_vals,$prods_order)=getDBdrop_down_Ref($Data->{'db'},$st_prods,'');

  my %FieldDefinitions = (
    fields => {
      strTitle => {
        label => "$Data->{'LevelNames'}{$Defs::LEVEL_COMP} " . 'Name',
        value => $field->{strTitle},
        type  => 'text',
        size  => '40',
        maxsize => '150',
        compulsory => 1,
        sectionname => 'main',
      },
      intRecStatus => {
        label => $Data->{'SystemConfig'}{'AllowStatusChange'} ? 'Active?' : '',	
        value => $field->{intRecStatus},
        type => 'checkbox',
        default => 1,
        displaylookup => {1=>'Yes', 0=>'No'},
        noadd => 1,
        sectionname => 'main',
      },
      strAbbrev => {
        label => 'Abbreviation',
        value => $field->{strAbbrev},
        type  => 'text',
        size  => '10',
        maxsize => '10',
        sectionname => 'main',
        readonly => $isCompleted,
      },
      strContact => {
        label => 'Contact',
        value => $field->{strContact},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'main',                           
        readonly => $isCompleted,
      },
      intSeasonID => {
        label => ! $assocSeasons->{'allowSeasons'} ? 'Season' : '',
        value => $field->{intSeasonID},
        type  => 'lookup',
        noedit => $hasStarted,
        options => $DefCodes->{-5},
        order => $DefCodesOrder->{-5},
        firstoption => ['',"Choose Season"],
        sectionname => 'main',
      },
      intNewSeasonID => {
        label => $assocSeasons->{'allowSeasons'} ? "$txt_SeasonName" : '',
        value => $field->{intNewSeasonID},
        type  => 'lookup',
        readonly=> $hasStarted,
        options => $seasons_vals,
        default => $assocSeasons->{'currentSeasonID'},
        firstoption => ['',"Choose $txt_SeasonName"],
        compulsory=> $assocSeasons->{'allowSeasons'} ? 1 : 0,
        sectionname => 'main',
      },
      intCompTypeID => {
        label => "$Data->{'LevelNames'}{$Defs::LEVEL_COMP} " . 'Type',
        value => $field->{intCompTypeID},
        type  => 'lookup',
        readonly => $hasStarted,
        options => $DefCodes->{-36},
        order => $DefCodesOrder->{-36},
        firstoption => ['',"Choose Type"],
        compulsory => $intAllowSWOL ? 1 : 0 ,
        sectionname => 'grades',
        readonly => $isCompleted,
      },
      intCompLevelID => {
        label => !$intAllowSWOL ? "$Data->{'LevelNames'}{$Defs::LEVEL_COMP} " . 'Level' : '',
        value => $field->{intCompLevelID},
        type  => 'lookup',
        options => $DefCodes->{-21},
        order => $DefCodesOrder->{-21},
        firstoption => ['',"Choose Level"],
        sectionname => 'grades',
        readonly => $isCompleted,
      },
      intGradeID => {
        label => $intAllowSWOL ? 'Division' : 'Grade',
        value => $field->{intGradeID},
        type  => 'lookup',
        readonly => $hasStarted,
        options => $grades_vals,
        firstoption => $intAllowSWOL ? ['','Choose Division'] : ['',"Choose Grade"],
        compulsory =>  $intAllowSWOL ? 1 : 0 ,
        sectionname => 'grades',
        readonly => $isCompleted,
      },
      intAgeGroupID => {
        label => "Default $txt_AgeGroupName" ,
        value => $field->{intAgeGroupID},
        type  => 'lookup',
        options => $ageGroups_vals,
        firstoption => ['',"Choose $txt_AgeGroupName"],
        compulsory =>  $intAllowSWOL ? 1 : 0 ,
        sectionname => 'grades',
      },
      intCompGender => {
        label => 'Gender',
        value => $field->{intCompGender},
        type  => 'lookup',
        readonly=> $hasStarted,
        options => \%Defs::genderInfo,
        firstoption => ['',"Choose Gender"],
        compulsory => $intAllowSWOL ? 1 : 0 ,
        sectionname => 'grades',
        readonly => $isCompleted,
      },			
      strAgeLevel => {
        label => 'Age Level',
        value => $field->{strAgeLevel},
        type  => 'lookup',
        readonly=> $hasStarted,
        options => \%Defs::CompAgeLevel,
        firstoption => ['',"Choose Age Level"],
        sectionname => 'grades',
        readonly => $isCompleted,
      },						
      intUseSeeding=> {
        label => $intAllowSWOL ? 'Use Seeding (if Knockout Fixture used)' : '',
        value => $field->{'intUseSeeding'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'fixturing',
        readonly => $isCompleted,
      },
      intNumTeams => {
        label => 'Max. Number of'  . " $Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'}",
        value => $field->{intNumTeams},
        type  => 'text',
        size  => '3',
        maxsize => '3',
        validate	=> 'BETWEEN:1-300',
        compulsory => $intAllowSWOL ? 1 : 0,
        sectionname => 'fixturing',
        readonly => $isCompleted,
      },
      intNumRounds => {
        label => $intAllowSWOL ? 'Number of Rounds' : '',
        value => $field->{intNumRounds},
        type  => 'text',
        size  => '2',
        maxsize => '2',
        validate => 'BETWEEN:0-100',
        compulsory => ($intAllowSWOL and $fixtureType != 2) ? 1 : 0,
        sectionname => 'fixturing',
        rreadonly => $isCompleted,
      }, 
      intMatchInterval => {
        label => $intAllowSWOL ? 'Days Between Rounds' : '',
        value => $field->{intMatchInterval},
        type  => 'text',
        size  => '2',
        maxsize => '2',
        validate => 'BETWEEN:0-14',
        compulsory => ($intAllowSWOL and $fixtureType != 2) ? 1 : 0,
        sectionname => 'fixturing',
        readonly => $isCompleted,
      }, 
      intVenueRequiredMins => {
        label => $intAllowSWOL ? 'Time Venue Required For (mins)' : '',
        value => $field->{intVenueRequiredMins},
        type  => 'text',
        size  => '3',
        maxsize => '3',
        validate => 'NUMBER',
        compulsory => $intAllowSWOL ? 1 : 0,
        sectionname => 'fixturing',
        readonly => $isCompleted,
      }, 
      intPercentageOfVenue => {
        label => $intAllowSWOL ? '% of Venue Required' : '',
        value => $field->{intPercentageOfVenue} || 100,
        type  => 'text',
        size  => '3',
        maxsize => '3',
				validate => 'BETWEEN:0-100',
        compulsory => $intAllowSWOL ? 1 : 0,
        sectionname => 'fixturing',
        readonly => $isCompleted,
      }, 
      dtStart => {
        label => 'Start Date',
        value => $field->{'dtStart'},
        type  => 'date',
        readonly=> $hasStarted,
        format => 'dd/mm/yyyy',
        validate => 'DATE',
        compulsory =>  $intAllowSWOL ? 1 : 0 ,
        sectionname => 'fixturing',
        readonly => $isCompleted,
      },
      strCompAltName => { 
        label => $intAllowSWOL ? 'Alternate Name' : '',
        value => $field->{strCompAltName},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'main',
        readonly => $isCompleted,
      },
      strCompGrouping => {
        label => $intAllowSWOL ? 'Website Grouping' : '',
        value => $field->{strCompGrouping},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'display',
      },
      dtMinDOB => {
        label => $intAllowSWOL ? 'From (Maximum Age) DOB' : '', #Min DOB = MAX Age (Oldest)
        value => $field->{'dtMinDOB'},
        type  => 'date',
        datetype => 'dropdown',
        format => 'dd/mm/yyyy',
        validate => 'DATE',
        sectionname => 'grades',
        readonly => $isCompleted,
      },
      dtMaxDOB => {
        label => $intAllowSWOL ? 'To (Minimum Age) DOB' : '', #MAX DOB = MIN Age (Youngest)
        value => $field->{'dtMaxDOB'},
        type  => 'date',
        datetype => 'dropdown',
        format => 'dd/mm/yyyy',
        validate => 'DATE',
        sectionname => 'grades',
        readonly => $isCompleted,
      },
      tmDefaultStartTime => {
        label => $intAllowSWOL ? 'Default Game Start Time' : '',
        value => $field->{'tmDefaultStartTime'} ? $field->{'tmDefaultStartTime'} : CompObj->getDefaultValueBySport($sportID,'tmDefaultStartTime'),
        type  => 'time',
        sectionname => 'fixturing',
				compulsory =>  ($intAllowSWOL and !$fixtureType)? 1 : 0 ,
        posttext => $posttext_tmDefaultStartTime,
      },
      intMatchDuration => {
        label => $intAllowSWOL ? 'Match Duration (mins)' : '',
        value => $field->{'intMatchDuration'} ? $field->{'intMatchDuration'} : CompObj->getDefaultValueBySport($sportID,'intMatchDuration'),
        type => 'text',
        size =>3,
        maxsize => 3,
        compulsory => $intAllowSWOL ? 1 : 0,
        validate => 'BETWEEN:1-200',
        sectionname => 'fixturing',
        readonly => $isCompleted,
      },
      intAllowMinAgeExceptions => {
        label => $intAllowSWOL ? 'Allow Minimum DOB Exceptions' : '',
        value => $field->{'intAllowMinAgeExceptions'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'grades',
        readonly => $isCompleted,
      },
      intAllowMaxAgeExceptions => {
        label => $intAllowSWOL ? 'Allow Maximum DOB Exceptions' : '',
        value => $field->{'intAllowMaxAgeExceptions'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'grades',
        readonly => $isCompleted,
      },
      intNumFinalsEligibility => {
        label => $intAllowSWOL ? 'Matches for Finals Eligibility' : '',
        value => $field->{'intNumFinalsEligibility'},
        type => 'text',
        size =>2,
        maxsize => 2,
        validate => 'BETWEEN:0-100',
        sectionname => 'fixturing',
        readonly => $isCompleted,
      },
      'intNominations' => {
        label => $Data->{'SystemConfig'}{'AssocConfig'}{'allowTeamEntry'} ? "$Data->{'LevelNames'}{$Defs::LEVEL_TEAM. '_P'} are Nominated to $Data->{'LevelNames'}{$Defs::LEVEL_COMP}" : '',
        value => $field->{'intNominations'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'fixturing',
      },
      intOrder => {
        label =>$intAllowSWOL ? 'Sort Order' : '',
        value => $field->{'intOrder'},
        type => 'text',
        size =>3,
        maxsize => 3,
        validate => 'BETWEEN:0-999',
        sectionname => 'grades',
      },
      intUpload => {
        label => $intAllowSWOL ? 'Display Competition on public website ?' : '',
        value => $field->{'intUpload'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'display',
      },
      intDisplayResults => {
        label => $intAllowSWOL ? 'Display Results' : '',
        value => $field->{'intDisplayResults'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'display',
      },
      intDisplayLadder => {
        label => $intAllowSWOL ? 'Display Ladder' : '',
        value => $field->{'intDisplayLadder'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'display',
      },
      intFixtureConfigID => {
        label => ($fixtureType != 2 and $intAllowSWOL ) ? "Fixture Template" : '',
        value => $field->{intFixtureConfigID},
        type  => 'lookup',
        options => FixtureTemplate->getFixtureTemplates({'data' => $Data, 'types' => [0,2],}),
        firstoption =>['',"Choose a Fixture Template"],
        sectionname => 'templates',
        compulsory => ($intAllowSWOL and $fixtureType != 2) ? 1 : 0,
        rreadonly => $isCompleted,
      },
      intCompFixtureType=> {
        label => $intAllowSWOL ? "Publish to Web as" : '',
        value => $field->{intCompFixtureType},
        type  => 'lookup',
        options => \%Defs::CompFixtureType,
        default => 1,
        firstoption => ['',"Choose Type"],
        sectionname => 'templates',
      },
      intLadderConfigID => {
        label => $intAllowSWOL ? "Ladder Template" : '',
        value => $field->{intLadderConfigID},
        type  => 'lookup',
        options => Ladder->get_templates($Data->{'db'},$Data->{Realm},1,$Data->{'clientValues'}{'assocID'}),
        firstoption =>['',"Choose a Ladder Template"],
        sectionname => 'templates',
      },
      intFinalsConfigID => {
        label => ($fixtureType != 2 and $intAllowSWOL ) ? "Finals Template" : '',
        value => $field->{intFinalsConfigID},
        type  => 'lookup',
        options => FixtureTemplate->getFixtureTemplates({'data' => $Data, 'types' => [1],}),
        firstoption =>['',"Choose a Finals Type"],
        sectionname => 'templates',
        rreadonly => $isCompleted,
      },
      intStatsConfigID => {
        label => $intAllowSWOL ? "Player Comp Stats Template" : '',
        value => $field->{intStatsConfigID},
        type  => 'lookup',
        options => PlayerCompStats->get_templates($Data->{'db'}, $Data->{'Realm'}, $Defs::PLAYER_COMP_STATS, $Data->{'clientValues'}{'assocID'}),
        firstoption => ['',"Choose a Stats Type"],
        sectionname => 'templates',
      },
      intRoundStatsConfigID=> {
        label => $intAllowSWOL ? "Player Round Stats Template" : '',
        value => $field->{intRoundStatsConfigID},
        type  => 'lookup',
        options => PlayerRoundStats->get_templates($Data->{'db'}, $Data->{'Realm'}, $Defs::PLAYER_ROUND_STATS, $Data->{'clientValues'}{'assocID'}),
        firstoption => ['',"Choose a Stats Type"],
        sectionname => 'templates',
      },
      intTeamMatchStatsID => {
        label =>  $intAllowSWOL ? "Team Match Stats Template" : '',
        value => $field->{intTeamMatchStatsID},
        type  => 'lookup',
        options => TeamMatchStats->get_templates($Data->{'db'}, $Data->{'Realm'}, $Defs::TEAM_MATCH_STATS, $Data->{'clientValues'}{'assocID'}),
        firstoption => ['',"Choose a Stats Type"],
        sectionname => 'templates',
      },
      intPlayerStatsConfigID => {
        label =>  $intAllowSWOL ? "Player Match Stats Template" : '',
        value => $field->{intPlayerStatsConfigID},
        type => 'lookup',
        options => PlayerMatchStats->get_templates($Data->{'db'}, $Data->{'Realm'}, $Defs::PLAYER_MATCH_STATS, $Data->{'clientValues'}{'assocID'}),
        firstoption => ['',"Choose a Stats Type"],
        sectionname => 'templates',
      },
      strCompNotes => {
        label => $intAllowSWOL ? 'Notes (displayed on website)' : '',
        value => $field->{strCompNotes},
        type => 'textarea',
        rows => '25',
        cols => '50',
        sectionname => 'notes',
      },
            strCompUmpireCostCode => {
			  label => $umpireAllocation ? qq[$Data->{'SystemConfig'}{'TYPE_NAME_3'} Competition Cost Code] : '',
        value => $field->{strCompUmpireCostCode},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
      },
			strCompUmpireTravelCode => {
			  label => $umpireAllocation ? qq[$Data->{'SystemConfig'}{'TYPE_NAME_3'} Travel Cost Code] : '',
        value => $field->{strCompUmpireTravelCode},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
      },
			strCompUmpirePayCode => {
			  label => $umpireAllocation ? qq[$Data->{'SystemConfig'}{'TYPE_NAME_3'} Pay Code] : '',
        value => $field->{strCompUmpirePayCode},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
      },
			strCompExpenseCode1 => {
			  label => ($umpireAllocation and $ExpenseCode{1}) ? $ExpenseCode{1} : '',
        value => $field->{strCompExpenseCode1},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode2 => {
			  label => ($umpireAllocation and $ExpenseCode{2}) ? $ExpenseCode{2} : '',
        value => $field->{strCompExpenseCode2},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode3 => {
			  label => ($umpireAllocation and $ExpenseCode{3}) ? $ExpenseCode{3} : '',
        value => $field->{strCompExpenseCode3},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode4 => {
			  label => ($umpireAllocation and $ExpenseCode{4}) ? $ExpenseCode{4} : '',
        value => $field->{strCompExpenseCode4},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode5 => {
			  label => ($umpireAllocation and $ExpenseCode{5}) ? $ExpenseCode{5} : '',
        value => $field->{strCompExpenseCode5},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode6 => {
			  label => ($umpireAllocation and $ExpenseCode{6}) ? $ExpenseCode{6} : '',
        value => $field->{strCompExpenseCode6},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode7 => {
			  label => ($umpireAllocation and $ExpenseCode{7}) ? $ExpenseCode{7} : '',
        value => $field->{strCompExpenseCode7},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode8 => {
			  label => ($umpireAllocation and $ExpenseCode{8}) ? $ExpenseCode{8} : '',
        value => $field->{strCompExpenseCode8},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode9 => {
			  label => ($umpireAllocation and $ExpenseCode{9}) ? $ExpenseCode{9} : '',
        value => $field->{strCompExpenseCode9},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode10 => {
			  label => ($umpireAllocation and $ExpenseCode{10}) ? $ExpenseCode{10} : '',
        value => $field->{strCompExpenseCode10},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode11 => {
			  label => ($umpireAllocation and $ExpenseCode{11}) ? $ExpenseCode{11} : '',
        value => $field->{strCompExpenseCode11},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode12 => {
			  label => ($umpireAllocation and $ExpenseCode{12}) ? $ExpenseCode{12} : '',
        value => $field->{strCompExpenseCode12},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode13 => {
			  label => ($umpireAllocation and $ExpenseCode{13}) ? $ExpenseCode{13} : '',
        value => $field->{strCompExpenseCode13},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode14 => {
			  label => ($umpireAllocation and $ExpenseCode{14}) ? $ExpenseCode{14} : '',
        value => $field->{strCompExpenseCode14},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
			},
			strCompExpenseCode15 => {
			  label => ($umpireAllocation and $ExpenseCode{15}) ? $ExpenseCode{15} : '',
        value => $field->{strCompExpenseCode15},
        type  => 'text',
        size  => '40',
        maxsize => '200',
        sectionname => 'umpire',
      },
      strCompAppointmentNote => {
        label => ($umpireAllocation and (! $field->{strCompAppointmentNote} or $option eq 'display')) ? qq[$Data->{'SystemConfig'}{'TYPE_NAME_3'} Appointment Notes] : '',
        value => $field->{strCompAppointmentNote},
        type => 'textarea',
        rows => '15',
        cols => '40',
        sectionname => 'umpire',
      },
      intMon => {
        label => "Monday?",
        value => $field->{'intMon'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'days',
      },
      intTue => {
        label => "Tuesday?",
        value => $field->{'intTue'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'days',
      },
      intWed => {
        label => "Wednesday?",
        value => $field->{'intWed'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'days',
      },
      intThu => {
        label => "Thursday?",
        value => $field->{'intThu'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'days',
      },
      intFri => {
        label => "Friday?",
        value => $field->{'intFri'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'days',
      },
      intSat => {
        label => "Saturday?",
        value => $field->{'intSat'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'days',
      },
      intSun => {
        label => "Sunday?",
        value => $field->{'intSun'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'days',
      },
      intAllowClubTeamResultsEntry => {
        label => $intAllowSWOL ? "Allow Clubs/Teams to enter results?" : '',
        value => $field->{'intAllowClubTeamResultsEntry'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'resultsentry',
      },
      intLockMatches => {
        label => $intAllowSWOL ? "Allow Match Locking ?" : '',
        value => $field->{'intLockMatches'},
        type => 'checkbox',
        default => 0,
        displaylookup => {1=>'Yes',0=>'No'},
        sectionname => 'lockmatches',
      },
      intLockDayOfWeek => {
        label => $intAllowSWOL ? qq[Lock all previously played matches on <span style='color:red;'>MIDNIGHT</span> of] : '',
        value => $field->{intLockDayOfWeek},
        type  => 'lookup',
        options => \%Defs::timeSlotDays,
        firstoption => ['',"Choose Day"],
        sectionname => 'lockmatches',
      },	
      LOCKTEXT => {
        label => $intAllowSWOL ? 'Match Locking' : '',
        value => "To enable Automatic match locking, you must tick the <b>Allow Match Locking</b> below and select a day",
        type  => 'textvalue',
        sectionname => 'lockmatches',
			  nodisplay => 1,
      },
      LOCKTEXT2 => {
        label => $intAllowSWOL ? 'Match Locking' : '',
        value => qq[ <span style="color:red;">* MIDNIGHT refers to AEST time.</span>],
        type  => 'textvalue',
        sectionname => 'lockmatches',
			  nodisplay => 1,
      },
	DAYSRUN => {
        label => ($intAllowSWOL ) ? 'Days run' : '',
        value =>  ($fixtureType != 1) ? qq[] : qq[$compulsory <span style="color:red;">You must choose at least one day from the list below for the competition to display in the time allocation grid.</span>],
        type  => 'textvalue',
        sectionname => 'days',
				nodisplay => 1,
      },
	intPeriodLength => {
        label => ($intAllowSWOL ) ? 'Period Length' : '',
        value =>  $field->{'intPeriodLength'},
       type  => 'text',
        size  => '2',
        maxsize => '2',
        validate => 'BETWEEN:0-100',
        sectionname => 'fixturing',
      },
      ( map { (
        'EC_' . $_->[0] => {
            label => $_->[1] || $ConfigDefs::Courtside{$_->[0]}->{label},
            value => "$CourtsideConfig{$_->[0]}",
            sectionname => $ConfigDefs::Courtside{$_->[0]}->{sectionname},
            type => $ConfigDefs::Courtside{$_->[0]}->{type} || 'text',
            options => $ConfigDefs::Courtside{$_->[0]}->{options} || '',
            firstoption => $ConfigDefs::Courtside{$_->[0]}->{firstoption} || '',
            compulsory => $ConfigDefs::Courtside{$_->[0]}->{compulsory} || 0,
            size  => ($ConfigDefs::Courtside{$_->[0]}->{type} eq 'lookup') ? '' : $ConfigDefs::Courtside{$_->[0]}->{size} || 40,
            maxsize => $ConfigDefs::Courtside{$_->[0]}->{maxsize} || 100,
            validate => $ConfigDefs::Courtside{$_->[0]}->{validate} || '',
            SkipAddProcessing => 1,
            SkipProcessing => 1,
        },
      ) } ( @ConfigDefsArray ) ), 
      intCourtsideType => {
        #label => ($intAllowSWOL and $sportID == 7) ? "Default Courtside Type" : '',
        label => ($intAllowSWOL and $ConfigDefsArray[0]) ? "Default Courtside Type" : '',
        value => $field->{intCourtsideType},
        type  => 'lookup',
        options => {1 => 'Stadium Scoring', 2 => 'Live Stats'},
        firstoption => ['',''],
        sectionname => 'courtside',
      },
			intSingleMatchCreditProductID=> {
        label => ($Data->{'SystemConfig'}{'AllowMatchCredits'}) ? "Default Single Qty Match Credit" : '',
        value => $field->{intSingleMatchCreditProductID},
        type  => 'lookup',
        options => $prods_vals,
        firstoption => ['','Choose a Match Credit Product'],
        sectionname => 'courtside',
      },
			intMatchCreditType => {
        label => ($Data->{'SystemConfig'}{'AllowMatchCredits'}) ? "Match Credit Type" : '',
        value => $field->{intMatchCreditType},
        type  => 'lookup',
        options => $matchCreditType,
        firstoption => ['','Choose a Match Credit Type'],
        sectionname => 'courtside',
      },

      strMatchDayReports => {
        label => $intAllowSWOL ? "Match Day Reports" : '',
        value => $field->{'strMatchDayReports'},
        type => 'lookup',
        sectionname => 'resultsentry',
				options => $matchdayreports_vals,
				order => $matchdayreports_order,
				class => 'chzn-select',
				multiple => 1,
      },
    },         
    order => [
      qw(
        strTitle 
        intRecStatus 
        strAbbrev 
        strCompAltName 
        strContact 
        intSeasonID 
        intNewSeasonID 
        intCompTypeID 
        intCompGender 
        intCompLevelID 
        intGradeID 
        intAgeGroupID 
        dtMinDOB 
        dtMaxDOB 
        dtStart 
        tmDefaultStartTime 
        intMatchDuration 
        intVenueRequiredMins 
        intPercentageOfVenue 
        intNumTeams 
        intNumRounds 
        intMatchInterval 
        intNominations 
        intOrder 
        intNumFinalsEligibility 
        intPeriodLength
        intDisplayResults 
        intDisplayLadder 
        intUpload 
        strCompGrouping 
        intFixtureConfigID 
        intCompFixtureType 
        intLadderConfigID 
        intFinalsConfigID 
        intStatsConfigID 
        intRoundStatsConfigID 
        intTeamMatchStatsID 
        intPlayerStatsConfigID 
        strCompNotes 
        strCompUmpireCostCode 
        strCompUmpireTravelCode 
        strCompUmpirePayCode 
        strCompExpenseCode1 
        strCompExpenseCode2 
        strCompExpenseCode3 
        strCompExpenseCode4 
        strCompExpenseCode5 
        strCompExpenseCode6 
        strCompExpenseCode7 
        strCompExpenseCode8 
        strCompExpenseCode9 
        strCompExpenseCode10 
        strCompExpenseCode11 
        strCompExpenseCode12 
        strCompExpenseCode13 
        strCompExpenseCode14 
        strCompExpenseCode15 
        strCompAppointmentNote 
        DAYSRUN 
        intMon 
        intTue 
        intWed 
        intThu 
        intFri 
        intSat 
        intSun 
				intAllowClubTeamResultsEntry
        LOCKTEXT 
        intLockMatches 
        intLockDayOfWeek
        LOCKTEXT2
				intCourtsideType
				intMatchCreditType
				intSingleMatchCreditProductID
				strMatchDayReports
      ),
      ( map { (
        "EC_".$_->[0]
      ) } ( @ConfigDefsArray ) ),
    ],
    options => {
      abelsuffix => ':',
      hideblank => 1,
      target => $Data->{'target'},
      formname => 'n_form',
      LocaleMakeText => $Data->{'lang'},
      submitlabel => $submitLabel,
      introtext => $editIntroText,
      NNoHTML => 1,
      updateSQL => qq[
        UPDATE tblAssoc_Comp
        SET --VAL--
        WHERE intCompID=$compID
			],
      addSQL => qq[
        INSERT INTO tblAssoc_Comp
        (intAssocID, intFixtureType, --FIELDS-- )
        VALUES ($Data->{'clientValues'}{'assocID'}, $fixtureType, --VAL-- )
			],
      afteraddFunction => \&postCompAdd,
      afteraddParams => [$option, $Data, $Data->{'db'}, $assocSeasons],
      #afterupdateFunction => \&postCompEdit,
      #afterupdateParams => [$compID, $Data, $Data->{'db'}],
      auditFunction => \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Competition',
      ],
      auditEditParams => [
        $compID,
        $Data,
        'Update',
        'Competition',
      ],
      beforeaddFunction => \&preCompAdd,
      beforeaddParams => [$Data],
      afterupdateFunction => \&postCompUpdate,
      afterupdateParams => [$option,$Data,$Data->{'db'}, $compID],
      LocaleMakeText => $Data->{'lang'},
    },
    fieldtransform => {
        textcase => {
            strTitle => $field_case_rules->{'strTitle'} || '',
        }
    },
    sections => [ 
      ['main', 'Details'],
      ['grades','Type/Gender/Age/Order'],
      ['fixturing','Fixturing'],
      ['display', 'Website Display'],
      ['templates','Templates'],
      ['notes','Notes'], 
      ['days', "Days $Data->{'LevelNames'}{$Defs::LEVEL_COMP} Run"], 
      ['resultsentry', 'Results Entry'],
      ['lockmatches', 'Match Locking'], 
      ['umpire', qq[$Data->{'SystemConfig'}{'TYPE_NAME_3'} Allocation Configuration]],
      ['courtside', 'Courtside'],
    ],
    carryfields =>  {
      client => $client,
      a => $action,
      ftype => $fixtureType,
    },
  );

  my $resultHTML='';
  ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, '',$Data->{'db'});
	my $title=$field->{'strTitle'} || '';

  if ( $option eq 'edit' ) {
    my $statement =qq/
      SELECT strTitle
      FROM tblAssoc_Comp
      WHERE intCompID=$compID
    /;
    my $query = $Data->{'db'}->prepare($statement);
    $query->execute;
    $title = $query->fetchrow_array();
    $query->finish;
  }

  $title="Add New $Data->{'LevelNames'}{$Defs::LEVEL_COMP}" if $option eq 'add';
  my $chgoptions='';
  if (
      ($Data->{'clientValues'}{'authLevel'} >=$Defs::LEVEL_ASSOC && allowedAction($Data, 'co_e')) 
      && ($intAllowSWOL || (!$intAllowSWOL 
      && !$field->{intStarted}))
  ) {
    if ($option eq 'display')  {
      $chgoptions .= qq[<a href="$Data->{'target'}?client=$client&amp;a=FI_"><img src="images/fixture_importer.gif" border="0" alt="Fixture Importer" title="Fixture Importer"></a> ] unless ($compObj->numberMatches() or !$Data->{'SystemConfig'}{'AssocConfig'}{'allowFixtureImporter'});
      $chgoptions.=qq[
        <span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=CO_DTE">
        Edit $Data->{'LevelNames'}{$Defs::LEVEL_COMP}</a></span>
      ];
    }
    elsif ($option eq 'edit' &&  !param('HF_subbutact')) {
            $chgoptions.=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=CO_DEL" onclick="return confirm('Are you sure you want to delete this $Data->{'LevelNames'}{$Defs::LEVEL_COMP}');">Delete $Data->{'LevelNames'}{$Defs::LEVEL_COMP}</a></span> ] if $compObj->canDelete();
    }
  }
    
  $chgoptions = qq[
    <div class="changeoptions">
      $chgoptions
    </div>
  ] if $chgoptions;
    
  $title = $chgoptions.$title;
    
  $resultHTML = qq[<div class="warningmsg">This $Data->{'LevelNames'}{$Defs::LEVEL_COMP} has already started and cannot be modified.</div>$resultHTML] if $field->{'intStarted'} && !$intAllowSWOL;


  ### Show ResultHTML
  ## if a pool and added, then go to "Stage/Pool" setup
  ## $fixtureType
  if (
    $fixtureType == $Defs::FIXTURE_TYPE_POOLS 
    and $Data->{'clientValues'}{'compID'} > 0 
    and param('HF_subbutact') 
    and $option eq 'add'
  ) {
      $resultHTML = Comp_PoolsStages::stagePoolWizard($Data, $compID || $Data->{'clientValues'}{'compID'}, 1);
      $title='';
  }       
	return ($resultHTML,$title);
}

sub loadCompDetails {
  my($db, $id) = @_;
	return {} if !$id;
  my $statement=qq[
    SELECT *,DATE_FORMAT(dtStart,"%d/%m/%Y") AS dtStart
    FROM tblAssoc_Comp
    WHERE intCompID=$id
  ];
  my $query = $db->prepare($statement);
  $query->execute;
  my $field=$query->fetchrow_hashref();
  $query->finish;
  foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
  return $field;
}

sub postCompAdd {
  my ($id, $params, $action, $Data, $db, $assocSeasons) = @_;
  return undef if !$db;
  maintain_courtside_data($db, $id, $params);
  if ($action eq 'add') {
    {
      my $cl=setClient($Data->{'clientValues'}) || '';
      my %cv=getClient($cl);
      $cv{'compID'}=$id;
      $cv{'currentLevel'} = $Defs::LEVEL_COMP;
      $Data->{'clientValues'}{'compID'}=$id || 0;
      my $clm=setClient(\%cv);
	    my $st = qq[
		    UPDATE tblAssoc_Comp 
		    SET intNewSeasonID = $assocSeasons->{'currentSeasonID'} 
		    WHERE intCompID = $id 
			    AND intAssocID = $Data->{'clientValues'}{'assocID'} 
			    AND intNewSeasonID = 0
	    ];
	    $Data->{'db'}->do($st);
	    addBubble(
		    $Data,
		    $Data->{'clientValues'}{'assocID'},
		    0,
		    1,
		    $id,
	    );
      return (0,qq[
        <div class="OKmsg"> $Data->{'LevelNames'}{$Defs::LEVEL_COMP} Added Successfully</div><br>
        <a href="$Data->{'target'}?client=$clm&amp;a=CO_HOME">Display Details for $params->{'d_strTitle'}</a><br><br>
        <b>or</b><br><br>
        <a href="$Data->{'target'}?client=$cl&amp;a=CO_ADD&amp;l=$Defs::LEVEL_COMP">Add another $Data->{'LevelNames'}{$Defs::LEVEL_COMP}</a>
      ]);
    } 
  }
}

sub preCompAdd {

	 my($params, $Data) = @_;
  	return undef if !$Data->{'db'};

	my $seasonID = $params->{'d_intNewSeasonID'} || 0;
	my $st = qq[
		SELECT 
			intLocked
		FROM 
			tblSeasons
		WHERE 
			intSeasonID = $seasonID
	];
    	my $qry= $Data->{'db'}->prepare($st);
    	$qry->execute();

	my $locked = $qry->fetchrow_array() || 0;

	if ($locked)	{
      		return (1,qq[ <div class="warningmsg"> $Data->{'LevelNames'}{$Defs::LEVEL_COMP} Cannot be added - Season has been Locked</div><br>]);
	}
}

sub postCompUpdate {
  my($id, $params, $action, $Data, $db, $compID) = @_;
  return undef if !$db;
  $compID ||= $id || 0;
  $Data->{'cache'}->delete('swm',"CompObj-$compID") if $Data->{'cache'};
  maintain_courtside_data($db, $compID, $params);
}

sub getCompTeams {
    my($Data,$compID) = @_;
    
     my @Teams = ();
    
    my $dbh = $Data->{db};
    my $query = qq[
                   SELECT tblTeam.*, intTeamNum FROM tblTeam
                   INNER JOIN tblComp_Teams USING (intTeamID)
                   WHERE tblComp_Teams.intCompID = $compID
                   AND tblComp_Teams.intRecStatus = $Defs::RECSTATUS_ACTIVE ORDER BY intTeamNum
                   ];
    
    my $sth = $dbh->prepare($query);
    $sth->execute();
    
    while (my $dref = $sth->fetchrow_hashref()) {
        my %team = ();
        foreach my $field( keys %{$dref}) {
            $team{$field} = $dref->{$field};
        }
        push (@Teams, \%team);
    }
    
    return \@Teams;
}

sub deleteComp {
    my ($Data, $compID,$client) = @_;
    
    
    my $dbh = $Data->{db};
    my $assocID = $Data->{clientValues}{assocID};
  	$client=setClient($Data->{'clientValues'}) || '';
    
    my $compObj = new CompObj('ID'=>$compID, assocID=>$assocID, db=>$dbh);
    my $result = $compObj->delete();
    
    my $resultHTML = '';
    if ($result && $result !~/^ERROR/) {
        $resultHTML .= qq[<p class="OKmsg">$Data->{'LevelNames'}{$Defs::LEVEL_COMP} successfully deleted.</p>];
    }
    else {
        $resultHTML .= qq[<p class="warningmsg">Unable to delete $Data->{'LevelNames'}{$Defs::LEVEL_COMP}.</p>];
    }

    $resultHTML .= qq[<p><a href="$Data->{'target'}?client=$client&amp;a=CO_L">Click here</a> to return to list of $Data->{'LevelNames'}{$Defs::LEVEL_COMP . '_P'}</p>];
    
    return $resultHTML;
    
    
    
}

sub postCompEdit {
    my ($id, $params, $compID, $Data, $dbh) = @_;

    my ($key, $value) = ('','');
    
    my $st = qq[
      INSERT INTO tblAssoc_Comp_Courtside (
        intCompID,
        strKey,
        strValue
      )
      VALUES (
        ?,
        ?,
        ?
      )
      ON DUPLICATE KEY UPDATE
        strValue = ? 
    ];
    my $q = $dbh->prepare($st);
    $q->execute($compID, $key, $value, $value);

    # Update all future comp matches to the comp match time.
    #my $match_time = $params->{d_tmDefaultStartTime};
    #my $update = qq[
    #  UPDATE 
    #    tblCompMatches 
    #  SET 
    #    dtMatchTime  = CONCAT(DATE(dtMatchTime), ' ', ?)
    #  WHERE 
    #    intCompID = $compID
    #    AND dtMatchTime > NOW()
    #];
    #my $sth = $dbh->prepare($update);
    #$sth->bind_param(1,$match_time);
    #$sth->execute();

    return;
}

sub newCompPage {
	my ($Data, $client)=@_;

	my $unesc_c = unescape($client);
	my $body = qq[
		<div class="sectionheader">Which type of competition do you wish to create?</div>

		<form action ="$Data->{'target'}" method="POST">
			<input type="hidden" name="a" value="CO_DTA">
			<input type="hidden" name="l" value="$Defs::LEVEL_COMP">
			<input type="hidden" name="client" value="$unesc_c">
			<input type="hidden" name="ftype" value="0">

			<input type="submit" value="Home and Away" style="float:left;width:200px;margin-top:5px;" class = "button generic-button">

<p  style="margin-left:230px;">The Home and Away competition type should be selected when the teams in the competition alternate between playing a game at their home venue one week and then at the opponents ground the following week. This is the common format for club based sports such as Australian Football, Rugby League and Hockey.</p>

			<br>
		</form>
		<form action ="$Data->{'target'}" method="POST">
			<input type="hidden" name="a" value="CO_DTA">
			<input type="hidden" name="l" value="$Defs::LEVEL_COMP">
			<input type="hidden" name="client" value="$unesc_c">
			<input type="hidden" name="ftype" value="1">

			<input type="submit" value="Venue Allocation" style="float:left;width:200px;margin-top:5px;" class = "button generic-button">

<p style="margin-left:230px;">The Venue Allocation competition type should be selected when matches for one or more competitions need to be allocated to specific times on specific courts or at certain venues and these allocations then remain in place throughout the entire season. This format is commonly used by team based sports such as basketball and indoor sporting complex competitions such as Futsal.</p>
		</form>
	];
	$body .= qq[
        <br>
		<form action ="$Data->{'target'}" method="POST">
			<input type="hidden" name="a" value="CO_DTA">
			<input type="hidden" name="l" value="$Defs::LEVEL_COMP">
			<input type="hidden" name="client" value="$unesc_c">
			<input type="hidden" name="ftype" value="2">

			<input type="submit" value="Pools Competition" style="float:left;width:200px;margin-top:5px;" class = "button generic-button">

<p style="margin-left:230px;">The Pools competition should be selected where the competition is broken into more than one group (or 'Pool'). It also allows for multiple phases of pools to be created (e.g. initial Pools phase followed by Finals), as well as the creation of progression rules governing which teams advance between Pool phases and into Finals.</p>
		</form>

	] unless ($Data->{'SysteConfig'}{'HidePools'});
	return ($body, 'Add a New Competition');
}

# DISPLAY A LIST OF ALL Comps
sub listComps {

  my($Data) = @_;

  my $resultHTML = '';
  my $client = unescape($Data->{client});

  my $statement=qq[
    SELECT 
			intFixtureType,
			intCompID, 
			strTitle,  
			strContact, 
			intCompTypeID, 
			intCompGender, 
			strAbbrev, 
			tblAssoc_Comp.intRecStatus, 
			tblAssoc_Comp.intNewSeasonID,
			S.strSeasonName , 
			Seasons.strName as OldSeasonName,
			strCompGrouping,
			tblAssoc_Comp.intAgeGroupID,
			AG.strAgeGroupDesc,
			intOrder
    FROM tblAssoc_Comp
      LEFT JOIN tblDefCodes as Seasons ON (tblAssoc_Comp.intSeasonID = Seasons.intCodeID)
      LEFT JOIN tblSeasons as S ON (S.intSeasonID = tblAssoc_Comp.intNewSeasonID)
      LEFT JOIN tblAgeGroups AS AG ON (AG.intAgeGroupID = tblAssoc_Comp.intAgeGroupID)
    WHERE tblAssoc_Comp.intAssocID = ?
      AND tblAssoc_Comp.intRecStatus <> $Defs::RECSTATUS_DELETED
    ORDER BY 
			strCompGrouping,
			intOrder, 
			strTitle
  ];
  my @fixtureTypes = ('Home and Away','Venue Allocation','Pools Competition');
  my $query = $Data->{'db'}->prepare($statement);
  $query->execute($Data->{'clientValues'}{'assocID'});

  my %tempClientValues = getClient($client);
	my @rowdata = ();
  while (my $dref= $query->fetchrow_hashref()) {
    setClientValue(\%tempClientValues, $Defs::LEVEL_COMP, $dref->{intCompID});
    $tempClientValues{currentLevel} = $Defs::LEVEL_COMP;
    my $tempClient = setClient(\%tempClientValues);

		push @rowdata, {
			id => $dref->{'intCompID'} || 0,
			intFixtureType => $fixtureTypes[$dref->{'intFixtureType'}] || 0,
			strTitle => $dref->{'strTitle'} || '',
			SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=CO_HOME",
			strAbbrev => $dref->{'strAbbrev'} || '',
			intSeasonID => $dref->{'intNewSeasonID'} || '',
			strSeasonName => $dref->{'strSeasonName'} || '',
			OldSeasonName => $dref->{'OldSeasonName'} || '',
			strContact => $dref->{'strContact'} || '',
			strCompGrouping => $dref->{'strCompGrouping'} || '',
			intOrder => $dref->{'intOrder'} || '',
			intUpload => $dref->{'intOrder'} ? 1 : 0,
			intRecStatus => $dref->{'intRecStatus'} || 0,
			intAgeGroupID => $dref->{'intAgeGroupID'} || 0,
			strAgeGroupDesc => $dref->{'strAgeGroupDesc'} || '',
		};
  }

  my $type=$Data->{'clientValues'}{'currentLevel'};
  my $title="$Data->{'LevelNames'}{$Defs::LEVEL_COMP.'_P'} in $Data->{'LevelNames'}{$type}";

	my $assocObj = getInstanceOf($Data, 'assoc', $Data->{'clientValues'}{'assocID'});

  my ($intAllowSWOL, $intAllowSeasons) = $assocObj->getValue(['intSWOL', 'intAllowSeasons']);


  my $rectype_options=show_recordtypes($Data, $Defs::LEVEL_COMP) || '';
	my $txt_SeasonName= $Data->{'SystemConfig'}{'txtSeason'} || 'Season';
	my $fieldlabels =getFieldLabels($Data, $Defs::LEVEL_COMP);

	my @headers = (
		{
      type => 'Selector',
      field => 'SelectLink',
		},
		{
			name => 	$fieldlabels->{'strTitle'} || 'Name',
			field => 	'strTitle',
		},
		{
			name => 	$fieldlabels->{'Competition Type'} || 'Competition Type',
			field => 	'intFixtureType',
			width => 30,
		},
		{
			name => 	$fieldlabels->{'strAbbrev'} || 'Abbreviation',
			field => 	'strAbbrev',
			width => 30,
		},
		{
			name => 	$txt_SeasonName || 'Season',
			field => 	$intAllowSeasons ? 'strSeasonName' : 'OldSeasonName',
			width => 50,
		},
		{
			name => 	$fieldlabels->{'strCompGrouping'} || 'Grouping',
			field => 	'strCompGrouping',
			width => 50,
		},
		{
			name => 	$fieldlabels->{'strAgeGroupDesc'} || 'Age Group',
			field => 	'strAgeGroupDesc',
			width => 50,
		},
		{
			name => 	$fieldlabels->{'strContact'} || 'Contact',
			field => 	'strContact',
		},
		{
			name => 	$fieldlabels->{'intRecStatus'} || 'Status',
			field => 	'intRecStatus',
			editor => 'checkbox',
			type => 'tick',
			width => 25,
		},
		{
			name => 	$fieldlabels->{'intUpload'} || 'Upload',
			field => 	'intUpload',
			editor => 'checkbox',
			type => 'tick',
			width => 25,
		},
	);
	my $list_instruction= $Data->{'SystemConfig'}{"ListInstruction_$Defs::LEVEL_COMP"} 
		? qq[<div class="listinstruction">$Data->{'SystemConfig'}{"ListInstruction_$Defs::LEVEL_COMP"}</div>] 
		: '';

  my $filterfields = [
    {
      field => 'strTitle',
      elementID => 'id_textfilterfield',
      type => 'regex',
    },
    {
      field => 'intSeasonID',
      elementID => 'dd_seasonfilter',
      allvalue => '-99',
    },
    {
      field => 'intRecStatus',
      elementID => 'dd_actstatus',
      allvalue => '2',
    },
    {
      field => 'intAgeGroupID',
      elementID => 'dd_ageGroupfilter',
      allvalue => '-99',
		},
  ];

	my $grid  = showGrid(
		Data => $Data,
		columns => \@headers,
		rowdata => \@rowdata,
		gridid => 'grid',
		width => '100%',
		height => 700,
		filters => $filterfields,
		client => $client,
		#saveurl => 'save.cgi',
  );

	$resultHTML = qq[ 
		$list_instruction
		<div class="grid-filter-wrap">
			$rectype_options
			$grid
		</div>
	];

	my $addCopyRegradeComp = '';
  if ($Data->{'clientValues'}{'authLevel'} >=$Defs::LEVEL_ASSOC and allowedAction($Data, 'co_a')) {
      my $addlink = $intAllowSWOL
        ? "$Data->{'target'}?client=$client&amp;a=CO_ADD&amp;l=$Defs::LEVEL_COMP"
        : "$Data->{'target'}?client=$client&amp;a=CO_DTA&amp;l=$Defs::LEVEL_COMP";
      $addCopyRegradeComp .= qq[<div class="changeoptions">];
      $addCopyRegradeComp .=qq[<span class = "button-small generic-button"><a href="$addlink">New</a></span>];
      $addCopyRegradeComp .= qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=COPYCOMP_DTA">Copy</a></span>] if $intAllowSWOL;
      $addCopyRegradeComp .= qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=REGRADE_CONFIG">Regrade</a></span>] if $intAllowSWOL;
      $addCopyRegradeComp .= qq[</div>];
  }
  $title = $addCopyRegradeComp.$title if $addCopyRegradeComp;



  return ($resultHTML,$title);

}


sub maintain_courtside_data {
  my ($db, $compID, $params) = @_;
  foreach my $key (keys %{$params}) {
    next unless ($key =~ /d_EC_/);
    my $value = $params->{$key};
    $key =~ s/d_EC_//;
    my $st = qq[
      INSERT INTO tblAssoc_Comp_Courtside (
        intCompID,
        strKey,
        strValue
      )
      VALUES (
        ?,
        ?,
        ?
      )
      ON DUPLICATE KEY UPDATE
        strValue = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($compID, $key, $value, $value);
  }
}

1;

