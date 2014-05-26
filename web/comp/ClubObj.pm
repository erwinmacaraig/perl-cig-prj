#
# $Header: svn://svn/SWM/trunk/web/comp/ClubObj.pm 10816 2014-02-26 03:54:50Z cgao $
#

package ClubObj;
use BaseAssocObject;
our @ISA =qw(BaseAssocObject);

use strict;
use DBI;
use Data::Dumper;

sub new {

  my $this = shift;
  my $class = ref($this) || $this;
  my %params=@_;


  my $self ={};
  ##bless selfhash to class
  bless $self, $class;

  #Set Defaults
  $self->{'db'}=$params{'db'};
  $self->{'ID'}=$params{'ID'};
  $self->{'assocID'}=$params{'assocID'};
  return undef if !$self->{'db'};
  return undef if !$self->{'assocID'};
  return undef if $self->{'assocID'} !~ /^\d+$/;
  return undef if($self->{'ID'} and $self->{'ID'} !~ /^\d+$/);

  ##return the blessed hash
  return $self;
}

sub load	{
  my $self = shift;
  my $options = shift;
  

  my $st=qq[
		SELECT *
		FROM tblClub
		WHERE intClubID = ?
	];
  my $q = $self->{'db'}->prepare($st);
  $q->execute($self->{'ID'});
	if($DBI::err)	{
		$self->LogError($DBI::err);
	}
	else	{
		$self->{'DBData'}=$q->fetchrow_hashref();
        if ($options->{'venues'}) {
            $self->{DBData}{Veu}
        }
	}
}

sub _load_venues {

}

sub realmID {
    my $self = shift;
    my $dbh = $self->{db};
    
    my $assocID  = $self->assocID();
    
    if (!defined($self->{realmID})) {
        my ($realmID) = $dbh->selectrow_array(qq[SELECT intRealmID FROM tblAssoc WHERE intAssocID = $assocID]);
        $self->{realmID} = $realmID;
    }

    return $self->{realmID};
}


