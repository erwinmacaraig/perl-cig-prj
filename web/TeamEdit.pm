package TeamEdit;


require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(availablePlayers selectedPlayers updatePlayers);
@EXPORT_OK = qw(availablePlayers selectedPlayers updatePlayers);

use strict;
use warnings;

use lib ".","..", "../..";
use Utils;
use Seasons;
use AuditLog;
use Log;

sub availablePlayers {
    my ($params) = @_;
    my ($Data, $assocID, $compID, $clubID, $teamID, $fields_ref) = @{$params}{qw(data assocID compID clubID teamID fields_ref)};
    
    my $db = $Data->{'db'};

    if (!$clubID){
        my $club_id_lookup_stmt = 'SELECT intClubID from tblTeam where intTeamID =?';
        my $club_id_lookup_query = $db->prepare($club_id_lookup_stmt);
        $club_id_lookup_query->execute($teamID);
        if (my $dref = $club_id_lookup_query->fetchrow_hashref()){
            $clubID = $dref->{'intClubID'} || 0;
        }
    }

    my $seasonID = $fields_ref->{'seasonFilter'}; 
    my $ageGroupID = $fields_ref->{'ageGroupFilter'};
    my $genderID = $fields_ref->{'genderFilter'};
    my $unassigned_only = $fields_ref->{'unassigned_only'};
    my $toDOB;
    my $fromDOB;
    
    if ($fields_ref->{'dobTo'}){
        $toDOB = formatDate($fields_ref->{'dobTo'}) || '';
    }
    
    if ($fields_ref->{'dobFrom'}){
        $fromDOB = formatDate($fields_ref->{'dobFrom'}) || '';
    }

    my $MS_tablename = "tblMember_Seasons_$Data->{'Realm'}";

    my $season_JOIN = qq[
                    
    ];
    my $club_WHERE = '';
    my $gender_WHERE = '';
    my @where_clause;
    
    if ($genderID && ($genderID == $Defs::GENDER_MALE || $genderID == $Defs::GENDER_FEMALE ) ){
        push @where_clause, "M.intGender = $genderID";
    }

    my $statement = qq[
        SELECT M.intMemberID, strMemberNo, M.strFirstName, M.strSurname, DATE_FORMAT(M.dtDOB, '%Y%m%d'), MS.intSeasonID, MS.intPlayerAgeGroupID, DATE_FORMAT(M.dtDOB, '%d/%m/%Y') as FormattedDOB
        FROM tblMember as M
        left JOIN $MS_tablename as MS ON (MS.intMemberID = M.intMemberID
                            AND MS.intAssocID = $assocID AND MS.intMSRecStatus = 1)
    ];
    if ($clubID and $clubID > 0) {
        $statement .= qq[ INNER JOIN tblMember_Clubs as MC ON (MC.intMemberID = M.intMemberID and MC.intClubID = $clubID and MC.intStatus = $Defs::RECSTATUS_ACTIVE ) ];
        push @where_clause, "MS.intClubID = $clubID";
    }
    if ($assocID and $assocID > 0) {
        $statement .= qq[ INNER JOIN tblMember_Associations as MA ON (MA.intMemberID = M.intMemberID and MA.intAssocID = $assocID AND MA.intRecStatus=$Defs::RECSTATUS_ACTIVE) ];
    }
    else{ 
        return qq[UNABLE]; 
    }
    
    if (@where_clause){
        $statement .= 'WHERE ' . join(' AND ', @where_clause);
    }
    
    my $query = $db->prepare($statement) or query_error($statement);
    $query->execute or query_error($statement);

    my %all_players;
    my @Players;

    while( my ($DB_intMemberID, $DB_strMemberNo, $DB_strFirstname,$DB_strSurname, $DB_DOB, $DB_intSeasonID, $DB_intAgeGroupID, $DB_DOBFormat) = $query->fetchrow_array())  {
        $DB_intSeasonID ||= 0;
        $DB_intAgeGroupID ||= 0;

        my $mnum=$DB_strMemberNo ? " ($DB_strMemberNo)" : '';
        $DB_DOBFormat = ($DB_DOBFormat and $DB_DOBFormat ne '00/00/0000') ? qq[$DB_DOBFormat] : '';

        $all_players{$DB_intMemberID}{'name'}=$DB_strSurname . ", " . $DB_strFirstname;
        $all_players{$DB_intMemberID}{'familyname'}=$DB_strSurname;
        $all_players{$DB_intMemberID}{'firstname'}=$DB_strFirstname;
        $all_players{$DB_intMemberID}{'dob'} = $DB_DOB;
        $all_players{$DB_intMemberID}{'dobFormatted'} = $DB_DOBFormat;
        $all_players{$DB_intMemberID}{'seasons'}{$DB_intSeasonID}{'in_season'} = 1;
        $all_players{$DB_intMemberID}{'ageGroups'}{$DB_intAgeGroupID} = $DB_intSeasonID;
        $all_players{$DB_intMemberID}{'dob'} =~s/\-//g;
        
    }
    $query->finish;
    
    # Do we want team history as well?
    if ( $clubID && $unassigned_only ){
        my $team_history_sql = qq[
            SELECT MS.intMemberID,
                   MS.intSeasonID,
                   MT.intTeamID
            FROM $MS_tablename AS MS
            INNER JOIN tblAssoc_Comp AS AC ON ( MS.intAssocID = AC.intAssocID
                                               AND MS.intSeasonID = AC.intNewSeasonID
                                               AND AC.intRecStatus = $Defs::RECSTATUS_ACTIVE)
            INNER JOIN tblMember_Teams AS MT ON ( AC.intCompID = MT.intCompID
                                                 AND MT.intMemberID = MS.intMemberID
                                                 AND MT.intStatus = $Defs::RECSTATUS_ACTIVE)
            WHERE MS.intMSRecStatus = $Defs::RECSTATUS_ACTIVE
              AND MS.intClubID = ?       
        ];
        
        my @values = ($clubID);
        
        if ( $seasonID && $seasonID > 0){
            $team_history_sql .= qq[  AND MS.intSeasonID = ?];
            push @values, $seasonID;
        }
        
        my $team_history_stmt = $db->prepare($team_history_sql) or query_error($team_history_sql);
        $team_history_stmt->execute(@values) or query_error($team_history_sql);
        
        while( my $dref = $team_history_stmt->fetchrow_hashref())  {
            next if ($dref->{'intTeamID'} == $teamID); # skip the team we are messing with
            
            my $intMemberID = $dref->{'intMemberID'};
            
            if ( !defined  $all_players{$intMemberID} ){
                #INFO "Could not find $intMemberID";
            }
            elsif ( !defined  $all_players{$intMemberID}{'seasons'} ){
                #INFO "Could not find seasons for $intMemberID";
            }
            elsif ( !defined  $all_players{$intMemberID}{'seasons'}{$dref->{'intSeasonID'}} ){
                #INFO "Could not find season $dref->{'intSeasonID'} for $intMemberID";
            }
            else{
                $all_players{$intMemberID}{'seasons'}{$dref->{'intSeasonID'}}{'teams'}{$dref->{'intTeamID'}} = 1;
            }
        }
        $team_history_stmt->finish;
        
    }
    
      
    PLAYER: foreach my $key (sort { uc($all_players{$a}{'name'}) cmp uc($all_players{$b}{'name'})} keys %all_players) {
        
        # Date of Birth To/From field restrictions
        $all_players{$key}{'dob'} ||= '';
        next if $fromDOB and $all_players{$key}{'dob'} < $fromDOB;
        next if $toDOB and $all_players{$key}{'dob'} > $toDOB;
        
        # Season Dropdown Restrictions
        # Limit to players to only the season or seasons we want 
        if ($seasonID) {
            if ($seasonID == -1 ) {
                next PLAYER if defined $all_players{$key}{'seasons'};
            }
            elsif ($seasonID == -99) {
                #do nothing
            }
            elsif ($seasonID and  ! defined $all_players{$key}{'seasons'}{$seasonID})  {
                next PLAYER;
            }
        }
        
        # Age Group Dropdown Restrictions
        # Limit to players to only the age group in the selected season we want 
        if ($ageGroupID) {
            if ($ageGroupID == -1)    {
                next PLAYER if defined $all_players{$key}{'ageGroups'}{$ageGroupID};
            }
            elsif ($ageGroupID == -99)    {
                #do nothing
            }
            elsif ($ageGroupID)   {
                if ($seasonID && ($seasonID != -99))    {
                    next PLAYER if (!exists($all_players{$key}{'ageGroups'}{$ageGroupID}));
                    next PLAYER if ($all_players{$key}{'ageGroups'}{$ageGroupID} != $seasonID);
                }
                else    {
                    next PLAYER if ! defined $all_players{$key}{'ageGroups'}{$ageGroupID};
                }
            }
        }
        
        # Unassigned Restrictions
        # Limit to players to only the age group in the selected season we want 
        if ($unassigned_only) {
            if ($seasonID == -1) {
                next PLAYER if defined $all_players{$key}{'seasons'};
            }
            elsif ($seasonID == -99) {
                #do nothing
                foreach my $temp_season_ID (keys %{$all_players{$key}{'seasons'}}){
                    next PLAYER if defined $all_players{$key}{'seasons'}{$temp_season_ID}{'teams'}; 
                }
            }
            elsif ($seasonID and defined $all_players{$key}{'seasons'}{$seasonID}{'teams'})  {
                next PLAYER;
            }
        }

        # Add the player to the list
        my %Player=(
            'id' => $key,
            'familyname' => $all_players{$key}{'familyname'},
            'firstname' => $all_players{$key}{'firstname'},
            'dob' => $all_players{$key}{'dob'},
            'dobFormatted' => $all_players{$key}{'dobFormatted'},
        );
        push @Players, \%Player;
    }
    return \@Players;
}


