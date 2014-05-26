#
# $Header: svn://svn/SWM/trunk/web/Stats.pm 10059 2013-12-01 22:45:16Z tcourt $
#

package Stats;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(displayStats);

use strict;

use lib '.', '..';

use Defs;
use Reg_common;

sub displayStats {
  my($action, $Data) = @_;
	$action||='';
  my $db=$Data->{'db'};
	my $SystemConfig=$Data->{'SystemConfig'};
	my %Statistics=();
	my $clientValues_ref=$Data->{'clientValues'};
	my $level=$Data->{'clientValues'}{'currentLevel'} || '';
	my %StatsConfig	= (
		$Defs::LEVEL_TOP=> [$Defs::LEVEL_INTERNATIONAL, 'International Body','Top'],
		$Defs::LEVEL_INTERNATIONAL=> [$Defs::LEVEL_INTREGION, 'International Region','International Body'],
		$Defs::LEVEL_INTREGION=> [$Defs::LEVEL_INTZONE, 'International Zone','International Region'],
		$Defs::LEVEL_INTZONE=> [$Defs::LEVEL_NATIONAL, 'National','International Zone'],
		$Defs::LEVEL_NATIONAL => [$Defs::LEVEL_STATE, 'States','National'],
		$Defs::LEVEL_STATE    => [$Defs::LEVEL_REGION, 'Regions','States'],
		$Defs::LEVEL_REGION   => [$Defs::LEVEL_ZONE, 'Zones','Regions'],
		$Defs::LEVEL_ZONE   => [$Defs::LEVEL_ASSOC, 'Assocs','Zones'],
	);
	my $id=getID($Data->{'clientValues'});
	if($level > $Defs::LEVEL_ASSOC)	{
		getNodeStats($db, $id, \%Statistics, \%StatsConfig, $level);
	}
	elsif ($level == $Defs::LEVEL_ASSOC) { 
		getAssocStats($db, $clientValues_ref->{assocID}, \%Statistics); 
	}
	for my $i (qw(TotalMembers TotalClubs TotalTeams Assocs TotalAssoc Zones TotalZones Regions TotalRegions))	{
		$Statistics{$i} ||= 0;
	}

    my $lang = $Data->{'lang'};
    my $active = $lang->txt('Active');
    my $inactive = $lang->txt('Inactive');
   
    my $resultHTML = qq[<table>];
     
    $resultHTML .= buildHTML(
        $lang,
        '',
        qq[<b>$active</b>],
        qq[<b>$inactive</b>]
    );

    $resultHTML .= buildHTML(
        $lang, 
        $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER.'_P'},
        $Statistics{TotalActiveMembers},
        $Statistics{TotalInactiveMembers}
    );

    $resultHTML .= buildHTML(
        $lang, 
        $Data->{'LevelNames'}{$Defs::LEVEL_CLUB.'_P'},
        $Statistics{TotalActiveClubs},
        $Statistics{TotalInactiveClubs}
    ) if !$SystemConfig->{'NoClubs'};


    $resultHTML .= buildHTML(
        $lang, 
        $Data->{'LevelNames'}{$Defs::LEVEL_TEAM.'_P'},
        $Statistics{TotalActiveTeams},
        $Statistics{TotalInactiveTeams}
    ).qq[<tr><td>&nbsp;</td></tr>] if !$SystemConfig->{'NoTeams'};


    for my $k (sort {$b <=> $a} keys %StatsConfig) {
        next if $k >= $level;
        my $n = $StatsConfig{$k}[2];
        my $tn = "Total$n";   
        if ($Statistics{$tn}) {
            $resultHTML .= buildHTML(
                $lang,
                $Data->{'LevelNames'}{$k.'_P'},
                $Statistics{$tn}.' ('.($lang->txt('of').' '.$Statistics{$tn}.')'),
                ''
            );
        }
    }

    $resultHTML .= buildHTML(
        $lang,
        $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC.'_P'},
        $Statistics{Assocs}.' ('.($lang->txt('of').' '.$Statistics{TotalAssocs}.')'),
        ''
    ) if $Statistics{TotalAssocs};

    $resultHTML .= qq[</table>];

    return ($resultHTML, $lang->txt('Statistics'));
}


