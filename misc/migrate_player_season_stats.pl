#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/migrate_player_season_stats.pl 8250 2013-04-08 08:24:36Z rlee $
#

use warnings;

use lib "..","../web";
use Defs;
use Utils;
use strict;

my $db = connectDB();

#exit;

my $st_select = qq[
  SELECT
    tblPlayerSeasonStats.*,
    tblAssoc.intRealmID
  FROM
    tblPlayerSeasonStats
    INNER JOIN tblAssoc USING(intAssocID)
  WHERE
    intCreatedFrom > 0
    AND tblPlayerSeasonStats.intAssocID = 12607
];
my $q_select = $db->prepare($st_select);
$q_select->execute();
while (my $dref = $q_select->fetchrow_hashref()) {
  next unless($dref->{'intRealmID'});
  my $st_insert = qq[
      INSERT INTO tblPlayerCompStats_$dref->{'intRealmID'} (
        intPlayerCompStatsID, 
        intAssocID,           
        intSeasonID,          
        intAgeGroupID,        
        intClubID,            
        intCompID,            
        strTeam,              
        intTeamID,            
        strName,              
        strDesc,              
        intPlayerID,          
        intStatTotal1,        
        intStatTotal2,        
        intStatTota30,        
        intCreatedFrom,
        tTimeStamp
    )
    VALUES (
      0,
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
      '2012-03-29'
    )
  ];
  my $q_insert = $db->prepare($st_insert);
  $q_insert->execute(
    $dref->{'intAssocID'},           
    $dref->{'intSeasonID'},          
    $dref->{'intAgeGroupID'},        
    $dref->{'intClubID'},            
    $dref->{'intCompID'},            
    $dref->{'strTeam'}, ## NEW FIELD             
    $dref->{'intTeamID'},            
    $dref->{'strName'}, ## NEW FIELD              
    $dref->{'strDesc'},              
    $dref->{'intMemberID'}, ## intPlayerID          
    $dref->{'intMatches'},  ## intStatTotal1        
    $dref->{'intStat1'}, ## intStatTotal2
    $dref->{'intFinalsMatches'},  ## intStatTotal30        
    $dref->{'intCreatedFrom'}
  ); 
}

