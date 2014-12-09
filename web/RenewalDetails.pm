package RenewalDetails;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    getRenewalDetails
);

use strict;
use lib '.', '..';
use Defs;
use TTTemplate;
use EntityTypeRoles;
use PersonRegistration;
use Person;
use Data::Dumper;

sub getRenewalDetails {
    my ($Data, $regoID) = @_;

    my $rego = getRegistrationDetail($Data, $regoID) || {};

    $rego = $rego->[0];

    return '' if !$rego;

    my $newAgeLevel = Person::calculateAgeLevel($Data, $rego->{'currentAge'});
    my $personRoles = getEntityTypeRoles($Data, $rego->{'strSport'}, $rego->{'strPersonType'});

    $rego->{'newAgeLevel'} = $newAgeLevel;

    my %templateData = (
        'personType' => $Defs::personType{$rego->{'strPersonType'}} || '',
        'sport' => $Defs::sportType{$rego->{'strSport'}} || '',
        'personRole' => $personRoles->{$rego->{'strPersonEntityRole'}} || '-',
        'personLevel' => $Defs::personLevel{$rego->{'strPersonLevel'}},
        'ageLevel' => $Defs::ageLevel{$newAgeLevel},
    );

    my $content = runTemplate(
        $Data,
        \%templateData,
        'person/renewal_roledetails.templ'
    );

    return($content, $rego);
}


1;