sub buildHTML {
    my ($lang, $levelName, $active, $inactive) = @_;

    my $label = ($levelName)
        ? $lang->getNumberOf($levelName).':'
        : '';

    my $inactive2 = (length($inactive))
        ? qq[<td class="value">$inactive</td>]
        : '';

    my $result = qq[
        <tr>
            <td class="label">$label</td>
            <td class="value">$active</td>
            $inactive2
        </tr>
    ];

    return $result;
}


########################## FUNCTIONS ##########################





sub getAssocStats	{
	my ($db, $assocID, $stats_ref)=@_;
	$stats_ref->{TotalActiveMembers} ||= 0;
	$stats_ref->{TotalInactiveMembers} ||= 0;
	$stats_ref->{TotalAciveClubs} ||= 0;
	$stats_ref->{TotalInactiveClubs} ||= 0;
	$stats_ref->{TotalActiveTeams} ||= 0;
	$stats_ref->{TotalInactiveTeams} ||= 0;
	$stats_ref->{TotalActiveMembers}+=numActiveMembers($db, $assocID);
	$stats_ref->{TotalInactiveMembers}+=numInactiveMembers($db, $assocID);
	$stats_ref->{TotalActiveClubs}+=numActiveClubs($db, $assocID);
	$stats_ref->{TotalInactiveClubs}+=numInactiveClubs($db, $assocID);
	$stats_ref->{TotalActiveTeams}+=numActiveTeams($db, $assocID);
	$stats_ref->{TotalInactiveTeams}+=numInactiveTeams($db, $assocID);
}

sub numActiveMembers {
	my ($db, $assocID) = @_;
	my $statement = qq[
		SELECT COUNT(tblMember.intMemberID)
		FROM tblMember 
			INNER JOIN tblMember_Associations ON (
				tblMember.intMemberID=tblMember_Associations.intMemberID
				AND tblMember_Associations.intRecStatus = $Defs::RECSTATUS_ACTIVE)
		WHERE intAssocID=$assocID
			AND tblMember.intStatus <> $Defs::RECSTATUS_DELETED
		LIMIT 1
	];
	my $query = $db->prepare($statement);
	$query->execute;
	my ($numActiveMembers) = $query->fetchrow_array();
	$query->finish;
	$numActiveMembers||=0;
	return($numActiveMembers);
}

sub numInactiveMembers {
  my ($db, $assocID) = @_;
  my $statement = qq[
    SELECT COUNT(tblMember.intMemberID)
    FROM tblMember
      INNER JOIN tblMember_Associations ON (
        tblMember.intMemberID=tblMember_Associations.intMemberID
        AND tblMember_Associations.intRecStatus = $Defs::RECSTATUS_INACTIVE)
    WHERE intAssocID=$assocID
      AND tblMember.intStatus <> $Defs::RECSTATUS_DELETED
    LIMIT 1
  ];
  my $query = $db->prepare($statement);
  $query->execute;
  my ($numInactiveMembers) = $query->fetchrow_array();
  $query->finish;
  $numInactiveMembers||=0;
  return($numInactiveMembers);
}


sub numActiveClubs {
	my ($db, $assocID) = @_;
	my $statement = qq[
		SELECT COUNT(tblClub.intClubID)
		FROM tblClub INNER JOIN tblAssoc_Clubs ON (
			tblAssoc_Clubs.intClubID=tblClub.intClubID
				AND tblAssoc_Clubs.intRecStatus = $Defs::RECSTATUS_ACTIVE)
		WHERE intAssocID=$assocID
			AND tblClub.intRecStatus <> $Defs::RECSTATUS_DELETED
		LIMIT 1
	];
	my $query = $db->prepare($statement);
	$query->execute;
	my ($numActiveClubs) = $query->fetchrow_array();
	$query->finish;
	$numActiveClubs ||= 0;
	return($numActiveClubs);
}

sub numInactiveClubs {
  my ($db, $assocID) = @_;
  my $statement = qq[
    SELECT COUNT(tblClub.intClubID)
    FROM tblClub INNER JOIN tblAssoc_Clubs ON (
      tblAssoc_Clubs.intClubID=tblClub.intClubID
        AND tblAssoc_Clubs.intRecStatus = $Defs::RECSTATUS_INACTIVE)
    WHERE intAssocID=$assocID
      AND tblClub.intRecStatus <> $Defs::RECSTATUS_DELETED
    LIMIT 1
  ];
  my $query = $db->prepare($statement);
  $query->execute;
  my ($numInactiveClubs) = $query->fetchrow_array();
  $query->finish;
  $numInactiveClubs ||= 0;
  return($numInactiveClubs);
}

