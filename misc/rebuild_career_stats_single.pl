#!/usr/bin/perl
use strict;
use lib '..','../web', '../web/sportstats', '../web/comp';
use Getopt::Long;
use Defs;
use Utils;

use PlayerCareerStatsFactory;

my $assoc_id;
my $round_stats;
my $comp_stats;
my $career_stats;

my @realms= qw(2 3 10);
my $db=connectDB();
$db->{mysql_auto_reconnect} = 1;
$db->{wait_timeout} = 3700;
$db->{mysql_wait_timeout} = 3700;
my %Data=();
$Data{db} = $db;
my $assocID = $ARGV[0] || exit;
my $realmID = $ARGV[1] || exit;
$Data{Realm} = $realmID;

    print "Updating stats for Association: $assocID \n\n"; 
  	my %comp_data = (
			'comp_id' => 99, 
			'assoc_id' => $assocID, 
		);
  	update_player_career_stats(\%Data, \%comp_data);
	


print "\nCompleted\n\n";

exit;

sub update_player_career_stats {
	my ($Data, $comp_data) = @_;
  my %args = (
  	'Data'=>$Data, 
    'CompetitionID'=>$comp_data->{'comp_id'}, 
    'AssocID'=>$comp_data->{'assoc_id'}, 
 	);
  my $careerstats = PlayerCareerStatsFactory->create(%args);
  $careerstats->update();
  return;
}


