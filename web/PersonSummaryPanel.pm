package PersonSummaryPanel;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  personSummaryPanel
);

use strict;
use lib '.', '..';
use Defs;
use PersonObj;
use TTTemplate;
use Countries;


sub personSummaryPanel {
    my ($Data, $personID) = @_;

    my $personObj = new PersonObj(
        db => $Data->{'db'}, 
        ID => $personID, 
        cache => $Data->{'cache'}
    );
    $personObj->load();
    return '' if !$personObj;
    return '' if !$personObj->ID();
    my $isocountries  = getISOCountriesHash();
    my %templateData = (
        #'NationalNum' => $personObj->getValue('strNationalNum') || '',
        'NationalNum' => $personObj->getValue('strStatus') eq $Defs::PERSON_STATUS_REGISTERED ? $personObj->getValue('strNationalNum') || '' : '',
        'FamilyName' => $personObj->getValue('strLocalSurname') || '',
        'FirstName' => $personObj->getValue('strLocalFirstname') || '',
        'dob' => $personObj->getValue('dtDOB'),
        'gender' => $Defs::PersonGenderInfo{$personObj->getValue('intGender')},
        'nationality' => $isocountries->{$personObj->getValue('strISONationality')},
    );

    my $content = runTemplate(
        $Data,
        \%templateData,
        'person/summarypanel.templ'
    );

    return $content || '';
}


1;
