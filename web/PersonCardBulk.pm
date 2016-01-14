package PersonCardBulk;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  handlePersonCardBulk
);

use strict;
use lib '.', '..';
use Defs;

use Reg_common;
use Utils;
use AuditLog;
use TTTemplate;
use PersonLanguages;
use CGI qw(param);
use PersonCard;

sub handlePersonCardBulk {
    my ( 
        $action, 
        $Data
    ) = @_;

    my $resultHTML = '';
    my $personName = my $title = '';
    my $lang = $Data->{'lang'};
    $action ||= '';
    my $batchID = 0;

    if ( $action =~ /^PCARD_BATCH/ ) {
	    #CREATE BATCH
        $batchID = create_batch( $Data);
        $action = '';
	}
    elsif ( $action =~ /^PCARD_CANCEL/ ) {
	    #CLEAR BATCH
        cancel_batch( $Data, getExistingBatchID($Data));
        $action = '';
	}
    elsif ( $action =~ /^PCARD_MARK/ ) {
	    #CLEAR BATCH
        mark_batch( $Data, getExistingBatchID($Data));
        $action = '';
    }
    elsif ( $action =~ /^PCARD_HISTORY/ ) {
        ($resultHTML, $title) = show_card_history($Data);
    }
    elsif ( $action =~ /^PCARD_REPRINT/ ) {
        my $success = request_reprint($Data);
        ($resultHTML, $title) = show_card_history($Data, $success);
    }
    if(!$action or $action eq 'PCARD_')    {
        $batchID ||= getExistingBatchID($Data);
        my $count = getBatchCount($Data, $batchID);
        if($batchID and $count)    {
            ( $resultHTML, $title ) = show_batch_options( $Data, $batchID );
        }
        else    {
            ( $resultHTML, $title ) = show_bulk_options( $Data, $batchID );
        }
    }
    return ( $resultHTML, $title );
}

sub show_bulk_options   {
	my ($Data, $batchID) = @_;

    my $languages = getPersonLanguages(
        $Data,
        1,
        1,
    );

	my %PageContent = (
        personLevels => \%Defs::personLevel,
        personTypes => \%Defs::personType,
        cardlist => getAllowedCards($Data),
        languages => $languages,
        client => setClient($Data->{'clientValues'}),
        batchID => $batchID,
	);
    my $resultHTML = runTemplate($Data, \%PageContent, 'cardprint/bulkoptions.templ') || '';
    my $title = $Data->{'lang'}->txt('Bulk Card Printing');
    return ($resultHTML, $title);
}

sub create_batch{
	my ($Data) = @_;

    my $cardID = param('cardID') || 0;
    my $personType = param('ptype') || '';
    my $personLevel = param('pLevel') || '';
    my $lang = param('lang') || '';
    my $limit = param('limit') || 10;
    if($limit !~/^\d+$/)   { $limit = 10; }

    my $cardInfo = getCardInfo($Data, $cardID);
    my $cardTypes = join("','",@{$cardInfo->{'types'}});

    my $realmID = $Data->{'Realm'} || 1;
    my @values = ();
    my $level = $Data->{'clientValues'}{'authLevel'} || 0;
    my $id = getID($Data->{'clientValues'}, $level || 0);

    my $levelWhere = '';
    if($personLevel)    {
        $levelWhere = qq[
            AND PR.strPersonLevel = ? 
        ];
        push @values, $personLevel;
    }
    if($personType)    {
        $cardTypes = $personType;
    }
    push @values, $cardID;
    my $st = qq[
        SELECT
            intPersonCardPrintID
        FROM 
            tblPersonCardPrint AS PCP
            INNER JOIN tblPersonRegistration_$realmID AS PR ON (
                PCP.intRegistrationID = PR.intPersonRegistrationID
                $levelWhere
            )
            LEFT JOIN tblTempEntityStructure AS TES ON (
                TES.intChildID = PR.intEntityID
            )
        WHERE
            PCP.strType IN ('$cardTypes')        
            AND PCP.intBatchID = 0
            AND intCardID = ?
            AND (TES.intParentID = $id or PR.intEntityID = $id)
        ORDER BY PCP.intPersonID
        LIMIT $limit
    ];
	my $q = $Data->{'db'}->prepare($st);
    my @ids = ();
	$q->execute(@values);
    while(my ($pcpID) = $q->fetchrow_array())   {
        push @ids, $pcpID;
    }
    $q->finish();
    my $ids = join(',',@ids);
    if($ids)    {
        my $batchID = newBatchID($Data, $cardID, $lang);
        $st = qq[
            UPDATE tblPersonCardPrint AS PCP
            SET PCP.intBatchID = ?
            WHERE
                PCP.intPersonCardPrintID IN ($ids)
            LIMIT $limit
        ];
        $q = $Data->{'db'}->prepare($st);
        $q->execute($batchID);
        $q->finish();
        return $batchID;
    }
    return -1;

}

sub show_batch_options   {
	my ($Data, $batchID) = @_;

    my $count = getBatchCount($Data, $batchID);
	my %PageContent = (
        batchID => $batchID,
        cardcount => $count || 0,
        client => setClient($Data->{'clientValues'}),
	);
    my $resultHTML = runTemplate($Data, \%PageContent, 'cardprint/batchoptions.templ') || '';
    my $title = $Data->{'lang'}->txt('Bulk Card Printing');
    return ($resultHTML, $title);
}

sub show_card_history {
	my ($Data, $batchID) = @_;

    my $level = $Data->{'clientValues'}{'currentLevel'} || 0;
    my $id = getID($Data->{'clientValues'}, $level || 0);
    if($level != $Defs::LEVEL_PERSON)   {
        return ('','');
    }
    my $st = qq[
        SELECT DISTINCT
            PC.strName,
            PCP.intReprint,
            PCP.dtPrinted
        FROM
            tblPersonCardPrint AS PCP
            INNER JOIN tblPersonCard AS PC ON
                PCP.intCardID = PC.intPersonCardID
        WHERE
            intPersonID = ?
            AND dtPrinted > '1970-01-01'
    ];
	my $q = $Data->{'db'}->prepare($st);
	$q->execute($id);
    my @history = ();
    while(my $dref = $q->fetchrow_hashref())   {
        push @history, $dref;
    }

	my %PageContent = (
        client => setClient($Data->{'clientValues'}),
        history => \@history,
        cardlist => getAllowedCards($Data,1),
	);
    my $resultHTML = runTemplate($Data, \%PageContent, 'cardprint/history.templ') || '';
    my $title = $Data->{'lang'}->txt('Card Print History');
    return ($resultHTML, $title);
}

sub request_reprint {
	my ($Data) = @_;

    my $cardID = param('cardID') || 0;

    my $level = $Data->{'clientValues'}{'currentLevel'} || 0;
    my $id = getID($Data->{'clientValues'}, $level || 0);
    if($level != $Defs::LEVEL_PERSON)   {
        return ('','');
    }
    my $authLevel = $Data->{'clientValues'}{'authLevel'} || 0;

    my $cardInfo = getCardInfo($Data, $cardID);
    if($authLevel >= $cardInfo->{'intPrintFromLevelID'})  {
        logCardPrintRequest(
            $Data,
            $id,
            0,
            $cardID
        );
        return 1;
    }

    return 0;
}
1;
