package TermsConditions;

require Exporter;
@ISA = qw(Exporter);
@EXPORT= qw(getTerms logTermsAcceptance);
@EXPORT_OK = qw(getTerms logTermsAcceptance);
use lib "..",".";
use Defs;


sub getTerms {
    my ($Data, $type) = @_;

    my $currentLanguage = $Data->{'lang'}->generateLocale($Data->{'SystemConfig'});

    my $st = qq[
        SELECT
            intTermsID,
            strTerms
        FROM
            tblTermsConditions
        WHERE
            strType = ?
            AND intCurrent = 1
            AND strLocale = ?
        LIMIT 1
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $type,
        $currentLanguage,
    );
    my ($id, $terms) = $q->fetchrow_array();
    $q->finish();
    return (
        $id || 0,
        $terms || '',
    );
}

sub logTermsAcceptance {
    my ($Data, $type, $userID, $personID, $termsID) = @_;

    warn("OOO my ($Data, $type, $userID, $personID, $termsID) ="); 
    return 0 if !$type;
    return 0 if (!$userID and !$personID);

    if(!$termsID)   {
        ($termsID,undef) = getTerms($Data, $type);    
    }
    return 0 if !$termsID;
    
    my $st = qq[
        INSERT INTO 
            tblTermsConditionsLog
        (
            intTermsID,
            intUserID,
            intPersonID,
            tAgreed
        )
        VALUES (
            ?,
            ?,
            ?,
            NOW()
        )
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $termsID,
        $userID || 0,
        $personID || 0,
    );
    $q->finish();
    return 1;
}


1;
