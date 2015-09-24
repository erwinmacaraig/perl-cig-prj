#!/usr/bin/perl

use strict;
use lib "..", "../web";
use Utils;
use DBI;
use Defs;
use PersonRegistrationStatusChange;

use Data::Dumper;

sub main {
    my $db = connectDB();
    my $realmID = 1;
    my %Data = ();
    $Data{'db'} = $db;
    $Data{'Realm'} = 1; #default to 1
    $Data{'SystemConfig'} = getSystemConfig(\%Data);

    #Rollover a number of periods
    my $npID = $Data{'SystemConfig'}{'rolloverNationalPeriodID_1'} || 0;
    rolloverRegoRecords($db, $npID, $realmID) if ($npID);

    $npID = $Data{'SystemConfig'}{'rolloverNationalPeriodID_2'} || 0;
    rolloverRegoRecords($db, $npID, $realmID) if ($npID);

    $npID = $Data{'SystemConfig'}{'rolloverNationalPeriodID_3'} || 0;
    rolloverRegoRecords($db, $npID, $realmID) if ($npID);


}

sub rolloverRegoRecords {

    my ($db, $npID, $realmID) = @_;
    return if (!$npID or !$realmID);

    my $stUPD = qq[
        UPDATE tblPersonRegistration_1
        SET 
            strOldStatus='ACTIVE', 
            strStatus='PASSIVE'
        WHERE intPersonRegistrationID = ?
        LIMIT 1
    ];
    my $qUPD = $db->prepare($stUPD);

    my $st = qq[
        SELECT  
            intPersonRegistrationID
        FROM 
            tblPersonRegistration_$realmID as PR
        WHERE
            intNationalPeriodID = ?
            AND strStatus='ACTIVE'
    ];
    my $q = $db->prepare($st);
    $q->execute($npID);

    my $count = 0;
    while (my $dref=$q->fetchrow_hashref()) {
        my $personRegoID = $dref->{'intPersonRegistrationID'} || next;
        $qUPD->execute( $personRegoID) or query_error($stUPD);
        addPersonRegistrationStatusChangeLog($Data, $personRegoID, $Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_PASSIVE, -1);
        $count++;
    }
    print "$count RECORDS ROLLED OVER\n";
}
1;