sub selectedPlayers{
    my ($params) = @_;
    my ($Data, $assocID, $compID, $clubID, $teamID, $fields_ref) = @{$params}{qw(data assocID compID clubID teamID fields_ref)};
    
    my $db = $Data->{'db'};

    my @bind_values;
    
    # We have a team
    push @bind_values, $teamID;
    
    # Restrict to a competition if we have one
    my $comp_where='';
    if ($compID and $compID > 0){
        $comp_where = qq[ and (MT.intCompID = ? ) ];
        push @bind_values, $compID;
    }else {
        $comp_where = qq[ and  MT.intCompID=0 ];
    }
    
    # And only active
    push @bind_values, $Defs::RECSTATUS_ACTIVE;
    
    # All the fun sql
    my $statement = qq[
        SELECT M.intMemberID,
               strMemberNo,
               M.strFirstName,
               M.strSurname,
               MT.intCompID,
               DATE_FORMAT(M.dtDOB, '%Y%m%d'),
               DATE_FORMAT(M.dtDOB, '%d/%m/%Y') as FormattedDOB
        FROM tblMember AS M
        INNER JOIN tblMember_Teams as MT ON (
               MT.intMemberID = M.intMemberID 
           AND MT.intTeamID = ?
           $comp_where
        )
        where MT.intStatus = ?
    ];

    my $query = $db->prepare($statement) or query_error($statement);
    $query->execute(@bind_values) or query_error($statement);

    my @Players=(); 

    my %all_players = ();
    while(my ($DB_intMemberID, $DB_strMemberNo, $DB_strFirstname,$DB_strSurname,$DB_comp, $DB_DOB, $DB_DOBFormat) = $query->fetchrow_array()) {
        $DB_DOBFormat = ($DB_DOBFormat and $DB_DOBFormat ne '00/00/0000') ? qq[$DB_DOBFormat] : '';

        my %Player=(
            'id' => $DB_intMemberID,
            'familyname' => $DB_strSurname,
            'firstname' => $DB_strFirstname,
            'dob' => $DB_DOB,
            'dobFormatted' => $DB_DOBFormat,
            'comp' => $DB_comp,
        );

        push @Players, \%Player;
    }
    $query->finish;

    return \@Players;
}

