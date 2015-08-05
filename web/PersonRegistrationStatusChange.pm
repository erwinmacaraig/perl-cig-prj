package PersonRegistrationStatusChange;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    getPersonRegistrationStatusChangeLog
    addPersonRegistrationStatusChangeLog
    getPersonRegistrationStatus
);

use strict;
use lib '.', '..', '../..';
use Defs;
use Reg_common;
use PersonUtils;
use GridDisplay;
use Switch;
use Data::Dumper;

sub getPersonRegistrationStatusChangeLog {
    my ($Data, $personRegistrationID, $raw) = @_;

    my $lang = $Data->{'lang'};
    my $client = setClient($Data->{'clientValues'}) || '';

    my %RegFilters = ();
    my $st = qq[
        SELECT
            prs.intPersonRegistrationStatusChangeLogID,
            prs.dtChanged,
            prs.intOriginLevel,
            prs.intUserID,
            prs.strOldStatus,
            prs.strNewStatus
        FROM
            tblPersonRegistrationStatusChangeLog prs
        WHERE
            prs.intPersonRegistrationID = ?
    ];

    my $results=0;
    my @rowdata = ();
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(
        $personRegistrationID
    );
    while (my $dref = $query->fetchrow_hashref) {
        $results++;
        
        my $changedBy = '';
        if(!$dref->{'intUserID'}) {
            $changedBy = $Data->{'lang'}->txt('System');
        }
        else {
            switch($dref->{'intOriginLevel'}) {
                case 1 { $changedBy = $Data->{'lang'}->txt('Self User'); }
                case 3 { $changedBy = $Data->{'lang'}->txt('Club'); }
                case 10 { $changedBy = $Data->{'lang'}->txt('Zone'); }
                case 20 { $changedBy = $Data->{'lang'}->txt('Region'); }
                case 30 { $changedBy = $Data->{'lang'}->txt('State'); }
                case 100 { $changedBy = $Data->{'lang'}->txt('MA'); }
                else { $changedBy = $Data->{'lang'}->txt('System'); }
            }
        }

        push @rowdata, {
            id => $dref->{'intPersonRegistrationStatusChangeLogID'} || 0,
            dtChanged => $Data->{'l10n'}{'date'}->TZformat($dref->{'dtChanged'},'MEDIUM','SHORT') || '',
            oldStatus => $Data->{'lang'}->txt($Defs::personRegoStatus{$dref->{'strOldStatus'}}) || '',
            newStatus => $Data->{'lang'}->txt($Defs::personRegoStatus{$dref->{'strNewStatus'}}) || '',
            changedByLevel => $changedBy,
        };
    }

    my $rectype_options = '';
    my @headers = (
        {
            name   => $Data->{'lang'}->txt('Change Date/Time'),
            field  => 'dtChanged',
            width  => 30,
            defaultShow => 1,
        },
        {
            name   => $Data->{'lang'}->txt('Existing Status'),
            field  => 'oldStatus',
            width  => 30,
            defaultShow => 1,
        },
        {
            name   => $Data->{'lang'}->txt('New Status'),
            field  => 'newStatus',
            width  => 40,
        },
        {
            name   => $Data->{'lang'}->txt('Changed by Level'),
            field  => 'changedByLevel',
            width  => 40,
        },
    );

    my $filterfields = [
    ];

    my $grid  = showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '100%',
        filters => $filterfields,
        gridid  => 'regoStatusChangeLog',
        gridtitle => $Data->{'lang'}->txt('Change Status Log'),
    );

    my $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:100%;">$rectype_options</div>
            $grid
        </div>
    ];

    return $resultHTML;
}

sub addPersonRegistrationStatusChangeLog {
    my ($Data, $personRegistrationID, $oldStatus, $newStatus, $trigger) = @_;

    #return if (($oldStatus eq $newStatus) or $Defs::personRegoStatus{$newStatus} == '');
    return if ($oldStatus eq $newStatus);

    my $st = qq[
        INSERT INTO tblPersonRegistrationStatusChangeLog
        (
            intPersonRegistrationID,
            dtChanged,
            intOriginLevel,
            intUserID,
            strOldStatus,
            strNewStatus
        )
        VALUES 
        (
            ?,
            NOW(),
            ?,
            ?,
            ?,
            ?
        )
    ];

    $trigger ||= $Data->{'clientValues'}{'authLevel'};

  	my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $personRegistrationID,
        $trigger || 0,
        $Data->{'clientValues'}{'authLevel'} == 1 ? $Data->{'User'}{'UserID'} || 0 : $Data->{'clientValues'}{'userID'} || 0,
        $oldStatus,
        $newStatus
    );

    return;
}

sub getPersonRegistrationStatus {
    my ($Data, $personRegistrationID) = @_;

    my $st = qq[
        SELECT
            pr.*
        FROM 
            tblPersonRegistration_$Data->{'Realm'} AS pr
        WHERE
            pr.intPersonRegistrationID = ?
        LIMIT 1
    ];


    my $db = $Data->{'db'};
    my $query = $db->prepare($st) or query_error($st);
    $query->execute($personRegistrationID); 

    my $dref = $query->fetchrow_hashref();

    return $dref;
}

1;
