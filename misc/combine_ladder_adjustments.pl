#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/combine_ladder_adjustments.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;
use lib '..','../web','../web/comp';
use Defs;
use Utils;
use LadderAdjustment;

main ();

sub main {
    my $dbh   = connectDB();

    my $st = qq[
        SELECT 
            intAssocID,
            intCompID, 
            intTeamID, 
            intRoundID, 
            strAdjustmentType, 
            COUNT(strAdjustmentReason) AS numRecs,
            SUM(intAdjustmentValue) AS totVal
        FROM tblLadderAdjustments
        GROUP BY 
            intAssocID,
            intCompID, 
            intTeamID, 
            intRoundID, 
            strAdjustmentType 
        HAVING COUNT(strAdjustmentReason)>1;
    ];

    my $q = $dbh->prepare($st);
    $q->execute();

    print "Combining Ladder Adjustments...\n";

    while (my $href = $q->fetchrow_hashref()) {
        my $assocID = $href->{intAssocID};
        my $compID  = $href->{intCompID};
        my $teamID  = $href->{intTeamID};
        my $roundID = $href->{intRoundID};
        my $adjTyp  = $href->{strAdjustmentType};
        my $numRecs = $href->{numRecs};
        my $totVal  = $href->{totVal};

        print "Processing: $assocID/$compID/$teamID/$roundID/$adjTyp\n";
        
        my %args = (
            dbh     => $dbh,
            assocID => $assocID,
            compID  => $compID,
            teamID  => $teamID,
            roundID => $roundID,
            adjTyp  => $adjTyp,
            numRecs => $numRecs,
            totVal  => $totVal,
        );

        combine_adjustments(\%args);
    }

    print "Completed\n";
}

sub combine_adjustments {
    my ($params) = @_;
    
    my $dbh     = $params->{dbh};
    my $assocID = $params->{assocID};
    my $compID  = $params->{compID};
    my $teamID  = $params->{teamID};
    my $roundID = $params->{roundID};
    my $adjTyp  = $params->{adjTyp};
    my $numRecs = $params->{numRecs};
    my $totVal  = $params->{totVal};
    
    my $st = qq[
        SELECT 
            intLadderAdjustmentID,
            strAdjustmentReason,
            intAdjustmentValue,
            intRegrading,
            intCompPoolID
        FROM tblLadderAdjustments
        WHERE
            intAssocID=?        AND
            intCompID=?         AND
            intTeamID=?         AND
            intRoundID=?        AND
            strAdjustmentType=?;
    ];

    my $q = $dbh->prepare($st);
    $q->execute(
        $assocID,
        $compID,
        $teamID,
        $roundID,
        $adjTyp 
    );

    my $regrading  = 0;
    my $compPoolID = 0;
    my $recCount   = 0;
    my $adjValue   = 0;
    my $adjReason  = '';
    my @recsArray = ();

    while (my $href = $q->fetchrow_hashref()) {
        $recCount++;
        push (@recsArray, $href->{intLadderAdjustmentID});

        if ($recCount == 1) {
            $compPoolID = $href->{intCompPoolID};
            $adjReason  = $href->{strAdjustmentReason};
        }

        if ($href->{intRegrading}) {
            $regrading = $href->{intRegrading} if !$regrading;
        }

        die '*Aborted* => Different intCompPoolIDs within a set!' if $href->{intCompPoolID} != $compPoolID;

        $adjValue += $href->{intAdjustmentValue};
    }

    die "*Aborted* => Expected Recs/Value = $numRecs/$totVal, Actual = $recCount/$adjValue!" if ($recCount != $numRecs) or ($adjValue != $totVal);

    #add new record for the accumulated value (if not zero)
    if ($adjValue) {
        my $new_adj = new LadderAdjustment(
            db => $dbh,
            assocID => $assocID,
            compID  => $compID,
            poolID  => $compPoolID
        );

        my $adj_id = $new_adj->insert({
            roundID   => $roundID,
            type      => $adjTyp,
            value     => $adjValue,
            reason    => $adjReason,
            regrading => $regrading,
            teamID    => $teamID,
        });

        die '*Aborted* => Error occurred when inserting new record to database.' if ($DBI::err);
    }

    #now purge all the recs in recsArray
    my $where = 'WHERE intLadderAdjustmentID IN (';

    foreach my $id (@recsArray) { $where .= $id.','; }

    $where .= '-1)'; #adding -1 is easier than removing the last comma

    $st = qq[DELETE FROM tblLadderAdjustments $where];

    $dbh->do($st);

    die '*Aborted* => Error occurred when deleting records from database.' if ($DBI::err);

    return;
}
