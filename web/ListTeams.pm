#
# $Header: svn://svn/SWM/trunk/web/ListTeams.pm 10696 2014-02-14 03:41:12Z dhanslow $
#

package ListTeams;

## LAST EDITED -> 10/09/2007 ##

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(listTeams);
@EXPORT_OK = qw(listTeams);

use strict;
use CGI qw(param unescape escape);

use lib '.', "..";
use Defs;
use Reg_common;
use Utils;
use CGI;
use RecordTypeFilter;
use InstanceOf;
use GridDisplay;
use FieldLabels;

sub listTeams {
  my($Data, $teamID, $typeID, $action) = @_;
  my $resultHTML = '';
  my $client = $Data->{client};
  my $lang = $Data->{'lang'};
	my $type=$Data->{'clientValues'}{'currentLevel'};
	my $statement='';

  my $assocObj = getInstanceOf($Data, 'assoc', $Data->{'clientValues'}{'assocID'});

  my ($intAllowSWOL) = $assocObj->getValue(['intSWOL']);

	my $showTeamNo = 0;
  if($type == $Defs::LEVEL_CLUB)	{
		$statement=qq[
			SELECT 
        DISTINCT 
        tblTeam.intTeamID, 
				tblTeam.strName,
				tblAssoc_Comp.strTitle,
        tblTeam.strContact, 
        tblTeam.strPhone1, 
        tblTeam.strMobile, 
        tblTeam.strEmail, 
        tblTeam.intRecStatus,
        tblAssoc_Comp.intCompID, 
				S.intSeasonID,
        S.strSeasonName, 
				tblAssoc_Comp.intAgeGroupID,
				AG.strAgeGroupDesc,
        tblComp_Teams.intTeamFinancial
			FROM 
        tblTeam 
        LEFT JOIN tblComp_Teams ON (tblComp_Teams.intRecStatus !=-1 AND tblTeam.intTeamID = tblComp_Teams.intTeamID)
				LEFT JOIN tblAssoc_Comp ON (
          tblAssoc_Comp.intCompID = tblComp_Teams.intCompID 
          AND tblComp_Teams.intRecStatus = $Defs::RECSTATUS_ACTIVE 
          AND (tblAssoc_Comp.intRecStatus <> $Defs::RECSTATUS_DELETED or tblAssoc_Comp.intRecStatus IS NULL)
        )
				LEFT JOIN tblAgeGroups AS AG ON (AG.intAgeGroupID = tblAssoc_Comp.intAgeGroupID)
        LEFT JOIN tblSeasons as S ON (tblAssoc_Comp.intNewSeasonID= S.intSeasonID)
			WHERE 
        tblTeam.intClubID = $Data->{'clientValues'}{'clubID'}
				AND (tblComp_Teams.intCompID = tblAssoc_Comp.intCompID or tblComp_Teams.intCompID IS NULL  or tblAssoc_Comp.intCompID IS NULL)
				AND tblTeam.intRecStatus <> $Defs::RECSTATUS_DELETED
			ORDER BY
				tblTeam.strName
		];
	}
	elsif($type == $Defs::LEVEL_COMP)	{
	  $showTeamNo = 1;
		$statement=qq[
			SELECT 
        DISTINCT 
        tblTeam.intTeamID, 
        tblTeam.strName, 
        tblTeam.strContact, 
        tblTeam.strPhone1, 
        tblTeam.strMobile, 
        tblTeam.strEmail, 
        tblAssoc_Comp.intStarted, 
        tblAssoc_Comp.intNumTeams, 
        tblTeam.intRecStatus, 
        tblAssoc_Comp.intCompID, 
        tblComp_Teams.intTeamFinancial,
        tblComp_Teams.intTeamNum
			FROM 
        tblTeam 
        INNER JOIN tblComp_Teams ON (tblTeam.intTeamID = tblComp_Teams.intTeamID AND tblComp_Teams.intRecStatus !=-1)
				INNER JOIN tblAssoc_Comp ON tblAssoc_Comp.intCompID=tblComp_Teams.intCompID
			WHERE 
        tblComp_Teams.intCompID = $Data->{'clientValues'}{'compID'}
				AND (tblComp_Teams.intCompID = tblAssoc_Comp.intCompID or tblComp_Teams.intCompID IS NULL)
				AND (tblComp_Teams.intRecStatus = $Defs::RECSTATUS_ACTIVE or tblComp_Teams.intRecStatus IS NULL)
				AND (tblAssoc_Comp.intRecStatus <> $Defs::RECSTATUS_DELETED or tblAssoc_Comp.intRecStatus IS NULL)
				AND tblTeam.intRecStatus <> $Defs::RECSTATUS_DELETED
			ORDER BY tblTeam.strName, tblAssoc_Comp.intCompID DESC
		];
	}
	elsif($type == $Defs::LEVEL_ASSOC)	{
  		$statement=qq[
			SELECT 
        DISTINCT 
          tblTeam.intTeamID, 
          tblAssoc_Comp.strTitle,
					tblTeam.strName,
          tblTeam.strContact, 
          tblTeam.strPhone1, 
          tblTeam.strMobile, 
          tblTeam.strEmail, 
          tblTeam.intRecStatus,
          tblAssoc_Comp.intCompID, 
          S.intSeasonID,
          S.strSeasonName, 
					tblAssoc_Comp.intAgeGroupID,
					AG.strAgeGroupDesc,
					tblComp_Teams.intTeamFinancial
			FROM 
        tblTeam 
				LEFT JOIN tblComp_Teams ON (tblComp_Teams.intRecStatus !=-1 AND tblTeam.intTeamID = tblComp_Teams.intTeamID)
				LEFT JOIN tblAssoc_Comp ON (
          tblAssoc_Comp.intCompID = tblComp_Teams.intCompID 
          AND tblComp_Teams.intRecStatus = $Defs::RECSTATUS_ACTIVE
       AND (tblAssoc_Comp.intRecStatus <> -1 or tblAssoc_Comp.intRecStatus IS NULL)
 )
				LEFT JOIN tblAgeGroups AS AG ON (AG.intAgeGroupID = tblAssoc_Comp.intAgeGroupID)
        LEFT JOIN tblSeasons as S ON (tblAssoc_Comp.intNewSeasonID= S.intSeasonID)
			WHERE
	(tblAssoc_Comp.intRecStatus <> $Defs::RECSTATUS_DELETED or tblAssoc_Comp.intCompID IS NULL)
 
        AND tblTeam.intAssocID = $Data->{'clientValues'}{'assocID'}
				AND (tblComp_Teams.intCompID = tblAssoc_Comp.intCompID or tblComp_Teams.intCompID IS NULL or tblAssoc_Comp.intCompID IS NULL)
				AND tblTeam.intRecStatus <> $Defs::RECSTATUS_DELETED
      ];

      if ($intAllowSWOL) {
        $statement .= qq[ ORDER BY  tblAssoc_Comp.intCompID, tblTeam.strName ASC];
      }
      else {
        $statement .= qq[ ORDER BY tblTeam.strName, tblAssoc_Comp.intCompID DESC];
      }
	}
	my $query = $Data->{'db'}->prepare($statement);
	$query->execute;
  my $found = 0;
	my %tempClientValues = getClient($client);
	my $currentname='';
	my $addteam=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=T_DTA&amp;l=$Defs::LEVEL_TEAM">Add</a></span>] if allowedAction($Data, 't_a');
  my $assignteams = qq[
    <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=T_CAS&amp;l=$Defs::LEVEL_TEAM">Manage $Data->{'LevelNames'}{$Defs::LEVEL_TEAM .'_P'} in  $Data->{'LevelNames'}{$Defs::LEVEL_COMP}
    </a></span>
  ] if(allowedAction($Data, 't_a') and $tempClientValues{currentLevel}==4 and $tempClientValues{'compID'} > 0); 
	my $rectype_options = show_recordtypes($Data, $Defs::LEVEL_TEAM);
	my %lookupfields=(
	  intRecStatus => {
			$Defs::RECSTATUS_ACTIVE => 'Y',
			$Defs::RECSTATUS_INACTIVE => 'N',
		},
		intTeamFinancial => {
		  1 => 'Y',
			0 => 'N',
		},
	);
	my %CheckBoxFields=(
	  intRecStatus=> $Defs::RECSTATUS_ACTIVE,
		intTeamFinancial=> 1,
	);
	my $numTeams=0;
	my $intStarted=0;
	my %teamInComp=();
	my $showTeamFinancial = 0;
	my @rowdata = ();
	while (my $dref= $query->fetchrow_hashref()) {
		$dref->{intCompID} ||= 0;
		$dref->{intTeamNo} ||= 0;
		$teamInComp{$dref->{intTeamID}} =1 if ($dref->{intTeamID} and $dref->{intCompID});
		next if (exists $teamInComp{$dref->{intTeamID}} and ! $dref->{intCompID});
		next if !$dref->{strName};
		$dref->{strSeasonName} ||= '';
		$dref->{strPhone1} ||= $dref->{strMobile};
		$numTeams=$dref->{'intNumTeams'} || 0;
		$intStarted=$dref->{'intStarted'} || 0;
		$found++;
		setClientValue(\%tempClientValues, $Defs::LEVEL_TEAM, $dref->{intTeamID});
		setClientValue(\%tempClientValues, $Defs::LEVEL_COMP, $dref->{intCompID});
		$tempClientValues{currentLevel} = $Defs::LEVEL_TEAM;
		my $tempClient = setClient(\%tempClientValues);

    push @rowdata, {
      id => $dref->{'intTeamID'}.$found || 0,
      intTeamID => $dref->{'intTeamID'} || '',
      strName => $dref->{'strName'} || '',
      SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=T_HOME",
			strContact => $dref->{'strContact'} || '',
			strPhone1 => $dref->{'strPhone1'} || '',
			strEmail => $dref->{'strEmail'} || '',
			strSeasonName => $dref->{'strSeasonName'} || '',
			intSeasonID => $dref->{'intSeasonID'} || '',
			intTeamNum => $dref->{'intTeamNum'} || '',
			intTeamFinancial => $dref->{'intTeamFinancial'} || 0,
			intRecStatus => $dref->{'intRecStatus'} || 0,
			intAgeGroupID => $dref->{'intAgeGroupID'} || 0,
			strAgeGroupDesc => $dref->{'strAgeGroupDesc'} || '',
			strTitle => $dref->{'strTitle'} || '',
		};
	}
	$addteam='' if($numTeams and $found >= $numTeams);
	$addteam='' if $intStarted;
  $assignteams = '' if ($intStarted and !$Data->{'SystemConfig'}{'AssocConfig'}{'AlwaysAllowManageTeamsInComp'});
  my $title=$lang->txt('[_1] in [_2]', $Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'}, $Data->{'LevelNames'}{$type});
  my $modoptions;
  if ($type == $Defs::LEVEL_COMP) {
		$addteam = '';
	}
	$modoptions=qq[<div class="changeoptions">$addteam $assignteams</div>]; 
  $title=$modoptions.$title;
	my $list_instruction= $Data->{'SystemConfig'}{"ListInstruction_$Defs::LEVEL_TEAM"} ? qq[<div class="listinstruction">$Data->{'SystemConfig'}{"ListInstruction_$Defs::LEVEL_TEAM"}</div>] : '';

  my $fieldlabels =getFieldLabels($Data, $Defs::LEVEL_TEAM);
	
  my @headers = (
    {
      type => 'Selector',
      field => 'SelectLink',
    },
    {
      name =>   $fieldlabels->{'strName'} || $Data->{'lang'}->txt('Name'),
      field =>  'strName',
    },
    {
      name =>   $Data->{'lang'}->txt('Competition'),
      field =>  'strTitle',
			hide => ($type == $Defs::LEVEL_COMP)
    },
    {
      name =>   $fieldlabels->{'strSeasonName'} || $Data->{'lang'}->txt('Season'),
      field =>  'strSeasonName',
			hide => ($type == $Defs::LEVEL_COMP),
			width => 50,
    },
    {
      name =>   $Data->{'lang'}->txt('Age Group'),
      field =>  'strAgeGroupDesc',
			hide => ($type == $Defs::LEVEL_COMP),
			width => 50,
    },
    {
      name =>   $fieldlabels->{'strContact'} || $Data->{'lang'}->txt('Contact'),
      field =>  'strContact',
    },
    {
      name =>   $fieldlabels->{'strEmail'} || $Data->{'lang'}->txt('Email'),
      field =>  'strEmail',
    },
    {
      name =>   $fieldlabels->{'strPhone'} || $Data->{'lang'}->txt('Phone'),
      field =>  'strPhone1',
			width => 30,
    },
		{
			name =>   $Data->{'lang'}->txt('Number'),
			field =>  'intTeamNum',
			hide => !$showTeamNo,
			sorttype => 'number',
			width => 20,
		},
	);
	my %rstatus = (
      name =>   $Data->{'lang'}->txt('Active'),
      field =>  'intRecStatus',
      type => 'tick',
			width => 25,
	);
	if(allowedAction($Data, 't_e'))	{
		$rstatus{'editor'}  = 'checkbox';
	}
	push @headers, \%rstatus;
	
	if($showTeamFinancial)	{
		my %tf = (
			name =>   $Data->{'lang'}->txt('Financial'),
			field =>  'intTeamFinancial',
      type => 'tick',
		);
		if(allowedAction($Data, 't_e'))	{
			$tf{'editor'}  = 'checkbox';
		}
		push @headers, \%tf;
	}

  my $filterfields = [
    {
      field => 'strTitle',
      elementID => 'id_textfilterfield',
      type => 'regex',
    },
    {
      field => 'intRecStatus',
      elementID => 'dd_actstatus',
      allvalue => '2',
    },
  ];
	if($type != $Defs::LEVEL_COMP)	{
		push @{$filterfields}, {
      field => 'intAgeGroupID',
      elementID => 'dd_ageGroupfilter',
      allvalue => '-99',
    };
		push @{$filterfields}, {
			field => 'intSeasonID',
			elementID => 'dd_seasonfilter',
			allvalue => '-99',
		};
	}

  my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@rowdata,
    gridid => 'grid',
    width => '99%',
    height => 700,
    filters => $filterfields,
    client => $client,
    saveurl => 'ajax/aj_grid_update.cgi',
		ajax_keyfield => 'intTeamID',
    saveaction => 'edit_stat_team',
  );


	$resultHTML = qq[ 
		<div class="grid-filter-wrap">
			<div style="width:99%;">$rectype_options</div>
			$list_instruction
			$grid
		</div>
	];
  return ($resultHTML,$title);
}

1;