sub AllClubPlayers {
    my $self = shift;
    my $seasonID = shift;
    my $dbh = $self->{db};
    my $assocID = $self->assocID();
    my $clubID = $self->ID();
    
    my $realm = $self->realmID();
    my $tblMemberSeasons = 'tblMember_Seasons_' . $realm;

    my $query = qq[
                SELECT DISTINCT
                    tblMember.intMemberID,
                    tblMember_Clubs.intStatus,
                    strSurname,strFirstname
                FROM
                    tblMember
                    INNER JOIN tblMember_Associations ON (tblMember_Associations.intMemberID=tblMember.intMemberID)
                    INNER JOIN tblMember_Clubs LEFT JOIN tblMember_Clubs as mc ON (mc.intMemberID = tblMember.intMemberID
                        AND mc.intClubID = $clubID AND mc.intStatus = $Defs::RECSTATUS_ACTIVE  AND mc.intPermit = 0)
                    INNER JOIN $tblMemberSeasons as Seasons ON (Seasons.intMemberID = tblMember.intMemberID
                                        AND Seasons.intAssocID = tblMember_Associations.intAssocID AND Seasons.intMSRecStatus = $Defs::RECSTATUS_ACTIVE)
                WHERE
                    tblMember.intStatus <> $Defs::RECSTATUS_DELETED
                    AND tblMember.intRealmID = $realm
                    AND tblMember_Clubs.intStatus > $Defs::RECSTATUS_DELETED
                    AND (mc.intStatus > $Defs::RECSTATUS_DELETED OR mc.intStatus IS NULL)
                    AND tblMember_Clubs.intClubID = $clubID
                    AND tblMember.intMemberID=tblMember_Clubs.intMemberID
                    AND tblMember_Associations.intAssocID = $assocID
                    AND Seasons.intClubID = $clubID AND Seasons.intSeasonID = $seasonID
                ];
    my $sth = $dbh->prepare($query);
    $sth->execute() or query_error($sth);
    my %Players = ();
    while (my ($player,$status,$firstname,$surname) = $sth->fetchrow_array()) {
        # Small number of players have multiple records for the same club with different status.
        if (exists ($Players{$player})) {
            if ($status == 1) {
                $Players{$player}->{status} = 1;
            }
        }
        else {
            $Players{$player} = {status=>$status,type=>'player'};
        }
        $Players{$player}->{firstname} = $firstname;
        $Players{$player}->{surname} = $surname;
    }
    $sth->finish();
    return \%Players;
}
sub playersNotClearedOut {
    my $self = shift;
    my $seasonID = shift;
    my $dbh = $self->{db};
    my $assocID = $self->assocID();
    my $clubID = $self->ID();

    my $realm = $self->realmID();
    my $tblMemberSeasons = 'tblMember_Seasons_' . $realm;

    my $query = qq[
                SELECT DISTINCT
                    tblMember.intMemberID,
                    tblMember_Clubs.intStatus,
                    strSurname,strFirstname
                FROM 
                    tblMember 
                    INNER JOIN tblMember_Associations ON (tblMember_Associations.intMemberID=tblMember.intMemberID)
                    INNER JOIN tblMember_Clubs LEFT JOIN tblMember_Clubs as mc ON (mc.intMemberID = tblMember.intMemberID
                        AND mc.intClubID = $clubID AND mc.intStatus=$Defs::RECSTATUS_ACTIVE  AND mc.intPermit=0)
                    INNER JOIN $tblMemberSeasons as Seasons ON (Seasons.intMemberID = tblMember.intMemberID
                                        AND Seasons.intAssocID = tblMember_Associations.intAssocID AND Seasons.intMSRecStatus = $Defs::RECSTATUS_ACTIVE)
                    LEFT JOIN tblMember_ClubsClearedOut as clear on( clear.intMemberID = tblMember.intMemberID AND clear.intClubID = $clubID
                                        AND clear.intAssocID = $assocID AND clear.intCurrentSeasonID = $seasonID )
                WHERE 
                    tblMember.intStatus <> $Defs::RECSTATUS_DELETED
                    AND tblMember.intRealmID = $realm
                    AND tblMember_Clubs.intStatus > $Defs::RECSTATUS_DELETED
                    AND (mc.intStatus > $Defs::RECSTATUS_DELETED OR mc.intStatus IS NULL)
                    AND tblMember_Clubs.intClubID = $clubID
                    AND tblMember.intMemberID = tblMember_Clubs.intMemberID
                    AND tblMember_Associations.intAssocID = $assocID
                    AND Seasons.intClubID = $clubID AND Seasons.intSeasonID = $seasonID
                    AND clear.intClearanceID IS NULL
                ];
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my %Players = ();
    while (my ($player,$status,$firstname,$surname) = $sth->fetchrow_array()) {
        # Small number of players have multiple records for the same club with different status.
        if (exists ($Players{$player})) {
            if ($status == 1) {
                $Players{$player}->{status} = 1;
            }
        }
        else {
            $Players{$player} = {status=>$status,type=>'player'};
        }
        $Players{$player}->{firstname} = $firstname;
        $Players{$player}->{surname} = $surname;
    }
    $sth->finish();
    #print STDERR Dumper(\%Players);
    return \%Players;
};

sub activeNonPlayers {
    my $self = shift;
    my $seasonID = shift;

    my $dbh = $self->{db};
    my $assocID = $self->assocID();
    my $clubID = $self->ID();

    my ($realm) = $dbh->selectrow_array(qq[SELECT intRealmID FROM tblAssoc WHERE intAssocID = $assocID]);
    my $tblMemberSeasons = 'tblMember_Seasons_' . $realm;

    my $query = qq[
                   SELECT mc.intMemberID, mc.intStatus, strSurname, strFirstname
                   FROM tblMember_Clubs AS mc
                   INNER JOIN tblMember AS m ON (m.intMemberID = mc.intMemberID)
                   WHERE mc.intMemberID IN (
                                            SELECT intMemberID
                                            FROM $tblMemberSeasons
                                            WHERE intClubID = $clubID
                                            AND intAssocID = $assocID
                                            )
                   AND (m.intOfficial = 1 OR m.intMisc = 1 OR m.intCoach = 1 OR m.intMisc = 1 OR m.intVolunteer = 1 )
                   AND mc.intClubID = $clubID
                   AND mc.intStatus = $Defs::RECSTATUS_ACTIVE                   
                   AND m.intStatus != $Defs::RECSTATUS_DELETED
                   ];
                                            #AND intSeasonID = $seasonID

    my $sth = $dbh->prepare($query);
    $sth->execute();

    my %NonPlayers = ();
    while (my ($nonplayer,$status,$surname, $firstname) = $sth->fetchrow_array()) {
        if (exists ($NonPlayers{$nonplayer})) {
            if ($status == 1) {
                $NonPlayers{$nonplayer}->{status} = 1;
            }
        }
        else {
            $NonPlayers{$nonplayer} = {type=>'nonplayer', status=>$status};
        }
       
        $NonPlayers{$nonplayer}->{firstname} = $firstname;
        $NonPlayers{$nonplayer}->{surname} = $surname;
    
    }
    $sth->finish();
    return \%NonPlayers;
}

