#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/web/results/ajax/aj_save_players.cgi 9595 2013-09-25 05:05:38Z tcourt $
#

use strict;
use warnings;
use lib ".", "..", "../..", "../../..", "../../../results", '../../comp';
use CGI qw(param);
use JSON;

use Reg_common;
use Utils;
use Lang;
use SystemConfig;
use TeamEdit;
use Log;

main();

sub main {
    
    # GET INFO FROM URL
    my $client    = param('client')    || '';
    my $compID    = param('compID')    || 0;
    my $teamID    = param('teamID')    || 0;
    my $assocID   = param('assocID')   || 0;

    my $dataIN    = param('playerdata');

    # AUTHENTICATE
    my %Data   = ();
    my %clientValues = getClient($client);
    $Data{'clientValues'} = \%clientValues;
    my $db = allowedTo( \%Data );

    $Data{'db'} = $db;
    ( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );
    getDBConfig( \%Data );
    $Data{'SystemConfig'} = getSystemConfig( \%Data );
    $Data{'LocalConfig'}  = getLocalConfig( \%Data );
    
    my $lang= Lang->get_handle() || die "Can't get a language handle!";
    $Data{'lang'}=$lang;
    

    my %Players=();
    foreach my $row (split /\|/,$dataIN)    {
        my ($key, $val) = split /=/, $row;
        my ($memberID) = $key =~ /spl_(\d+)$/;
        $Players{$memberID} = $val; 
    }
    
    my @player_ids = keys %Players;

    updatePlayers({
        'data' => \%Data,
        'assocID' => $assocID,
        'compID' => $compID,
        'teamID' => $teamID,
        'player_ids' => \@player_ids,
    });

    my $json = to_json({
        result => 'ok',
        results => 1,
    });
    
    print "Content-type: application/x-javascript\n\n$json";

}
