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
use PersonRegistration;
use Data::Dumper;


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

    my ($count, $regs) = PersonRegistration::getRegistrationData(
        $Data,
        $personID,
        {},
    );

    my @personRegistration = ();

    foreach my $reg_rego_ref (@{$regs}) {
        next if $reg_rego_ref->{'strStatus'} ne $Defs::PERSONREGO_STATUS_ACTIVE;

        push @personRegistration, [ 
            $Data->{'lang'}->txt($reg_rego_ref->{'PersonType'} . " valid to ") . $Data->{'l10n'}{'date'}->format($reg_rego_ref->{'npdtTo'},'MEDIUM'),
            $reg_rego_ref->{'strPersonType'},
        ];
    }

    my $isocountries  = getISOCountriesHash();
    my %templateData = (
        #'NationalNum' => $personObj->getValue('strNationalNum') || '',
        'NationalNum' => $personObj->getValue('strStatus') eq $Defs::PERSON_STATUS_REGISTERED ? $personObj->getValue('strNationalNum') || '' : $personObj->getValue('strNationalNum') ? $Defs::personStatus{$Defs::PERSON_STATUS_PENDING} : '',
        'FamilyName' => $personObj->getValue('strLocalSurname') || '',
        'FirstName' => $personObj->getValue('strLocalFirstname') || '',
        'dob' => $personObj->getValue('dtDOB'),
        'gender' => $Defs::PersonGenderInfo{$personObj->getValue('intGender')},
        'nationality' => $isocountries->{$personObj->getValue('strISONationality')},
        'registrations' => \@personRegistration,
    );

    my $content = runTemplate(
        $Data,
        \%templateData,
        'person/summarypanel.templ'
    );

    return $content || '';
}


1;
