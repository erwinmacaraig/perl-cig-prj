#
# $Header: svn://svn/SWM/trunk/web/Reports/ReportAdvanced_AwardsRndByRnd.pm 8251 2013-04-08 09:00:53Z rlee $
#

package Reports::ReportAdvanced_AwardsRndByRnd;

use strict;
use lib ".","comp","../comp";
use ReportAdvanced_Common;
use Reports::ReportAdvanced;
use Reg_common;
use FormHelpers;
use CGI qw(param);
our @ISA =qw(Reports::ReportAdvanced);
use Awards qw(getAwardsIDsNames loadAwardDetails);


use strict;

sub _getConfiguration {
	my $self = shift;

	my $currentLevel = $self->{'EntityTypeID'} || 0;
	my $Data = $self->{'Data'};
	my $SystemConfig = $self->{'SystemConfig'};
	my $clientValues = $Data->{'clientValues'};

  my $natnumname=$SystemConfig->{'NationalNumName'} || 'National Number';

	my $AssocComps = AssocObj->getComps($Data,$clientValues->{assocID},1);
	my $AssocCompsOrdered = CompObj->groupOrderComps($self->{'db'}, [keys %{$AssocComps}]);
	$AssocComps->{0} = "Please select a $Data->{LevelNames}{$Defs::LEVEL_COMP}";
	unshift(@{$AssocCompsOrdered},0);

	my $Awards = getAwardsIDsNames($Data);
	my @AwardsOrdered = ();
	foreach my $id (sort {lc($Awards->{$a}) cmp lc($Awards->{$b})} keys %{$Awards}) {
			push @AwardsOrdered, $id;
	}
	$Awards->{0} = 'Please select an Award';
	unshift(@AwardsOrdered,0);

	my $comps = drop_down(
		'_EXTcompID',
		$AssocComps,
		$AssocCompsOrdered,
		$AssocCompsOrdered->[0],
		1,
		0,
		''
	);

	my $awards= drop_down(
		'_EXTawardID',
		$Awards,
		\@AwardsOrdered,
		$AwardsOrdered[0],
		1,
		0,
		''
	);


	my $preblock = qq[
<div style="margin:10px 0px;font-weight:bold;"> 
	<table>
		<tr>
			<td class="label">Select competition</td>
			<td>$comps</td>
		</tr>
		<tr>
			<td class="label">Select award</td>
			<td>$awards</td>
		</tr>
		<tr>
			<td class="label">Award Password</td>
			<td><input type="text" name="_EXTapwd"></td>
		</tr>
	</table>
</div>
	];

	my %config = (
		Name => 'Awards Rounds By Round',

		StatsReport => 0,
		MemberTeam => 0,
		ReportEntity => 1,
		ReportLevel => 0,
		Template => 'default_adv',
    TemplateEmail => 'default_adv_CSV',
		DistinctValues => 1,
    SQLBuilder => \&SQLBuilder,
    PreBlock => $preblock,

		Fields => {

			strNationalNum => [
				 $natnumname,
				{
					display=>'text',
					fieldtype=>'text',
					dbfield=>'tblMember.strNationalNum',
				},
		  ],
			Firstname => [
				 'First name',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					dbfield=>'tblMember.strFirstname',
					active=>1
				},
			],
			Surname => [
				'Family Name',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					dbfield=>'tblMember.strSurname',
					active=>1
				},
			 ],
			dtDOB => [
				'Date of Birth',
				{
					displaytype=>'text',
					fieldtype=>'date',
					allowsort=>1,
					dbfield=>'tblMember.dtDOB',
          dbformat=>' DATE_FORMAT(tblMember.dtDOB, "%d/%m/%Y")',
					active=>1
				},
			],
			TeamName=> [
				$currentLevel >= $Defs::LEVEL_CLUB ? "$Data->{'LevelNames'}{$Defs::LEVEL_TEAM} Name" : '',
				{
					displaytype=>'text',
					fieldtype=>'text',
					allowsort=>1,
					dbfield => 'GROUP_CONCAT(DISTINCT TEAM.strName ORDER BY intRoundNumber DESC)',
					#active=> 1
				},
			],
			intRoundNumber=> [
			 'Round Number',
			  {
					displaytype=>'text',
					fieldtype=>'text',
					size=> 2,
					#displaytype=>'lookup',
					#fieldtype=>'dropdown',
					#dropdownoptions=>{map { $_ => $_ } ('',1..30)},
					#dropdownorder=>['',1..30],
					#defaultvalue => [0,"Select Round"],
					filteronly=>1,
				},
			 ],

		},

		Order => [qw(
			strNationalNum 
			Firstname 
			Surname 
			dtDOB 
			TeamName
			intRoundNumber
		)],
    OptionGroups => {
      default => ['Details',{}],
    },

		Config => {
			FormFieldPrefix => 'c',
			FormName => 'rpform_',
			EmailExport => 1,
			limitView  => 5000,
			EmailSenderAddress => $Defs::admin_email,
			SecondarySort => 1,
			RunButtonLabel => 'Run Report',
		},
	);
	$self->{'Config'} = \%config;
}

