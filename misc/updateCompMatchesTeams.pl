#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/updateCompMatchesTeams.pl 9487 2013-09-10 04:57:13Z tcourt $
#

use strict;
use lib '..','../web', '../web/comp', '../web/sportstats', '../web/SMS', '../web/dashboard', '../web/gendropdown';
use Utils;
use CompObj;
use Team;

my $update = 0;

my @Comps = ();


my $dbh = connectDB();
my $log = 'updateCompMatchesTeams.log';
open(LOG, ">$log") || die "Unable to create log file\n$!\n";

foreach my $comp (@Comps) {
    print "Checking Competition: $comp\n";
    print LOG "Competition: $comp\n";


    
    my($count) = $dbh->selectrow_array("SELECT COUNT(strName) FROM tblTeam INNER JOIN tblComp_Teams USING (intTeamID) WHERE intCompID = $comp GROUP BY strName HAVING COUNT(strName) > 1");
    
   if ($count > 1) {
       print "Mulitple teams with the same name. Can't process\n\n";
       print LOG "Mulitple teams with the same name. Can't process\n\n";
       next;
   }

    # Get intTeamID and strName for teams in tblComp_Teams;
    my $query1 = qq[
                   SELECT tblTeam.strName,tblTeam.intTeamID 
                   FROM tblTeam 
                   INNER JOIN tblComp_Teams USING(intTeamID)
                   WHERE intCompID = $comp
               ];
    my $sth1 = $dbh->prepare($query1);
    $sth1->execute();
    my %CompTeams = ();
    while (my $dref = $sth1->fetchrow_hashref()) {
        $CompTeams{$dref->{strName}} = $dref->{intTeamID};
    }
 

    # Get intTeam and strName for teams in tblCompMatches;
    my $query2 = qq[SELECT tblTeam.strName, tblTeam.intTeamID
                    FROM tblTeam
                    WHERE tblTeam.intTeamID IN 
                    (
                     SELECT intAwayTeamID AS intTeamID FROM tblCompMatches WHERE intCompID =$comp 
                     UNION 
                     SELECT intHomeTeamID AS intTeamID FROM tblCompMatches WHERE intCompID = $comp
                     )
                     ];

    my $sth2 = $dbh->prepare($query2);
    $sth2->execute();
    my %MatchTeams = ();
    while (my $dref = $sth2->fetchrow_hashref()) {
        $MatchTeams{$dref->{strName}} = $dref->{intTeamID};
    }

    my $equal = 1;
    foreach my $comp_name (keys %CompTeams) {
        if (exists($MatchTeams{$comp_name}) and $MatchTeams{$comp_name} != $CompTeams{$comp_name}) {
            $equal = 0;
            last;
        }
    }    
            
    if (!$equal) {
        print "Teams in tblCompMatches differ, need to update\n";
        print LOG "Teams are different\n";
        
        foreach my $team(keys %CompTeams) {
            my $new_teamID = $CompTeams{$team};
            my $old_teamID = $MatchTeams{$team};
            
            print "Updating team id, $old_teamID to $new_teamID\n";
            
            # Update tblComp_Matches Home Team
            if ($update) {
                print "Update home team\n";
                
                $dbh->do("UPDATE tblCompMatches SET intHomeTeamID = $new_teamID WHERE intCompID = $comp AND intHomeTeamID = $old_teamID") || die "Unable to update tblComp_Matches and set intHomeTeamID to new team ID\n$!\n";
            }   
            
            # Update tblComp_Matches Away Team
            if ($update) {
                print "Updating away team\n";
                
                $dbh->do("UPDATE tblCompMatches SET intAwayTeamID = $new_teamID WHERE intCompID = $comp AND intAwayTeamID = $old_teamID") || die "Unable to update tblComp_Matches and set intAwayTeamID to new team ID\n$!\n";
            }
            
            print LOG "Changed Team IDs in tblCompMatches - $old_teamID to $new_teamID\n";
        }
        
    }
    else {
        print "Looks OK.\n";
        print LOG "Teams are the same.\n";
    }
    print LOG "\n";    
   
}

exit;

