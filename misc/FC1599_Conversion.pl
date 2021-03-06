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
    
    my $st = qq[ SELECT intEntityID FROM tblEntity WHERE intIsInternationalTransfer =1 ];
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

    my $useTempTable = 1; #$Data->{'SystemConfig'}{'1599_tmpTable'} || 0;
    my $tmpTable = '';
    my $tmpTableSELECT = '';
    if ($useTempTable)  {
        $tmpTableSELECT = qq[ 
            tmpI.intLastEntityID as tmpToEntityID, 
            tmpI.strType,
        ];
        $tmpTable = qq[ 
            INNER JOIN tmpIntTransferMigrate as tmpI ON (
                tmpI.intPersonID = PR.intPersonID 
                AND tmpI.intPersonRegistrationID = PR.intPersonRegistrationID
                AND tmpI.strType='OUT'
            ) 
        ];
## Does this require OUT as a string parameter ?
    }

    my $st = qq[
        SELECT
            PR.*,
            intExistingPersonRegistrationID,
            $tmpTableSELECT
            intRequestToEntityID
        FROM
            tblPersonRegistration_1 as PR
            LEFT JOIN tblPersonRequest as PersonReq ON (PersonReq.intPersonRequestID = PR.intPersonRequestID and PR.intPersonID=PersonReq.intPersonID)
            $tmpTable
        WHERE
            PR.intEntityID = ?
            AND PR.strPersonType= 'PLAYER'
            AND PR.strRegistrationNature <> 'INT_TRANSFER_OUT'
            AND PR.strStatus IN ('ACTIVE', 'PASSIVE')
            AND PR.intOnLoan=0
            AND PR.intIsLoanedOut = 0
    ];
            #AND PersonReq.intPersonRequestID IS NULL
    # For each of the above people we may need to move the CLUB they are in
        # Per SPORT
    # 1. Select from tblPersonRegistration_1
    # 2. Update tblPersonRequest
    # 3. Update tblTransactions SELECT COUNT(*) FROM tblTransactions WHERE intTXNEntityID=1659;
    # 4. Update tblPersonRegistration_1

    my $stINS_IntTransfer= qq[
        INSERT IGNORE INTO tblIntTransfer
        (
            intTransferReturn,
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
            0,
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
            strStatus='INT_TRANS_OUT'
        WHERE
            intPersonID= ?
            AND intEntityID <> ?
            AND strSport = ?
            AND strPersonType='PLAYER'
            AND strStatus IN ('TRANSFERRED', 'PASSIVE')
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

    my $stINSPQ = qq[
        INSERT INTO tblPersonRequest
        (
            intRealmID,
            strRequestType,
            strPersonEntityRole,
            intPersonID,
            intExistingPersonRegistrationID,
            strSport,
            strPersonType,
            strPersonLevel,
            strNewPersonLevel,
            intRequestFromEntityID,
            intRequestToEntityID,
            strRequestResponse,
            strRequestStatus    
        )
        VALUES (
            1,
            'INT_TRANSFER_OUT',
            '',
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?
        )
    ];

    my $stLastEntityID = qq[
        SELECT
            intEntityID
        FROM 
            tblPersonRegistration_1 
        WHERE 
            intPersonID=? 
            AND intEntityID <> $holdingClubID
            AND strPersonType='PLAYER' 
            AND strSport=? 
            AND intOnLoan=0
            AND strStatus IN ('ACTIVE', 'PASSIVE', 'ROLLED_OVER', 'TRANSFERRED')
        ORDER BY 
            dtFrom DESC 
        LIMIT 1
    ];
    my $qryLastEntityID= $db->prepare($stLastEntityID);

    my $qryINSPQ= $db->prepare($stINSPQ);
    while (my $dref = $qry->fetchrow_hashref()) {
        my $tmpEntityID = $dref->{'tmpToEntityID'} || 0;
        if (! $tmpEntityID) {
            $qryLastEntityID->execute(
                $dref->{'intPersonID'},
                $dref->{'strSport'},
            );
            $tmpEntityID = $qryLastEntityID->fetchrow_array();
        }
print STDERR "LAST ENTITYID WAS: $tmpEntityID\n";
        
        if (! $dref->{'intPersonRequestID'})    {
            $qryINSPQ->execute(
                $dref->{'intPersonID'},
                0, #$dref->{'intPersonRegistrationID'}, 
                $dref->{'strSport'},
                $dref->{'strPersonType'},
                $dref->{'strPersonLevel'},
                $dref->{'strPersonLevel'},
                $holdingClubID,
                $tmpEntityID || $holdingClubID,
                'ACCEPTED',
                'COMPLETED'
            );
            $dref->{'intPersonRequestID'} = $qryINSPQ->{mysql_insertid} || 0;
            $dref->{'intRequestToEntityID'} = $tmpEntityID;
            my $stUPPR = qq[
                UPDATE tblPersonRegistration_1 SET intPersonRequestID = ? WHERE intPersonRegistrationID = ? LIMIT 1
            ];
            my $qryUPPR= $db->prepare($stUPPR);
            $qryUPPR->execute($dref->{'intPersonRequestID'}, $dref->{'intPersonRegistrationID'});
        }
        else    {
            if ($dref->{'intPersonRequestID'})  {
                $qryReq_OUT->execute(
                    $dref->{'intPersonID'},
                    $dref->{'intPersonRequestID'}
                );
            }
        }
        $qryUPD_OUT->execute(
            $dref->{'intPersonID'},
            $holdingClubID, #$dref->{'intRequestToEntityID'} || $tmpEntityID,
            $dref->{'strSport'}
        );
    
        $qryUPD_HOLDINGCLUB_PR->execute($dref->{'intPersonRegistrationID'});
            
         $qryINS_IntTransfer->execute(
            $dref->{'intRequestToEntityID'} || $tmpEntityID,
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