sub formatDate  {
  my($date)=@_;
    my ($day, $month, $year)=split /\//,$date;

    if (defined $year and $year ne '' and defined $month and $month ne '' and defined $day and $day ne '') {
        return '' if $day   !~/^\d+$/;
        return '' if $month !~/^\d+$/;
        return '' if $year  !~/^\d+$/;
        $month = '0' . $month if length($month) == 1;
        $day   = '0' . $day if length($day) == 1;
        if ($year > 20 and $year < 100) { 
            $year+=1900;
        }
        elsif ($year <= 20) {
            $year += 2000;
        }
        $date="$year$month$day";
    }
    else {
        $date='';
    }
    return $date;
}

# Note: Most of this is lifted from the original code. It does some crazy things to handle
#       teams not in comps which is highly likely to just be ignored when a team is added
#       to a comp, but I left it in there because this crazy logic has become our business
#       logic.
sub updatePlayers {
    my ($params) = @_;
    my ($Data, $assocID, $compID, $clubID, $teamID, $player_ids) = @{$params}{qw(data assocID compID clubID teamID player_ids)};
    # Get members currently in the team
    my %currentPlayers;
    
    my $db = $Data->{'db'};
    
    if (!$clubID){
        my $club_id_lookup_stmt = 'SELECT intClubID from tblTeam where intTeamID =?';
        my $club_id_lookup_query = $db->prepare($club_id_lookup_stmt);
        $club_id_lookup_query->execute($teamID);
        if (my $dref = $club_id_lookup_query->fetchrow_hashref()){
            $clubID = $dref->{'intClubID'} || 0;
        }
    }

    my @current_players_values = ( $teamID );
    
    ## This will then only grab members who are in the comp.
    my $current_players_sql = qq[
        SELECT DISTINCT intMemberID, intMemberTeamID, intStatus
        FROM tblMember_Teams
        WHERE intTeamID = ?
          AND intStatus = $Defs::RECSTATUS_ACTIVE
    ];
    
    if ($compID && $compID > 0) {
        $current_players_sql .= " and (intCompID=? )";
        push @current_players_values, $compID;
    } else {
        $current_players_sql .= " and intCompID=0";
    }

    $current_players_sql .= " ORDER BY intCompID DESC";

    my $current_players_stmt = $db->prepare($current_players_sql) or query_error($current_players_sql);
    $current_players_stmt->execute( @current_players_values ) or query_error($current_players_sql);
    
    while(my ($DB_intMemberID, $DB_intMemberTeamID, $DB_intStatus) = $current_players_stmt->fetchrow_array())  {
        $currentPlayers{$DB_intMemberID} = {
            'intMemberTeamID' => $DB_intMemberTeamID,
            'intStatus' => $DB_intStatus, 
        };
    }
    $current_players_stmt->finish;

    my $st = qq[
        SELECT DISTINCT CT.intCompID, intNewSeasonID
        FROM tblComp_Teams as CT
            INNER JOIN tblAssoc_Comp as AC ON (AC.intCompID = CT.intCompID)
        WHERE CT.intTeamID=$teamID
            AND CT.intRecStatus = $Defs::RECSTATUS_ACTIVE
            AND AC.intRecStatus = $Defs::RECSTATUS_ACTIVE
    ];
    my $qry_comps = $db->prepare($st);

    my $member_insert_sql = qq[
        INSERT IGNORE INTO tblMember_Teams (intMemberID, intTeamID, intStatus, intCompID) VALUES (?, $teamID, $Defs::RECSTATUS_ACTIVE, ?) ON DUPLICATE KEY UPDATE intStatus = $Defs::RECSTATUS_ACTIVE
    ];
    my $member_insert_stmt = $db->prepare($member_insert_sql);

    # Prepare update sql to make players active in team
    my $member_team_active_update_sql = qq[
        UPDATE tblMember_Teams
        SET intStatus = $Defs::RECSTATUS_ACTIVE
    ];
    $member_team_active_update_sql .= qq[, intCompID = $compID]  if $compID >= 0;
    $member_team_active_update_sql .= qq[
        WHERE intMemberTeamID = ?
    ];
    my $member_team_active_update_stmt = $db->prepare($member_team_active_update_sql);

    my $DB_intNewSeasonID = 0;
    my $intNewRegoSeason = $Data->{'SystemConfig'}{'Seasons_defaultNewRegoSeason'};
    my %Comp_Seasons = ();

    #TODO:  Why do we need to know what season it is in?????
    if ($compID) {
        ## We have a CompID, lets get what season its in
        my $st_comp = qq[
            SELECT intNewSeasonID
            FROM tblAssoc_Comp
            WHERE intCompID = $compID
                AND intAssocID = $assocID
        ];
        my $qry_compSeason = $db->prepare($st_comp);
        $qry_compSeason->execute or query_error($st_comp);
        $DB_intNewSeasonID = $qry_compSeason->fetchrow_array() || $intNewRegoSeason;
        $Comp_Seasons{$compID} = $DB_intNewSeasonID;
    }
    
    for my $id (@{$player_ids}) {
        
        if (exists $currentPlayers{$id} and $compID > 0) {
            my $intMemberTeamID = $currentPlayers{$id} || 0;
            $member_team_active_update_stmt->execute($intMemberTeamID);
            delete $currentPlayers{$id};
        }
        else { 
            my $comp_counts=0;
            $qry_comps->execute or query_error($st);
            
            if ($compID) {
                $comp_counts++;
                $member_insert_stmt->execute($id, $compID) if $id>0;  
                my $st_upd = qq[
                    UPDATE tblMember_Teams
                    SET intStatus = $Defs::RECSTATUS_ACTIVE 
                    WHERE intMemberID =$id
                        AND intTeamID = $teamID
                        AND intCompID = $compID
                ]; 
                my $qry_up = $db->prepare($st_upd);
                $qry_up->execute();
            }
            else {
                #while(my ($DB_intCompID, $DB_intNewSeasonID) = $qry_comps->fetchrow_array())  {
                    my ($DB_intCompID, $DB_intNewSeasonID) = (0,0);
                    $DB_intNewSeasonID ||= $intNewRegoSeason;
                    $Comp_Seasons{$compID} = $DB_intNewSeasonID;
                    $comp_counts++;
                    #$member_insert_stmt->execute($id, $DB_intCompID) if $id>0 and $DB_intCompID != $compID;   
                    $member_insert_stmt->execute($id, $DB_intCompID) if $id>0;   
                    my $st_upd = qq[
                        UPDATE tblMember_Teams
                        SET intStatus = $Defs::RECSTATUS_ACTIVE 
                        WHERE intMemberID =$id
                            AND intTeamID = $teamID
                            AND intCompID = $DB_intCompID
                    ]; 
                    my $qry_up = $db->prepare($st_upd);
                    $qry_up->execute();
                #}
            }
            if (! $comp_counts) {
                if (exists $currentPlayers{$id})    {
                    my $intMemberTeamID = $currentPlayers{$id}{'intMemberTeamID'} || 0;
                    $member_team_active_update_stmt->execute($intMemberTeamID);
                }
                $member_insert_stmt->execute($id,0) if $id>0;     
            }
            delete $currentPlayers{$id}; ### BAFF LOOK HERE AS WELL
        }
    }   
    $member_team_active_update_stmt->finish;
    $member_insert_stmt->finish;
    
    


    # Delete remaining existing players from the team list
    my $delete_member_in_team_sql = qq[
        UPDATE tblMember_Teams
        SET intStatus = $Defs::RECSTATUS_DELETED
        WHERE intMemberID = ? 
                        AND intTeamID = ?
                        AND intStatus = ?
    ];
    
    # If we are in a comp, add the restriction
    if ($compID and $compID > 0){
        $delete_member_in_team_sql .= qq[AND intCompID in ($compID)];
    }else {
        $delete_member_in_team_sql .= qq[AND intCompID in ($compID, 0, -1)]; 
    }
    
    my $delete_member_in_team_stmt = $db->prepare($delete_member_in_team_sql);
    foreach my $id (keys %currentPlayers) {
        $delete_member_in_team_stmt->execute($id, $teamID, $Defs::RECSTATUS_ACTIVE);
    }
    $delete_member_in_team_stmt->finish;

    # Cleanup players without a comp? 
    my $players_without_comp_cleanup_sql = qq[
        UPDATE tblMember_Teams
        SET intStatus = $Defs::RECSTATUS_DELETED
        WHERE intTeamID = $teamID
            AND intStatus = $Defs::RECSTATUS_ACTIVE
            AND intCompID = -1
    ];
    my $players_without_comp_cleanup_stmt = $db->prepare($players_without_comp_cleanup_sql);
    $players_without_comp_cleanup_stmt->execute();
                                                                                            
    foreach my $compID (keys %Comp_Seasons) {
        $Data->{'memberListIntoComp'}=1 if ($compID and $compID == $compID);
        ## For all the Comp_Team records lets check the members Season records
        checkForMemberSeasonRecord($Data, $compID, $teamID, 0);
    }
    auditLog($teamID, $Data, 'Update Member List', 'Team');
    
    return 1;
}


1;