sub copyMemberToNewClub {
    my $self = shift;
    my ($memberID, $data, $toClubID, $toClubAssocID,$seasonID,$toSeasonID,$params) = @_;

    my $dbh = $self->{db};
    my $clubID = $self->ID();
    my $assocID = $self->assocID();


    my ($realmID) = $dbh->selectrow_array(qq[SELECT intRealmID FROM tblAssoc WHERE intAssocID = $toClubAssocID]);
    my $memberSeasonsTable = 'tblMember_Seasons_' . $realmID;

    
    #
    # Start of Association updates
    #
    
    if ($assocID != $toClubAssocID) {
        # Add a reocord to tblMember_Associations if club in different assoc.
        $dbh->do(qq[
                    INSERT INTO tblMember_Associations
                    (intMemberID,intAssocID,intRecStatus)
                    VALUES
                    ($memberID, $toClubAssocID, $Defs::RECSTATUS_ACTIVE)
                     ON DUPLICATE KEY UPDATE tTimeStamp = NOW(),intRecStatus = $Defs::RECSTATUS_ACTIVE
                    ]);
        
        # Mark as intActive in assoc they're leaving.
        if (!$params->{'ActiveOldAssoc'}) {
            $dbh->do(qq[
                   UPDATE tblMember_Associations
                   SET intRecStatus = $Defs::RECSTATUS_INACTIVE
                   WHERE intMemberID = $memberID
                   AND intAssocID = $assocID
               ]);

        }
            my $sth = $dbh->prepare(qq[
                                   SELECT intTypeID,intSubTypeID
                                   FROM tblMember_Types
                                   WHERE intMemberID = $memberID
                                   AND intAssocID = $assocID
                                   AND intActive = $Defs::RECSTATUS_ACTIVE
                               ]);
            $sth->execute();
        
        my $sth_insert = $dbh->prepare(qq[
                                          INSERT INTO tblMember_Types
                                          (intMemberID,intAssocID,intTypeID,intSubTypeID,intActive, intRecStatus)
                                          VALUES($memberID,$toClubAssocID,?,?,$Defs::RECSTATUS_ACTIVE,$Defs::RECSTATUS_ACTIVE)
                                          ON DUPLICATE KEY UPDATE intActive = $Defs::RECSTATUS_ACTIVE, intRecStatus = $Defs::RECSTATUS_ACTIVE, tTimeStamp = NOW()
                                      ]);

        while (my($type,$subtype) = $sth->fetchrow_array()) {
            $sth_insert->execute($type,$subtype);
        }

    
        my ($currentSeasonAssocCount) = $dbh->selectrow_array(qq[SELECT COUNT(*) 
                                                        FROM $memberSeasonsTable
                                                        WHERE intMemberID = $memberID
                                                        AND intAssocID = $assocID
                                                        AND intClubID = 0
                                                        AND intSeasonID = $seasonID
                                                        AND intMSRecStatus != $Defs::RECSTATUS_DELETED]);
        
        my $playerStatus = 0;
        if ($data->{type} eq 'player' || $data->{playerofficial}) {
            $playerStatus = 1;
        }
        
        if ($currentSeasonAssocCount > 0) {
            my $dtInPlayer = "'NULL'";
            if ($data->{type} eq 'player' || $data->{playerofficial}) {
                $dtInPlayer = 'NOW()';
            }
            
            $dbh->do(qq[
                 INSERT INTO $memberSeasonsTable
                 (
                  intMemberID,
                  intAssocID,
                  intClubID,
                  intSeasonID,
                  intPlayerStatus,
                  dtInPlayer
                 )
                 VALUES(
                        $memberID,
                        $toClubAssocID,
                        0,
                        $toSeasonID,
                        $playerStatus,
                        $dtInPlayer
                 )
                 ON DUPLICATE KEY UPDATE tTimeStamp = NOW(), intMSRecStatus = 1
                   
          ]);
        }
        else {
            #print "Adding default Member_Seasons record for association.\n";
            $dbh->do(qq[INSERT INTO $memberSeasonsTable
                   (intMemberID,intSeasonID,intAssocID,intClubID, intPlayerStatus) 
                    VALUES
                   ($memberID, $toSeasonID, $toClubAssocID, 0, $playerStatus)]);
        }
    }   
    
    # 
    # End of Association updates.
    #


    #
    # Start of Club updates.
    #

    # Add a record to tblMember_Clubs

    my ($currentmemberClubCount) = $dbh->selectrow_array(qq[SELECT COUNT(*)
                                                        FROM tblMember_Clubs
                                                        WHERE intMemberID = $memberID
                                                        AND intClubID = $toClubID 
                                                        ]);

        my $playerStatus = 0;    
        my $status = $data->{status};
        if( $currentmemberClubCount > 0){
             $dbh->do(qq[
                UPDATE tblMember_Clubs
                SET intStatus = 1,
                    tTimestamp =NOW() 
                WHERE 
                    intMemberID = $memberID
                    AND intClubID = $toClubID
            ]);
        }else{
            $dbh->do(qq[
                INSERT INTO tblMember_Clubs
                (intMemberID,intClubID,intStatus)
                VALUES
                ($memberID,$toClubID,1)
            ]);
    }
    # Mark member as inactive in club they're leaving.
    if(!$params->{'ActiveOldAssoc'}){
        $dbh->do(qq[
                UPDATE tblMember_Clubs
                SET intStatus = $Defs::RECSTATUS_INACTIVE
                WHERE intMemberID = $memberID
                AND intClubID = $clubID
            ]);
    }
    # find the member season club in source association
    my ($seasonClubRecord) = $self->seasonClubRecord($memberID,$seasonID,$assocID,$clubID);
    
    #find the member season club intination if it' already there then just update the status
    my ($seasonClubRecord_inDestination) = $self->seasonClubRecord($memberID,$toSeasonID,$toClubAssocID,$toClubID);
    # Set the members active in destination club
    if($params->{'ActiveNewAssoc'}){
       $seasonClubRecord->{intMSRecStatus} =1; 
    }

    if ($seasonClubRecord and !$seasonClubRecord_inDestination) {
        if($seasonClubRecord_inDestination){
            #only update is needed
            my $update_st = qq[
                            UPDATE 
                                $memberSeasonsTable 
                            SET 
                                intMSRecStatus = $seasonClubRecord->{intMSRecStatus}
                            WHERE intMemberID = ?
                            AND intAssocID = ?
                            intClubID =?
                            intSeasonID =?                  
                        ];
            my $qry_update = $dbh->prepare($update_st);
            $qry_update->execute( $memberID,
                                  $toClubAssocID,
                                  $toClubID,
                                  $toSeasonID);
            
        }else{
            #insert new record
         
        my $insert = 
            qq[
               INSERT INTO $memberSeasonsTable
               (
                intMemberID,
                intAssocID,
                intClubID,
                intSeasonID,
                intMSRecStatus,
                intSeasonMemberPackageID,
                intPlayerStatus,
                intPlayerFinancialStatus,
                intCoachStatus,
                intCoachFinancialStatus,
                intUmpireStatus,
                intUmpireFinancialStatus,
                intMiscStatus,
                intMiscFinancialStatus,
                intVolunteerStatus,
                intVolunteerFinancialStatus,
                intOther1Status,
                intOther1FinancialStatus,
                intOther2Status,
                intOther2FinancialStatus,
                dtInPlayer,
                dtOutPlayer,
                dtInCoach,
                dtOutCoach,
                dtInUmpire,
                dtOutUmpire,
                dtInMisc,
                dtOutMisc,
                dtInVolunteer,
                dtOutVolunteer,
                dtInOther1,
                dtOutOther1,
                dtInOther2,
                dtOutOther2
                )
               VALUES 
               (
                $memberID,
                $toClubAssocID,
                $toClubID,
                $toSeasonID,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?
                )];
        
        my $sth = $dbh->prepare($insert);

        $sth->execute(
            $seasonClubRecord->{intMSRecStatus},
            $seasonClubRecord->{intSeasonMemberPackageID},
            $seasonClubRecord->{intPlayerStatus},
            $seasonClubRecord->{intPlayerFinancialStatus},
            $seasonClubRecord->{intCoachStatus},
            $seasonClubRecord->{intCoachFinancialStatus},
            $seasonClubRecord->{intUmpireStatus},
            $seasonClubRecord->{intUmpireFinancialStatus},
            $seasonClubRecord->{intMiscStatus},
            $seasonClubRecord->{intMiscFinancialStatus},
            $seasonClubRecord->{intVolunteerStatus},
            $seasonClubRecord->{intVolunteerFinancialStatus},
            $seasonClubRecord->{intOther1Status},
            $seasonClubRecord->{intOther1FinancialStatus},
            $seasonClubRecord->{intOther2Status},
            $seasonClubRecord->{intOther2FinancialStatus},
            $seasonClubRecord->{dtInPlayer},
            $seasonClubRecord->{dtOutPlayer},
            $seasonClubRecord->{dtInCoach},
            $seasonClubRecord->{dtOutCoach},
            $seasonClubRecord->{dtInUmpire},
            $seasonClubRecord->{dtOutUmpire},
            $seasonClubRecord->{dtInMisc},
            $seasonClubRecord->{dtOutMisc},
            $seasonClubRecord->{dtInVolunteer},
            $seasonClubRecord->{dtOutVolunteer},
            $seasonClubRecord->{dtInOther1},
            $seasonClubRecord->{dtOutOther1},
            $seasonClubRecord->{dtInOther2},
            $seasonClubRecord->{dtOutOther2}
        );
        
        }
    } # Add default season record. They don't have a record for the specified season to copy across. 
    else {
        #print "Adding default Member_Seasons record for club.\n";
        
        my $playerStatus = 0;
        if ($data->{type} eq 'player' || $data->{playerofficial}) {
            $playerStatus = 1;
        }
        
        #WHY ????? w add a seasonId 1 to memberSeason table???
        #$dbh->do(qq[INSERT INTO $memberSeasonsTable
        #           (intMemberID,intSeasonID,intAssocID,intClubID, intPlayerStatus) 
        #            VALUES
        #           ($memberID, 1, $toClubAssocID, $toClubID, $playerStatus)]);
    }
    if($params->{'ClearOut'}){
        my $query =qq[
                INSERT INTO tblMember_ClubsClearedOut
                (intMemberID,intRealmID,intAssocID,intClubID,intClearanceID,intCurrentSeasonID)
                VALUES
                ($memberID,$realmID,$assocID,$clubID,0,$seasonID)
                ON DUPLICATE KEY UPDATE tTimeStamp = NOW(), intCurrentSeasonID = $seasonID  ];
        my $sth = $dbh->prepare($query);
        $sth->execute();
        
    }
    return;
}

