package TermsConditions;

require Exporter;
@ISA = qw(Exporter);
@EXPORT= qw(getTerms);
@EXPORT_OK = qw(getTerms);
use lib "..",".";
use LangBase;
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

1;