sub SQLBuilder  {
  my($self, $OptVals, $ActiveFields) =@_ ;
  my $currentLevel = $self->{'EntityTypeID'} || 0;
  my $Data = $self->{'Data'};
  my $clientValues = $Data->{'clientValues'};
  my $SystemConfig = $Data->{'SystemConfig'};

  my $from_levels = $OptVals->{'FROM_LEVELS'};
  my $from_list = $OptVals->{'FROM_LIST'};
  my $where_levels = $OptVals->{'WHERE_LEVELS'};
  my $where_list = $OptVals->{'WHERE_LIST'};
  my $current_from = $OptVals->{'CURRENT_FROM'};
  my $current_where = $OptVals->{'CURRENT_WHERE'};
  my $select_levels = $OptVals->{'SELECT_LEVELS'};

  my $sql = '';
  { #Work out SQL

		my $awardID = param('_EXTawardID') || $ActiveFields->{'_EXTawardID'} || 0;
		$awardID =~ /^(\d+)$/;
		$awardID=$1;
		return ('', 'No Award Selected') if !$awardID;

		my $compID = param('_EXTcompID') || $ActiveFields->{'_EXTcompID'} || 0;
		$compID =~ /^(\d+)$/;
		$compID=$1;
		return ('', 'No Competition Selected') if !$compID;
		my $assocID=getAssocID($Data->{'clientValues'});

   # We want to report up to and including this round.
    #$where_list =~s/intRoundNumber\s+=/intRoundNumber <=/;
		my @where_list = split /AND/, $where_list;
		my $round_where = '';
		$where_list = '';
		for my $w (@where_list)	{
			if($w =~/intRoundNumber/)	{
				$round_where .= ' AND '.$w;
			}
			else	{
				$where_list .=' AND ' if $where_list;
				$where_list .= $w;
			}

		}

    my $awardPWD = param('_EXTapwd') || $ActiveFields->{'_EXTapwd'} || '';

    if ($awardID)   {
       my $ok = checkAwardPWD($self->{'db'}, $awardID, $awardPWD);
       return ('','Invalid Password') if ! $ok;
    }

		my $rounds_query =qq[
			SELECT intRoundID,intRoundNumber,intRoundTypeID,strRoundName
			FROM tblCompRounds
			WHERE intCompID = ?
				AND intRecStatus <> -1
				$round_where
			ORDER BY intRoundTypeID,intRoundNumber
    ];

    my $sth = $self->{'db'}->prepare($rounds_query);
    $sth->execute($compID);

    $self->{'Config'}{'Fields'}{'Total'}=['Total',{displaytype=>'text', fieldtype=>'text', allowsort=>1}];
    $ActiveFields->{'Total'}=1;

		push @{$self->{'Config'}{'Order'}}, 'Total';
		push @{$self->{'RunParams'}{'Order'}}, 'Total';
		push @{$self->{'Config'}{'Labels'}}, ['Total', "Total"];

    my $rounds = '';
    my $maxRoundNo = param('intRoundNumber_1') || 0;

    while (my ($id,$number,$type,$name) = $sth->fetchrow_array()) {
			my $roundNumber = '';
			my $roundName = '';
			if ($type == $Defs::COMP_ROUND_FINALS) {
					$roundNumber = 'f' .$number;
					$roundName = $name;
			}
			else {
					$roundNumber = 'r' .$number;
					$roundName = "Round $number";
			}
			$rounds .= qq[SUM(IF(tblCompRounds.intRoundID = $id,intVotes,0)) AS $roundNumber, ];
			$self->{'Config'}{'Fields'}{$roundNumber}=[$roundName,{displaytype=>'text', fieldtype=>'text'}];
			$ActiveFields->{$roundNumber}=1;
			push @{$self->{'Config'}{'Order'}}, $roundNumber;
			push @{$self->{'RunParams'}{'Order'}}, $roundNumber;
			push @{$self->{'Config'}{'Labels'}}, [$roundNumber, $roundName];
			last if $maxRoundNo == $number;
    }

    my $extra_where = '';
    if ($currentLevel == $Defs::LEVEL_CLUB) {
      $extra_where .= qq[AND CLUB.intClubID = $Data->{clientValues}{clubID}];
    }

    if ($currentLevel == $Defs::LEVEL_TEAM) {
      $extra_where .= qq[AND TEAM.intTeamID = $Data->{clientValues}{teamID}];
    }

    if ($currentLevel > $Defs::LEVEL_ASSOC || $currentLevel < $Defs::LEVEL_TEAM) {
    	return ('','Not allowed at this login');
    }

    if ($where_list ne '') {
      $where_list = 'AND ' . $where_list;
    }

    $where_list =~s/AND\s*$//;

		my $compWHERE = '';
		if ($compID)	{
			$compWHERE = qq[ AND CM.intCompID = $compID ];
		}
		#my $teamGroupBy = '';
		#if ($ActiveFields->{'TeamName'} == 1) {
		#	$teamGroupBy = qq[, PA.intTeamID];
		#}
		$round_where =~ s/GROUP_CONCAT\(DISTINCT TEAM.strName ORDER BY intRoundNumber DESC\)/TEAM.strName/g;
    $sql = qq[
			SELECT SUM(intVotes) AS Total, $rounds ###SELECT###
			FROM tblCompPlayerAwards AS PA
				INNER JOIN tblCompAwards ON (tblCompAwards.intAwardID = PA.intAwardID)
				INNER JOIN tblCompMatches AS CM ON (CM.intMatchID = PA.intMatchID)
				INNER JOIN tblCompRounds ON (tblCompRounds.intRoundID = CM.intRoundID)
				INNER JOIN tblAssoc_Comp ON (tblAssoc_Comp.intCompID = CM.intCompID)
				INNER JOIN tblTeam AS TEAM ON (TEAM.intTeamID = PA.intTeamID)
				INNER JOIN tblClub AS CLUB ON (CLUB.intClubID = TEAM.intClubID)
				INNER JOIN tblMember ON (PA.intMemberID = tblMember.intMemberID)
			WHERE 1=1
				$where_list
				$extra_where
				$compWHERE
				$round_where
				AND tblCompAwards.intAssocID = $assocID
				AND CM.intRecStatus <> $Defs::RECSTATUS_DELETED
				AND tblCompRounds.intRecStatus<>-1
				AND PA.intAwardID = $awardID
			GROUP BY tblMember.intMemberID 
		];

    return ($sql,'');
  }
}

sub checkAwardPWD   {
	my ($db, $awardID, $pwd) = @_;
	$pwd ||= '';

	my $st = qq[
			SELECT
					strAwardPWD
			FROM
					tblCompAwards
			WHERE
					intAwardID=$awardID
	];
	my $qry = $db->prepare($st);
	$qry->execute();
	my $AwardPWD = $qry->fetchrow_array() || '';
	return 1 if ($AwardPWD eq $pwd or ! $AwardPWD);

	return 0;
}

1;
