#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/rebuild_stats.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;
use lib '..','../web', '../web/sportstats', '../web/comp';
use Getopt::Long;
use Defs;
use Utils;

use PlayerRoundStatsFactory;
use PlayerCompStatsFactory;
use PlayerCareerStatsFactory;


my $realm_id;
my $assoc_id;
my $round_stats;
my $comp_stats;
my $career_stats;

GetOptions(
	'realm=i' => \$realm_id, 
	'assoc=i' => \$assoc_id, 
	'round_stats' => \$round_stats, 
	'comp_stats' => \$comp_stats, 
	'career_stats' => \$career_stats
);

if ((!$realm_id) or (!$round_stats and !$comp_stats and !$career_stats)) { 
    &usage('Please provide the realm and an optional association ID and one or more stats types you wish to rebuild.');
}

my $db=connectDB();
my %Data=();
$Data{db} = $db;
$Data{Realm} = $realm_id;

my $assoc_where;
if ($assoc_id) {
    $assoc_where = qq[ AND tblAssoc.intAssocID = $assoc_id];
}

my $st = qq[
	SELECT 
  	tblAssoc_Comp.intCompID, 
    strTitle, 
    strRealmName, 
    tblAssoc.strName AS AssocName,
    intCompPoolID,
    intStageID,
    tblAssoc.intAssocID
 	FROM 
		tblAssoc_Comp
    INNER JOIN tblAssoc USING (intAssocID)
    INNER JOIN tblRealms ON (tblRealms.intRealmID = tblAssoc.intRealmID)
    LEFT JOIN tblComp_Pools ON (tblComp_Pools.intCompID = tblAssoc_Comp.intCompID)
 	WHERE 
		tblAssoc.intSWOL = 1
    AND tblAssoc_Comp.intDisplayResults = 1
    AND tblAssoc.intRecStatus != $Defs::RECSTATUS_DELETED
    AND tblRealms.intRealmID = $realm_id
    AND tblAssoc_Comp.intRecStatus = $Defs::RECSTATUS_ACTIVE
    $assoc_where
 	ORDER BY 
  	tblAssoc.strName, 
    tblAssoc_Comp.intSeasonID,
    tblAssoc_Comp.strTitle
];

my $q = $db->prepare($st);
$q->execute();

my $realm_name = '';
my $assoc_name = '';
my @associations = ();

while (my $href = $q->fetchrow_hashref()) {
	if ($realm_name ne $href->{strRealmName}) {
  	$realm_name = $href->{strRealmName};
    print "\nUpdating stats for Realm: $realm_name\n";
    sleep 2;
 	}
  if ($assoc_name ne $href->{AssocName}) {
  	$assoc_name = $href->{AssocName};
    print "\nUpdating stats for Association: $assoc_name\n"; 
		push @associations, [$href->{'intAssocID'},$href->{'AssocName'}];
    sleep 2;
  }
  my $comp_id = $href->{intCompID};
  my $comp_name = $href->{strTitle};
  print "Updating stats for $comp_name\n" if $round_stats or $comp_stats;
  my %comp_data = (
		'comp_id' => $comp_id, 
		'assoc_id' => $href->{intAssocID}, 
		'pool_id' => $href->{intCompPoolID}, 
		'stage_id' => $href->{intStageID}
	);
  if ($round_stats) {
  	print "Updating round stats.\n";
    update_player_round_stats(\%Data, \%comp_data);
  }
  if ($comp_stats) {
  	print "Updating comp stats.\n";
    update_player_comp_stats(\%Data, \%comp_data);
  }
}

if ($career_stats) {
	foreach my $assoc (@associations) {
		my %comp_data = (
  		'assoc_id'=>$assoc->[0],
  	);
  	print "\nUpdating career stats for $assoc->[1] \n";
  	update_player_career_stats(\%Data, \%comp_data);
	}
}

print "\nCompleted\n\n";
exit;

sub update_player_round_stats {
    my ($Data, $comp_data) = @_;
    
    my %args = (
                'Data'=>$Data, 
                'CompetitionID'=>$comp_data->{'comp_id'}, 
                'AssocID'=>$comp_data->{'assoc_id'}, 
                'poolID'=>$comp_data->{'pool_id'}, 
                'stageID'=>$comp_data->{'stage_id'}
            );
    
    my $roundstats = PlayerRoundStatsFactory->create(%args);
    $roundstats->update();

    return;
}
 

sub update_player_comp_stats {
    my ($Data, $comp_data) = @_;
    
    my %args = (
                'Data'=>$Data, 
                'CompetitionID'=>$comp_data->{'comp_id'}, 
                'AssocID'=>$comp_data->{'assoc_id'}, 
                'poolID'=>$comp_data->{'pool_id'}, 
                'stageID'=>$comp_data->{'stage_id'}
            );
    
    my $playerstats = PlayerCompStatsFactory->create(%args);
    $playerstats->update();

    return;
}
 
sub update_player_career_stats {
    my ($Data, $comp_data) = @_;
    
    my %args = (
                'Data'=>$Data, 
                'CompetitionID'=>$comp_data->{'comp_id'}, 
                'AssocID'=>$comp_data->{'assoc_id'}, 
                'poolID'=>$comp_data->{'pool_id'}, 
                'stageID'=>$comp_data->{'stage_id'}
            );
    
    my $careerstats = PlayerCareerStatsFactory->create(%args);
    $careerstats->update();

    return;
}




sub usage {
    my $error = shift;
    print "\nERROR:\n";
    print "\t$error\n";
    print "\tusage:./rebuild_stats.pl --realm realm_id --assoc assoc_id --round_stats --comp_stats --career_stats\n\n";
    exit;
}
