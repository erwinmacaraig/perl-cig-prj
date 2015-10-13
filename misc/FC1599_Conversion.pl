#!/usr/bin/perl

#
# $Header: 
#

use strict;
use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";
use Defs;
use Utils;
use SystemConfig;
use PlayerPassport;

main();

sub main    {
    my $db = connectDB();

    my %Data = ();
    my $db = connectDB();
    $Data{'db'} = $db;
    $Data{'Realm'} = 1;
    $Data{'RealmSubType'} = 0;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    
    my $st = qq[
        SELECT
            intEntityID
        FROM
            tblEntity
        WHERE
            intIsInternationalTransfer =1
    ];
    
    my $qry= $db->prepare($st);
    $qry->execute();

    my $holdingClubID= $qry->fetchrow_array() || 0;

    if ($holdingClubID) {
        migrateRecords(\%Data, $holdingClubID);
    }
    else    {
        print STDERR "Need Holding Club ID\n";
    }



}

sub migrateRecords{
    my ($Data, $holdingClubID) = @_;
    my $db = $Data->{'db'};

    my $st = qq[
        SELECT
            PR.*,
            intExistingPersonRegistrationID,
            intRequestToEntityID
        FROM
            tblPersonRegistration_1 as PR
            LEFT JOIN tblPersonRequest as PersonReq ON (PersonReq.intPersonRequestID = PR.intPersonRequestID and PR.intPersonID=PersonReq.intPersonID)
        WHERE
            PR.intEntityID = ?
            AND PR.strPersonType= 'PLAYER'
            AND PR.strStatus IN ('ACTIVE', 'PASSIVE')
            AND PR.intPersonRegistrationID = 1963088
    ];

    my $stINS_IntTransfer= qq[
        INSERT IGNORE INTO tblIntTransfer
        (
            intOldEntityID,
            intPersonRequestID,
            intPersonID,
            strSport,
            strPersonType,
            strPersonOutLevel,
            dtTransferOut,
            intTransferOut,
            strMAOutTo,
            strClubOutTo,
            strTMSOutRef,
            strOutNotes
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            'PLAYER',
            ?,
            ?,
            1,
            '',
            '',
            '',
            ''
        )
    ];
    my $qryINS_IntTransfer= $db->prepare($stINS_IntTransfer);

    my $stReq_OUT = qq[
        UPDATE tblPersonRequest
        SET 
            strRequestType= 'INT_TRANSFER_OUT'
        WHERE
            intPersonRequestID = ?
            AND intPersonID = ?
        LIMIT 1
    ];
    my $qryReq_OUT= $db->prepare($stReq_OUT);
 
    my $stUPD_OUT = qq[
        UPDATE tblPersonRegistration_1
        SET 
            strPreTransferredStatus = strStatus, 
            strStatus='INT_TRANSFER_OUT'
        WHERE
            intPersonID= ?
            AND intEntityID = ?
            AND strSport = ?
            AND strStatus = 'TRANSFERRED'
    ];
    my $qryUPD_OUT= $db->prepare($stUPD_OUT);

     my $stUPD_HOLDINGCLUB_PR= qq[
        UPDATE tblPersonRegistration_1
        SET 
            strRegistrationNature = 'INT_TRANSFER_OUT'
        WHERE
            intPersonRegistrationID = ?
        LIMIT 1
    ];
    my $qryUPD_HOLDINGCLUB_PR= $db->prepare($stUPD_HOLDINGCLUB_PR);
        
    my $qry= $db->prepare($st);
    $qry->execute($holdingClubID);

    while (my $dref = $qry->fetchrow_hashref()) {
        if ($dref->{'intPersonRequestID'})  {
            $qryReq_OUT->execute(
                $dref->{'intPersonID'},
                $dref->{'intPersonRequestID'}
            );
        }
        $qryUPD_OUT->execute(
            $dref->{'intPersonID'},
            $dref->{'intRequestToEntityID'},
            $dref->{'strSport'}
        );
    
        $qryUPD_HOLDINGCLUB_PR->execute($dref->{'intPersonRegistrationID'});
            
         $qryINS_IntTransfer->execute(
            $dref->{'intRequestToEntityID'},
            $dref->{'intPersonRequestID'},
            $dref->{'intPersonID'},
            $dref->{'strSport'},
            $dref->{'strPersonLevel'},
            $dref->{'dtApproved'}
        );
        savePlayerPassport($Data, $dref->{'intPersonID'});
    }
}

1;
