#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/automatic/clearance_dtDue.pl 8820 2013-06-27 23:42:31Z dhanslow $
#

use lib "../web","..","../web/comp/";
use Defs;
use Utils;
use DBI;
use strict;
use Lang;
use SystemConfig;
use FinalsEligibility;
use Getopt::Long;

my $assocID;
my $compID;
my $seasonID;

GetOptions ('assoc=i'=>\$assocID,'season=i'=>\$seasonID,'comp=i'=>\$compID);

if (!$assocID || !$seasonID) {
    &usage('Please provide the assocID and the season');
}

my $st = '';
my $db=connectDB();
if ($compID) {
	$st = qq[
    select 
      distinct 
      AC.intCompID, 
      CT.intTeamID 
    from 
      tblAssoc_Comp AC
      INNER JOIN tblComp_Teams CT ON CT.intCompID=AC.intCompID
    WHERE AC.intNewSeasonID=$seasonID
      AND AC.intCompID=$compID
      AND AC.intAssocID=$assocID
	];
} else {
	$st = qq[
    select 
      distinct 
      AC.intCompID, 
      CT.intTeamID 
    from 
      tblAssoc_Comp AC
      INNER JOIN tblComp_Teams CT ON CT.intCompID=AC.intCompID
    WHERE 
      AC.intNewSeasonID=$seasonID
      AND AC.intAssocID=$assocID
	];
}

my $query = $db->prepare($st);
$query->execute;
my @clearances=();
while (my($compID, $teamID) = $query->fetchrow_array) {
		## DAVID: MIGHT BE WORTH CALLING THIS:
		updateFinalsEligibility($db, $assocID, $compID, $teamID);	
}
	

sub usage {
    my $error = shift;
    print "\nERROR:\n";
    print "\t$error\n";
    print "\tusage:./rerun_finalsEligibility.pl --assoc assocID --season seasonID\n\n";

    exit;
}


