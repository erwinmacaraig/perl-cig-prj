#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/comp_nominations_to_team_preferences.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;
use lib '..','../web', '../web/comp';
use Utils;
use Defs;

my $log_file = 'comp_nominations_to_team_preferences.log'; 
open (LOG, ">$log_file") || die "Unable to create log file\n$!\n";


my $dbh = connectDB();
my $query = qq[SELECT 
               tblCompNominations.*, tblTeam.strName AS TeamName, tblDefVenue.strName AS VenueName
               FROM tblCompNominations
               INNER JOIN tblTeam ON (tblTeam.intTeamID = tblCompNominations.intTeamID)
               INNER JOIN tblDefVenue ON (tblDefVenue.intDefVenueID = tblCompNominations.intPrefVenueID) 
               WHERE intStatus = $Defs::TEAM_ENTRY_STATUS_ACCEPTED AND (intPrefVenueID IS NOT NULL AND strPrefStartTime IS NOT NULL)
               AND intAssocID = 16414
               ORDER BY intCompID
               ];

my $sth = $dbh->prepare($query); 
$sth->execute();

while (my $dref = $sth->fetchrow_hashref()) {
    my $team_name = $dref->{TeamName};
    my $team_id = $dref->{intTeamID};
    my $venue_name = $dref->{VenueName};
    my $venue_id = $dref->{intPrefVenueID};
    my $starttime = $dref->{strPrefStartTime};
    my $nomination_id = $dref->{intCompNominationID};
    $starttime .= ':00' if $starttime;
    print "\nUpdating nomination: $nomination_id for team:$team_name - $team_id\n";
    
    if ($venue_id) {
        print "Setting team venue preference to $venue_name\n";
        print LOG "$team_id:intVenue1ID:$venue_id\n";
        $dbh->do(qq[UPDATE tblTeam SET intVenue1ID = $venue_id WHERE intTeamID = $team_id LIMIT 1]);
    
    }
    if ($starttime) {
        print "Setting team starttime preference to $starttime\n";
        print LOG "$team_id:dtStartTime1:$starttime\n";
        $dbh->do(qq[UPDATE tblTeam SET dtStartTime1 = '$starttime' WHERE intTeamID = $team_id LIMIT 1])
    }
}
close LOG;

exit;