sub seasonClubRecord {
    my $self = shift;
    my ($memberID,$seasonID,$assocID, $clubID) = @_;
    
    return undef if !$seasonID;
    return undef if !$memberID;
    
    my $dbh = $self->{db};
    $clubID ||= $self->ID();
    $assocID ||= $self->assocID();
    
    my $memberSeasonsTable = 'tblMember_Seasons_' . $self->realmID();

    my $query = qq[
                   SELECT *
                   FROM $memberSeasonsTable
                   WHERE intMemberID = $memberID
                   AND intAssocID = $assocID
                   AND intClubID = $clubID
                   AND intSeasonID = $seasonID
                   AND intMSRecStatus != $Defs::RECSTATUS_DELETED
                   LIMIT 1
                   ];

    my ($hashref) = $dbh->selectrow_hashref($query);
    return $hashref;
    
}

# Returns a list of all teams that belong to a club.
sub getTeams {
    my $class = shift; 
    my ($Data, $club_id, $params) = @_;
    
    my $assoc_id = $Data->{clientValues}{assocID};
    
    my $not_in_comp_where = '';
    if ($params->{'not_in_comp'}) {
        $not_in_comp_where = qq[
                                AND tblTeam.intTeamID NOT IN 
                                (
                                 SELECT intTeamID 
                                 FROM tblComp_Teams
                                 INNER JOIN tblAssoc_Comp USING (intCompID)
                                 WHERE tblAssoc_Comp.intAssocID = $assoc_id 
                                 AND  tblComp_Teams.intRecStatus != $Defs::RECSTATUS_DELETED
                                )
                            ];
    }
    
    my $st = qq[
                   SELECT tblTeam.intTeamID, tblTeam.strName
                   FROM tblTeam
                   WHERE tblTeam.intClubID = ?
                   $not_in_comp_where
                   AND tblTeam.intRecStatus = $Defs::RECSTATUS_ACTIVE
           ];
    
    my $q = $Data->{db}->prepare($st);
    $q->execute($club_id);

    my %Teams = ();

    while (my $dref = $q->fetchrow_hashref()) {
        $Teams{$dref->{'intTeamID'}} = $dref->{'strName'};
   }

    return \%Teams;
    
}

1;
