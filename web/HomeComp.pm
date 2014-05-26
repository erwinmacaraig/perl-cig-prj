#
# $Header: svn://svn/SWM/trunk/web/HomeComp.pm 9007 2013-07-19 05:22:52Z dhanslow $
#

package HomeComp;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(showCompHome);
@EXPORT_OK =qw(showCompHome);

use lib "dashboard";

use strict;
use Reg_common;
use Utils;
use InstanceOf;

use Logo;
use TTTemplate;
use Notifications;
use FormHelpers;

sub showCompHome	{
	my ($Data, $compID)=@_;

	my $client = $Data->{'client'} || '';
	my $compObj = getInstanceOf($Data, 'comp');

	my $allowedit = allowedAction($Data, 'a_e') ? 1 : 0;
	my $notifications = [];

 my $subTypeSeasonOnly = $Data->{'SystemConfig'}->{'OnlyUseSubRealmSeasons'} ? '' : 'OR intRealmSubTypeID= 0';
  my $st_seasons=qq[ 
    SELECT intSeasonID, strSeasonName
		FROM tblSeasons 
		WHERE intRealmID = $Data->{'Realm'}
			AND (intAssocID = $Data->{'clientValues'}{'assocID'} OR intAssocID = 0)
			AND (intRealmSubTypeID = $Data->{'RealmSubType'} $subTypeSeasonOnly)
		ORDER BY intSeasonOrder
  ];
  my ($seasons_vals,$seasons_order)=getDBdrop_down_Ref($Data->{'db'},$st_seasons,'');

  my $st_grades=qq[ SELECT intAssocGradeID,strGradeDesc FROM tblAssoc_Grade WHERE intAssocID=$Data->{'clientValues'}{'assocID'} AND intRecStatus = $Defs::RECSTATUS_ACTIVE];

  my ($grades_vals,$grades_order)=getDBdrop_down_Ref($Data->{'db'},$st_grades,'');

  my $st_ageGroups =qq[ SELECT intAgeGroupID, strAgeGroupDesc FROM tblAgeGroups WHERE intRealmID = $Data->{'Realm'} and (intAssocID=$Data->{'clientValues'}{'assocID'} or intAssocID=0) and intRealmSubTypeID IN (0, $Data->{'RealmSubType'}) AND intRecStatus = $Defs::RECSTATUS_ACTIVE ];
  my ($ageGroups_vals,$ageGroups_order)=getDBdrop_down_Ref($Data->{'db'},$st_ageGroups,'');

	my %DefCodes=();
	{
			my $aID= $Data->{'clientValues'}{'assocID'} || -1;
			my $statement = qq[
		SELECT intType, intCodeID, strName
		FROM tblDefCodes
		WHERE intRealmID=$Data->{'Realm'}
			AND (intAssocID = $aID OR intAssocID = 0)
		AND intRecStatus != $Defs::RECSTATUS_DELETED
		];

		my $query = $Data->{'db'}->prepare($statement);
		$query->execute;
		while (my($intType, $intCodeID, $strName) = $query->fetchrow_array) {
				$DefCodes{$intType}{$intCodeID}=$strName || '';
		}
	}

	my $upcomingmatches = upcomingMatches($Data, $compObj);

	my $name = $compObj->name();
	my %TemplateData = (
		Name => $name,
		ReadOnlyLogin => $Data->{'ReadOnlyLogin'},
		EditDetailsLink => "$Data->{'target'}?client=$client&amp;a=CO_DTE",
		Notifications => $notifications,
		SeasonLabel => $Data->{'SystemConfig'}{'txtSeason'} || 'Season',
		TeamsLabel => $Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'},
		UpcomingMatches => $upcomingmatches,
		Details => {
			Active => $Data->{'lang'}->txt(($compObj->getValue('intRecStatus') || '') ? 'Yes' : 'No'),
			Abbrev => $compObj->getValue('strAbbrev') || '',
			strContact => $compObj->getValue('strContact') || '',
			Season => $seasons_vals->{$compObj->getValue('intNewSeasonID') || 0} || '',
			CompType => $DefCodes{-36}{$compObj->getValue('intCompTypeID') || 0} || '',
			CompLevel => $DefCodes{-21}{$compObj->getValue('intLevelTypeID') || 0} || '',
			Grade => $grades_vals->{$compObj->getValue('intGradeID') || 0} || '',
			AgeGroup => $ageGroups_vals->{$compObj->getValue('intAgeGroupID') || 0} || '',
			Gender => $Defs::genderInfo{$compObj->getValue('intCompGender') || 0} || '',

			NumTeams => $compObj->getValue('intNumTeams') || 0,
			NumRounds => $compObj->getValue('intNumRounds') || 0,
			MatchDuration => $compObj->getValue('intMatchDuration') || 0,
			StartDate => $compObj->getValue('dtStart') || 0,
			Notes => $compObj->getValue('strNotes') || 0,
		},
	);
	my $resultHTML = runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/comp.templ',
	);

  $Data->{'NoHeadingAd'} = 1;

	my $title = $name;
	return ($resultHTML, '');
}


sub upcomingMatches	{
	my (
		$Data,
		$compObj,
	) = @_;

	my $compID = $compObj->ID();
	my $assocID = getID($Data->{'clientValues'},$Defs::LEVEL_ASSOC) || return '';
	my $numTeams = $compObj->getValue('intNumTeams') || 0;
	my $limit = int($numTeams/2) + ($numTeams % 2);
	my $st=qq[
		SELECT
			M.intRoundID AS M_intRoundID,
			M.intAssocID AS M_intAssocID,
			M.intCompID AS M_intCompID,
			M.intCompPoolID AS M_intCompPoolID,
			M.intMatchID AS M_intMatchID,
			M.intMatchNum AS M_intMatchNum,
			M.strMatchName AS M_strMatchName,
			M.strMatchAbbrev AS M_strMatchAbbrev,
			M.dtMatchTime AS M_dtMatchTime,
			DATE_FORMAT(M.dtMatchTime,"%d/%m/%Y %h:%i") AS M_dtMatchTime_FMT,
			M.intVenueID AS M_intVenueID,
			M.intHomeTeamID AS M_intHomeTeamID,
			M.intAwayTeamID AS M_intAwayTeamID,
			HT.strName AS HomeTeam,
			AT.strName AS AwayTeam,
			V.strName AS VenueName
		FROM 
			tblCompMatches AS M 
				LEFT JOIN tblTeam AS HT 
					ON M.intHomeTeamID = HT.intTeamID
				LEFT JOIN tblTeam AS AT 
					ON M.intAwayTeamID = AT.intTeamID
				LEFT JOIN tblDefVenue AS V 
					ON M.intVenueID = V.intDefVenueID
		WHERE 
			M.intCompID = ?
			AND M.intAssocID = ?
			AND M.intRecStatus != $Defs::RECSTATUS_DELETED
			AND dtMatchTime>NOW()
		ORDER BY 
			M.dtMatchTime ASC,
			M.intMatchNum ASC
		LIMIT $limit
	];
	my $q = $Data->{'db'}->prepare($st);
	$q->execute($compID, $assocID);
	my @upcoming_matches = ();
	while (my $dref = $q->fetchrow_hashref())  {
		my %m = (
			datetime => $dref->{'M_dtMatchTime_FMT'} || '',
			hometeam => $dref->{'HomeTeam'} || 'Bye',
			awayteam => $dref->{'AwayTeam'} || 'Bye',
			venue => $dref->{'VenueName'} || '',
		);
		push @upcoming_matches, \%m;
	}
	return \@upcoming_matches,
}
1;

