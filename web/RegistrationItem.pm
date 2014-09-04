package RegistrationItem;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
	getRegistrationItems 
);
use lib '.', '..'; #"comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";

use strict;
use Utils;
use Log;
use Products;

sub getRegistrationItems    {
    my($Data, $ruleFor, $itemType, $originLevel, $regNature, $entityID, $entityLevel, $multiPersonType, $Rego_ref) = @_; 

    $itemType ||= '';
    $originLevel ||= 0; 
    $regNature ||= '';
    $ruleFor ||= '';
    $entityLevel ||= 0; # used for Products
    $multiPersonType ||= ''; ## For products, are multi regos used
    

    return 0 if (! $itemType);
	
  my $st = qq[
		SELECT 
            RI.intID,
            RI.intRequired,
            RI.intUseExistingThisEntity,
            RI.intUseExistingAnyEntity,
            D.strDocumentName,
            P.strName as strProductName
        FROM
            tblRegistrationItem as RI
            LEFT JOIN tblDocumentType as D ON (intDocumentTypeID = RI.intID and strItemType='DOCUMENT')
            LEFT JOIN tblProducts as P ON (P.intProductID= RI.intID and strItemType='PRODUCT')
        WHERE
            RI.intRealmID = ?
            AND RI.intSubRealmID IN (0, ?)
            AND RI.strRuleFor = ?
            AND RI.intOriginLevel = ?
			AND RI.strRegistrationNature = ?
            AND RI.strEntityType IN ('', ?)
            AND RI.intEntityLevel IN (0, ?)
			AND RI.strPersonType = ?
			AND RI.strPersonLevel = ?
            AND RI.strPersonEntityRole IN ('', ?)
			AND RI.strSport = ?
			AND RI.strAgeLevel = ?		
            AND RI.strItemType = ?
    ];
    my $q = $Data->{'db'}->prepare($st) or query_error($st);
    
    $q->execute(
        $Data->{'Realm'},
        $Data->{'RealmSubType'},
        $ruleFor,
        $originLevel,
		$regNature,
        $Rego_ref->{'strEntityType'} || $Rego_ref->{'entityType'} || '',
        $entityLevel,
		$Rego_ref->{'strPersonType'} || $Rego_ref->{'personType'} || '',
		$Rego_ref->{'strPersonLevel'} || $Rego_ref->{'personLevel'} || '',
		$Rego_ref->{'strPersonEntityRole'} || $Rego_ref->{'personEntityRole'} || '',
		$Rego_ref->{'strSport'} || $Rego_ref->{'sport'} || '',
		$Rego_ref->{'strAgeLevel'} || $Rego_ref->{'ageLevel'} || '',
        $itemType
	) or query_error($st);
    my @Items=();
    while (my $dref = $q->fetchrow_hashref())   {
        my %Item=();
        $Item{'ID'} = $dref->{'intID'};
        $Item{'UseExistingThisEntity'} = $dref->{'intUseExistingThisEntity'} || 0;
        $Item{'UseExistingAnyEntity'} = $dref->{'intUseExistingAnyEntity'} || 0;
        $Item{'Required'} = $dref->{'intRequired'} || 0;
        if ($itemType eq 'DOCUMENT') {
            $Item{'Name'} = $dref->{'strDocumentName'};
        }
    
        if ($itemType eq 'PRODUCT') {
            $Item{'Name'} = $dref->{'strProductName'} . $st;
            $Item{'ProductPrice'} = getItemCost($Data, $entityID, $entityLevel, $multiPersonType, $dref->{'intID'}) || 0;
            
        }
        push @Items, \%Item;
    }
    return \@Items;

}

1;