sub numActiveTeams {
	my ($db, $assocID) = @_;
	my $statement=qq[
		SELECT COUNT(intTeamID)
		FROM tblTeam
		WHERE intAssocID=$assocID
			AND tblTeam.intRecStatus = $Defs::RECSTATUS_ACTIVE
		LIMIT 1
	];
	#AND strTeamNo NOT IN (0,-1,-2,-3,-4) 
	my $query = $db->prepare($statement);
	$query->execute;
	my ($numActiveTeams) = $query->fetchrow_array();
	$query->finish;
	$numActiveTeams ||= 0;
	return($numActiveTeams);
}

sub numInactiveTeams {
  my ($db, $assocID) = @_;
  my $statement=qq[
    SELECT COUNT(intTeamID)
    FROM tblTeam
    WHERE intAssocID=$assocID
      AND tblTeam.intRecStatus = $Defs::RECSTATUS_INACTIVE
    LIMIT 1
  ];
  #AND strTeamNo NOT IN (0,-1,-2,-3,-4)
  my $query = $db->prepare($statement);
  $query->execute;
  my ($numInactiveTeams) = $query->fetchrow_array();
  $query->finish;
  $numInactiveTeams ||= 0;
  return($numInactiveTeams);
}


sub numUniqueNumbers {
  my ($db, $SystemConfig) = @_;
  my $num_field=$SystemConfig->{'GenNumField'} || 'strNationalNum';
  my $statement = qq[
    SELECT COUNT(DISTINCT $num_field)
    FROM tblMember;
  ];
  #my $query = $db->prepare($statement);
  #$query->execute;
  #my ($numNumbers) = $query->fetchrow_array();
  #$query->finish;
  #$numNumbers||=0;
  #return($numNumbers);
	return 0;
}

sub getNodeStats {
	my ($db, $id, $stats_ref, $StatsConfig, $level)=@_;
	my $lowerlevel=$StatsConfig->{$level}[0];
	my $lowerlevelname=$StatsConfig->{$level}[1];
	my $statement = qq[
		SELECT intNodeID, intDataAccess, intStatusID
		FROM tblNode AS N INNER JOIN tblNodeLinks AS NL ON (N.intNodeID=NL.intChildNodeID)
		WHERE NL.intParentNodeID = $id
			AND N.intTypeID=$lowerlevel
	];
	if($lowerlevel==$Defs::LEVEL_ASSOC)	{ 
		$statement=qq[
			SELECT tblAssoc.intAssocID, tblAssoc.intDataAccess, $Defs::NODE_SHOW
			FROM tblAssoc INNER JOIN tblAssoc_Node ON (tblAssoc_Node.intAssocID=tblAssoc.intAssocID)
			WHERE tblAssoc_Node.intNodeID = $id
				AND intDataAccess IN ($Defs::DATA_ACCESS_FULL, $Defs::DATA_ACCESS_READONLY, $Defs::DATA_ACCESS_STATS)
		];
	}
	$stats_ref->{$lowerlevelname}||=0;
	$stats_ref->{"Total$lowerlevelname"}||=0;
	my $query = $db->prepare($statement);
	$query->execute;
	while (my ($dbID, $dataaccess, $type) = $query->fetchrow_array()) {
		$stats_ref->{"Total$lowerlevelname"}++ if $type !=$Defs::NODE_HIDE;
		if(!defined $dataaccess)	{ $dataaccess = $Defs::DATA_ACCESS_FULL;}
		if($dataaccess >$Defs::DATA_ACCESS_NONE)	{
			$stats_ref->{$lowerlevelname}++ if $type !=$Defs::NODE_HIDE;
			if($lowerlevel==$Defs::LEVEL_ASSOC)	{ 
				getAssocStats($db, $dbID, $stats_ref); }
			else	{ 
				getNodeStats($db, $dbID, $stats_ref, $StatsConfig, $lowerlevel); 
			}
		}
	}
}

1;

