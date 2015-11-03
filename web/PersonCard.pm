package PersonCard;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    getAllowedCards
    getExistingBatchID
    newBatchID
    cancel_batch
    mark_batch
    getBatchCount
    getBatchInfo
    getCardInfo
    logCardPrintRequest
);

use strict;
use lib '.', '..';
use Defs;

use Reg_common;
use Utils;

sub getAllowedCards {
	my ($Data) = @_;

    my $level = $Data->{'clientValues'}{'authLevel'} || 0;
	my $query = qq[ 
        SELECT 
            intPersonCardID,
            strName
        FROM 
            tblPersonCard
        WHERE
            intBulkPrintFromLevelID <= ?
    ];

	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($level);
	my @cards = ();
	while(my $dref = $sth->fetchrow_hashref()){
		push @cards, {
			id => $dref->{'intPersonCardID'},
			name => $dref->{'strName'},
		};
	}
	$sth->finish();
    return \@cards;
}

sub getExistingBatchID {
	my ($Data) = @_;

    my $level = $Data->{'clientValues'}{'authLevel'} || 0;
    my $id = getID($Data->{'clientValues'}, $level || 0);
	my $st = qq[ 
        SELECT
            intPersonCardBatchID
        FROM
            tblPersonCardBatch
        WHERE
            intEntityTypeID = ?
            AND intEntityID = ?
            AND intStatus = 0
    ];
	my $q = $Data->{'db'}->prepare($st);
	$q->execute($level, $id);
    my ($batchID) = $q->fetchrow_array() || 0;
    $q->finish();
    return $batchID || 0;
}

sub newBatchID {
	my ($Data, $cardID, $lang) = @_;

    my $level = $Data->{'clientValues'}{'authLevel'} || 0;
    my $id = getID($Data->{'clientValues'}, $level || 0);
	my $st = qq[ 
        INSERT INTO tblPersonCardBatch (
            intEntityTypeID,
            intEntityID,
            intCardID,
            strLocale,
            intStatus,
            dtAdded
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            0,
            NOW()
        )
    ];
	my $q = $Data->{'db'}->prepare($st);
	$q->execute($level, $id, $cardID, $lang);
    my $newBatchId = $q->{'mysql_insertid'} || 0;
    $q->finish();
    return $newBatchId || 0;
}

sub cancel_batch {
	my ($Data, $batchID) = @_;

	my $st = qq[ 
        UPDATE
            tblPersonCardPrint
        SET
            intBatchId = 0
        WHERE 
            intBatchID = ?
    ];

	my $q = $Data->{'db'}->prepare($st);
	$q->execute($batchID);
    $q->finish();
	$st = qq[ 
        UPDATE
            tblPersonCardBatch
        SET
            intStatus = 2
        WHERE 
            intPersonCardBatchID = ?
    ];
	$q = $Data->{'db'}->prepare($st);
	$q->execute($batchID);
    $q->finish();
    return 1;
}

sub mark_batch {
	my ($Data, $batchID) = @_;

	my $st = qq[ 
        UPDATE
            tblPersonCardPrint
        SET
            dtPrinted = NOW()
        WHERE 
            intBatchID = ?
    ];

	my $q = $Data->{'db'}->prepare($st);
	$q->execute($batchID);
    $q->finish();
	$st = qq[ 
        UPDATE
            tblPersonCardBatch
        SET
            intStatus = 1
        WHERE 
            intPersonCardBatchID = ?
    ];
	$q = $Data->{'db'}->prepare($st);
	$q->execute($batchID);
    $q->finish();
    return 1;
}


sub getBatchCount {
	my ($Data, $batchID) = @_;

	my $st = qq[ 
        SELECT COUNT(*)
        FROM 
            tblPersonCardPrint 
        WHERE
            intBatchID = ?
            AND dtPrinted = '0000-00-00 00:00:00'
    ];

	my $q = $Data->{'db'}->prepare($st);
	$q->execute($batchID);
	my ($count) = $q->fetchrow_array();
	$q->finish();
    return $count || 0;
}

sub getCardInfo {
    my ($Data, $cardID) = @_;

    return undef if !$cardID;
    my $st = qq[
      SELECT * 
      FROM tblPersonCard
      WHERE intPersonCardID = ?
    ];

    my $q = $Data->{'db'}->prepare($st);
    $q->execute($cardID);
    my($carddata) = $q->fetchrow_hashref();
    $q->finish();
    return undef if !$carddata;

    $st = qq[
      SELECT strType
      FROM tblPersonCardTypes
      WHERE intPersonCardID = ?
    ];

    $q = $Data->{'db'}->prepare($st);
    $q->execute($cardID);
    while(my($type) = $q->fetchrow_array()) {
        push @{$carddata->{'types'}}, $type;
    }
    $q->finish();
    return $carddata || undef;
}

sub getBatchInfo {
    my ($Data, $batchID) = @_;

    return undef if !$batchID;
    my $st = qq[
      SELECT * 
      FROM tblPersonCardBatch
      WHERE intPersonCardBatchID = ?
    ];

    my $q = $Data->{'db'}->prepare($st);
    $q->execute($batchID);
    my($dref) = $q->fetchrow_hashref();
    $q->finish();
    return $dref || undef;
}

sub logCardPrintRequest {
    my (
        $Data, 
        $personID,
        $registrationID,
   ) = @_;

    my $realmID = $Data->{'Realm'} || 1;
    my $st = qq[
        INSERT INTO tblPersonCardPrint (
            intPersonID,
            strType,
            intRegistrationID,
            intCardID,
            dtAdded
        )
        SELECT
            PR.intPersonID,
            PR.strPersonType,
            PR.intPersonRegistrationID,
            PC.intPersonCardID,
            NOW()
        FROM
            tblPersonRegistration_$realmID AS PR
            INNER JOIN tblPersonCardTypes AS PCT
                ON PR.strPersonType = PCT.strType
            INNER JOIN tblPersonCard AS PC
                ON PCT.intPersonCardID = PC.intPersonCardID
        WHERE
            PR.intPersonRegistrationID = ?
            AND PC.intActive = 1
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute($registrationID);
    $q->finish();

    return 1;
}
1;
