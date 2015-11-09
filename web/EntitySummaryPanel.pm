package EntitySummaryPanel;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  entitySummaryPanel
);

use strict;
use lib '.', '..';
use Defs;
use EntityObj;
use TTTemplate;
use Countries;
use Switch;
use FacilityTypes;
use Logo;


sub entitySummaryPanel {
    my ($Data, $entityID) = @_;

    my $entityObj = new EntityObj(
        db => $Data->{'db'}, 
        ID => $entityID, 
        cache => $Data->{'cache'}
    );

    $entityObj->load();
    return '' if !$entityObj;
    return '' if !$entityObj->ID();

    my $isocountries  = getISOCountriesHash();

    my %templateData = (
        'NationalNum' => $entityObj->getValue('strStatus') eq $Defs::ENTITY_STATUS_ACTIVE ? $entityObj->getValue('strNationalNum') || '' : '',
        'LocalName' => $entityObj->getValue('strLocalName') || '',
        'Country' => $isocountries->{$entityObj->getValue('strISOCountry')},
        'Status' => $Defs::entityStatus{$entityObj->getValue('strStatus')},
    );

    switch ($entityObj->getValue('intEntityLevel')) {
        case "$Defs::LEVEL_CLUB"  {
            $templateData{'FoundationDate'} = $Data->{'l10n'}{'date'}->format($entityObj->getValue('dtFrom'),'MEDIUM');
        }
        case "$Defs::LEVEL_VENUE" {
            my $facilityType = FacilityTypes::getByID($Data, $entityObj->getValue('intFacilityTypeID'));
            $templateData{'FacilityType'} = $facilityType->{'strName'} || '';
        }
        else {
        }
    }
    $templateData{'Logo'} = getLogo($Data, $entityObj->getValue('intEntityLevel'), $entityID) || '';

    my $content = runTemplate(
        $Data,
        \%templateData,
        'entity/summarypanel.templ'
    );

    return $content || '';
}


1;
