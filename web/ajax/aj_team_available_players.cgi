#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/web/results/ajax/aj_available_players.cgi 9595 2013-09-25 05:05:38Z tcourt $
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
    my $dobFrom   = param('dobFrom');
    my $dobTo     = param('dobTo');
    
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
    
    my %fields_ref;
    foreach my $field ( 'dobFrom', 'dobTo', 'ageGroupFilter', 'seasonFilter', 'genderFilter', 'filteropt'){
        if (param($field)){
            $fields_ref{$field} = param($field);
        }
    }
    
    my @filter_ops = param('filteropt');
    foreach my $option ( @filter_ops ){
        $fields_ref{$option} = 1;
    } 

    my $playerdata_ref = availablePlayers( {
        'data' => \%Data,
        'assocID' => $assocID,
        'compID' => $compID,
        'teamID' => $teamID,
        'fields_ref' => \%fields_ref,
    });

    my $json = to_json({
        players => $playerdata_ref,
        results => scalar($playerdata_ref),
        tID     => $teamID,
        cID     => $compID,
        aID     => $assocID,
    });
    print "Content-type: application/x-javascript\n\n$json";
}

1;
