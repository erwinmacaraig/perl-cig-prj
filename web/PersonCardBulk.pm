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
    my $personType = param('pType') || '';
    my $personLevel = param('pLevel') || '';
    my $lang = param('lang') || '';
    my $limit = param('limit') || 10;
    if($limit !~/^\d+$/)   { $limit = 10; }

    my $batchID = newBatchID($Data, $cardID, $lang);
    my $cardInfo = getCardInfo($Data, $cardID);
    my $cardTypes = join("','",@{$cardInfo->{'types'}});

    my $levelJoin = '';
    my $realmID = $Data->{'Realm'} || 1;
    my @values = ();
    if($personLevel)    {
        $levelJoin = qq[
            INNER JOIN tblPersonRegistration_$realmID AS PR ON (
                PCP.intRegistration = PR.intPersonRegistrationID
                AND PR.strPersonLevel = ? 
            )
        ];
        push @values, $personLevel;
    }
    push @values, $batchID;
    push @values, $cardID;
# NEED TO BUILD IN CHECK IN TREE NAT/REGIONAL 
    my $st = qq[
        UPDATE tblPersonCardPrint AS PCP
            $levelJoin
        SET PCP.intBatchID = ?,
            intCardID = ?
        WHERE
            PCP.strType IN ('$cardTypes')        
            AND PCP.intBatchID = 0
        LIMIT $limit

    ];
	my $q = $Data->{'db'}->prepare($st);
	$q->execute(@values);
    $q->finish();

    return $batchID;
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

1;
