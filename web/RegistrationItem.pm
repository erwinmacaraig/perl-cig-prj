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
use Data::Dumper;

sub getRegistrationItems    {
    my($Data, $ruleFor, $itemType, $originLevel, $regNature, $entityID, $entityLevel, $multiPersonType, $Rego_ref, $documentFor) = @_; 

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
            D.strDocumentFor,
			D.strDescription,
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
	    AND RI.strPersonType IN ('', ?)
	    AND RI.strPersonLevel IN ('', ?)
        AND RI.strPersonEntityRole IN ('', ?)
	    AND RI.strSport IN ('', ?)
	    AND RI.strAgeLevel IN ('', ?)
        AND RI.strItemType = ? 
        AND (RI.strISOCountry_IN ='' OR RI.strISOCountry_IN IS NULL OR RI.strISOCountry_IN LIKE CONCAT('%|',?,'|%'))
        AND (RI.strISOCountry_NOTIN ='' OR RI.strISOCountry_NOTIN IS NULL OR RI.strISOCountry_NOTIN NOT LIKE CONCAT('%|',?,'|%'))        
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
	        $itemType, 
	        $Rego_ref->{'Nationality'} || '',
	        $Rego_ref->{'Nationality'} || '',
	        
		) or query_error($st);
    
    
	

    my @values = (); 
    push @values, $Data->{'Realm'};  
    push @values,$Data->{'RealmSubType'}; 
    push @values,$ruleFor;
    push @values,$originLevel;
    push @values,$regNature;
    push @values,$Rego_ref->{'strEntityType'} || $Rego_ref->{'entityType'} || '';
    push @values,$entityLevel;
    push @values,$Rego_ref->{'strPersonType'} || $Rego_ref->{'personType'} || '';
    push @values,$Rego_ref->{'strPersonLevel'} || $Rego_ref->{'personLevel'} || '';
    push @values,$Rego_ref->{'strPersonEntityRole'} || $Rego_ref->{'personEntityRole'} || '';
    push @values,$Rego_ref->{'strSport'} || $Rego_ref->{'sport'} || '';
    push @values,$Rego_ref->{'strAgeLevel'} || $Rego_ref->{'ageLevel'} || '';
    push @values,$itemType;
    push @values,$Rego_ref->{'Nationality'} || '';
    push @values,$Rego_ref->{'Nationality'} || '';
    


    my @Items=();
    while (my $dref = $q->fetchrow_hashref())   {
        next if($itemType eq 'DOCUMENT' and $documentFor and ($documentFor ne $dref->{'strDocumentFor'}));

        #check if International Transfer
        next if($dref->{'strDocumentFor'} eq 'TRANSFERITC' and !$Rego_ref->{'InternationalTransfer'});

        my %Item=();
        $Item{'ID'} = $dref->{'intID'};
        $Item{'UseExistingThisEntity'} = $dref->{'intUseExistingThisEntity'} || 0;
        $Item{'UseExistingAnyEntity'} = $dref->{'intUseExistingAnyEntity'} || 0;
        $Item{'Required'} = $dref->{'intRequired'} || 0;
        $Item{'DocumentFor'} = $dref->{'strDocumentFor'} || 0;	
		$Item{'Description'} = $dref->{'strDescription'} || '';
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
