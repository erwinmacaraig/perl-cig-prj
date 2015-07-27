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



    my $entityLevel_sent = $entityLevel;
    my $regNature_sent = $regNature;
    my $personType = $Rego_ref->{'strPersonType'} || $Rego_ref->{'personType'} || '';

    #RegistrationItems_PLAYER_NEW_TreatAs99;
    #my $sysConfigCheck = "RegistrationItems_" . $personType . "_" . $regNature . "_TreatAs99";
    #if ($itemType eq 'PRODUCT' and $Data->{'SystemConfig'}{$sysConfigCheck} == 1)   {
    #    $originLevel=99;
    #    $entityLevel=99;
    #}
    #RegistrationItems_PLAYER_TreatRenewalAsNew
    my $sysConfigCheck = "RegistrationItems_" . $personType . "_TreatRenewalAsNew";
    if ($itemType eq 'PRODUCT' and $Data->{'SystemConfig'}{$sysConfigCheck} == 1 and $regNature eq 'RENEWAL')   {
        $regNature = 'NEW';
    }

    $itemType ||= '';
    $originLevel ||= 0; 
    $regNature ||= '';
    $ruleFor ||= '';
    $entityLevel ||= 0; # used for Products
    $multiPersonType ||= ''; ## For products, are multi regos used    
    my $itc = $Rego_ref->{'InternationalTransfer'} || $Rego_ref->{'InternationalLoan'} || 0;

    return 0 if (! $itemType);
    my $ActiveFilter_ref='';
    my $sysConfigActiveFilter = 'ACTIVEPERIODS_' . $itemType . '_' . $regNature_sent . '_' . $personType;
    if ($Data->{'SystemConfig'}{$sysConfigActiveFilter} && $Rego_ref->{'intPersonID'})    {
        #If switched on, lets pre-build up Active Results
        $ActiveFilter_ref = registrationItemActivePeriods($Data, $Rego_ref->{'intPersonID'}, $regNature, $personType, $Rego_ref->{'strSport'} || $Rego_ref->{'sport'} || '');
    }

    my $ActiveProductsFilter_ref='';
    my $sysConfigActiveProductsFilter = 'ACTIVEPRODUCTS_' . $itemType . '_' . $regNature_sent . '_' . $personType;
    if ($Data->{'SystemConfig'}{$sysConfigActiveProductsFilter} && $Rego_ref->{'intPersonID'})    {
        #If switched on, lets pre-build up Active Results
        $ActiveProductsFilter_ref = registrationItemActiveProducts($Data, $Rego_ref->{'intPersonID'}, $regNature, $personType);
    }

    my $regNature2 = $regNature;
    $sysConfigCheck = "RegistrationItems_TransferUsesNew";
    if ($itemType eq 'PRODUCT' and $regNature eq "TRANSFER" and $Data->{'SystemConfig'}{"RegistrationItems_TransferUsesNew"} == 1)  {
        $regNature2 = 'NEW';
        my $sysConfigActiveProductsFilter = 'ACTIVEPRODUCTS_' . $itemType . '_TRANSFER_' . $personType;
        if ($Data->{'SystemConfig'}{$sysConfigActiveProductsFilter} && $Rego_ref->{'intPersonID'})    {
            $ActiveProductsFilter_ref = registrationItemActiveProducts($Data, $Rego_ref->{'intPersonID'}, $regNature2, $personType);
        }
    }
    $sysConfigCheck = "RegistrationItems_DomesticLoanUsesNew";
    if ($itemType eq 'PRODUCT' and $regNature eq "DOMESTIC_LOAN" and $Data->{'SystemConfig'}{"RegistrationItems_DomesticLoanUsesNew"} == 1)  {
        $regNature2 = 'NEW';
        my $sysConfigActiveProductsFilter = 'ACTIVEPRODUCTS_' . $itemType . '_DOMESTIC_LOAN_' . $personType;
        if ($Data->{'SystemConfig'}{$sysConfigActiveProductsFilter} && $Rego_ref->{'intPersonID'})    {
            $ActiveProductsFilter_ref = registrationItemActiveProducts($Data, $Rego_ref->{'intPersonID'}, $regNature2, $personType);
        }
    }
    #$sysConfigCheck = "RegistrationItems_InternationalLoanUsesNew";
    #if ($itemType eq 'PRODUCT' and $regNature eq "INTERNATIONAL_LOAN" and $Data->{'SystemConfig'}{"RegistrationItems_InternationalLoanUsesNew"} == 1)  {
    #    $regNature2 = 'NEW';
    #    my $sysConfigActiveProductsFilter = 'ACTIVEPRODUCTS_' . $itemType . '_INTERNATIONAL_LOAN_' . $personType;
    #    if ($Data->{'SystemConfig'}{$sysConfigActiveProductsFilter} && $Rego_ref->{'intPersonID'})    {
    #        $ActiveProductsFilter_ref = registrationItemActiveProducts($Data, $Rego_ref->{'intPersonID'}, $regNature2, $personType);
    #    }
    #}
     
    #$sysConfigCheck = "RegistrationItems_InternationalTransferUsesNew";
    #if ($itemType eq 'PRODUCT' and $regNature eq "INTERNATIONAL_TRANSFER" and $Data->{'SystemConfig'}{"RegistrationItems_InternationalTransferUsesNew"} == 1)  {
    #    $regNature2 = 'NEW';
    #    my $sysConfigActiveProductsFilter = 'ACTIVEPRODUCTS_' . $itemType . '_INTERNATIONAL_TRANSFER_' . $personType;
    #    if ($Data->{'SystemConfig'}{$sysConfigActiveProductsFilter} && $Rego_ref->{'intPersonID'})    {
    #        $ActiveProductsFilter_ref = registrationItemActiveProducts($Data, $Rego_ref->{'intPersonID'}, $regNature2, $personType);
    #    }
    #}
 
    my $locale = $Data->{'lang'}->getLocale();
    my $st = qq[
   SELECT 
            RI.intID,
            RI.intRequired,
            RI.intUseExistingThisEntity,
            RI.intUseExistingAnyEntity,
            COALESCE (LT_D.strString1,D.strDocumentName) as strDocumentName,
            D.strDocumentFor,
			COALESCE(LT_D.strNote,D.strDescription) AS strDescription,
            COALESCE (LT_P.strString1,P.strName) as strProductName,
            COALESCE(LT_P.strString2,P.strDisplayName) as strProductDisplayName,
            TP.intTransactionID,
            RI.intItemUsingActiveFilter,
            RI.strItemActiveFilterPeriods,
            RI.intItemActive,
            RI.intItemUsingPaidProductFilter,
            RI.strItemActiveFilterPaidProducts,
            RI.intItemPaidProducts,
strItemType
        FROM
            tblRegistrationItem as RI
            LEFT JOIN tblDocumentType as D ON (intDocumentTypeID = RI.intID and strItemType='DOCUMENT')
            LEFT JOIN tblProducts as P ON (P.intProductID= RI.intID and strItemType='PRODUCT')
            LEFT JOIN tblLocalTranslations AS LT_P ON (
                LT_P.strType = 'PRODUCT'
                AND LT_P.intID = P.intProductID
                AND LT_P.strLocale = '$locale'
            )
            LEFT JOIN tblLocalTranslations AS LT_D ON (
                LT_D.strType = 'DOCUMENT'
                AND LT_D.intID = D.intDocumentTypeID
                AND LT_D.strLocale = '$locale'
            )
            LEFT JOIN tblTransactions as TP ON (TP.intProductID = P.intProductID and TP.intPersonRegistrationID = ?)
        WHERE
            RI.intRealmID = ?
            AND RI.intSubRealmID IN (0, ?)
            AND RI.strRuleFor = ?
            AND RI.intOriginLevel IN (99, ?)
	    AND RI.strRegistrationNature IN (?, ?)
            AND RI.strEntityType IN ('', ?)
            AND RI.intEntityLevel IN (0, 99, ?)
	    AND RI.strPersonType IN ('', ?)
	    AND RI.strPersonLevel IN ('', ?)
        AND RI.strPersonEntityRole IN ('', ?)
	    AND RI.strSport IN ('', ?)
	    AND RI.strAgeLevel IN ('', ?)
        AND RI.strItemType = ? 
        AND (RI.strISOCountry_IN ='' OR RI.strISOCountry_IN IS NULL OR RI.strISOCountry_IN LIKE CONCAT('%|',?,'|%'))
        AND (RI.strISOCountry_NOTIN ='' OR RI.strISOCountry_NOTIN IS NULL OR RI.strISOCountry_NOTIN NOT LIKE CONCAT('%|',?,'|%'))        
        AND (RI.intFilterFromAge = 0 OR RI.intFilterFromAge <= ?)
        AND (RI.intFilterToAge = 0 OR RI.intFilterToAge >= ?)
        AND (RI.intItemForInternationalTransfer = 0 OR RI.intItemForInternationalTransfer = ?)
        AND (RI.intItemForInternationalLoan = 0 OR RI.intItemForInternationalLoan = ?)
	AND (RI.intItemUsingITCFilter =0
                OR (RI.intItemUsingITCFilter = 1 AND RI.intItemNeededITC = ?)
            )
      ]; 
   
    my $q = $Data->{'db'}->prepare($st) or query_error($st);
    $q->execute(
	        $Rego_ref->{'intPersonRegistrationID'} || '',
	        $Data->{'Realm'}, 
	        $Data->{'RealmSubType'}, 
	        $ruleFor,
	        $originLevel,
		$regNature,
		$regNature2,
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
	        $Rego_ref->{'currentAge'} || 0,
	        $Rego_ref->{'currentAge'} || 0,
                $Rego_ref->{'InternationalTransfer'} || 0,
                $Rego_ref->{'InternationalLoan'} || 0,
		$itc
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
        #next if($dref->{'strDocumentFor'} eq 'TRANSFERITC' and !$Rego_ref->{'InternationalTransfer'});

        ## Lets see if the person was active in the appropriate periods
        if ($itemType eq 'PRODUCT' && $Data->{'SystemConfig'}{$sysConfigActiveFilter} && $dref->{'intItemUsingActiveFilter'})    {
            if (! defined $ActiveFilter_ref->{$dref->{'strItemActiveFilterPeriods'}})   {
                $ActiveFilter_ref->{$dref->{'strItemActiveFilterPeriods'}} ||= 0; # was outside of if
            }
            next if ($dref->{'intItemActive'} != $ActiveFilter_ref->{$dref->{'strItemActiveFilterPeriods'}});
        }

        ## Lets see if the person has appropriate paid products
        if ($Rego_ref->{'intPersonID'} && $itemType eq 'PRODUCT' && $Data->{'SystemConfig'}{$sysConfigActiveProductsFilter} && $dref->{'intItemUsingPaidProductFilter'})    {
            if (! $ActiveProductsFilter_ref or ! defined $ActiveProductsFilter_ref->{$dref->{'strItemActiveFilterPaidProducts'}})   {
                $ActiveProductsFilter_ref->{$dref->{'strItemActiveFilterPeriods'}} = 0; # was outside of if
            }
            next if ($dref->{'intItemPaidProducts'} != $ActiveProductsFilter_ref->{$dref->{'strItemActiveFilterPaidProducts'}});
        }


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
            #$Item{'Name'} = $dref->{'strProductName'};
            $Item{'Name'} = $dref->{'strProductDisplayName'} || $dref->{'strProductName'};
            $Item{'ProductPrice'} = getItemCost($Data, $entityID, $entityLevel_sent, $multiPersonType, $dref->{'intID'}) || 0;
            $Item{'TransactionID'} = $dref->{'intTransactionID'} || 0;
            
        }
       
        push @Items, \%Item;
    }
    return \@Items;

}

sub registrationItemActivePeriods   {

    my ($Data, $personID, $regNature, $personType, $sport) = @_;
    $personID || return undef;

    my %ActiveFilter=();

    my $stFilters= qq[
        SELECT DISTINCT
            strItemActiveFilterPeriods
        FROM
            tblRegistrationItem
        WHERE
            intRealmID = ?
            AND strRegistrationNature = ?
            AND strPersonType IN ('', ?)
            AND intItemUsingActiveFilter = 1
            AND strItemActiveFilterPeriods <> ''
    ];
    my $qryFilters = $Data->{'db'}->prepare($stFilters) or query_error($stFilters);
    $qryFilters->execute(
        $Data->{'Realm'},
        $regNature,
        $personType
    );
    my %PeriodStatus = ();
    while (my $pref = $qryFilters->fetchrow_hashref())  {
        my $periodString = $pref->{'strItemActiveFilterPeriods'};
        my $activeResult = 0;
        my $condition = 'AND';
        $condition = 'OR' if ($pref->{'strItemActiveFilterPeriods'} =~ /\|/);
        my @periods = ();
        if ($condition eq 'AND')    {
            @periods= split /\&/, $periodString;
        }
        if ($condition eq 'OR')    {
            @periods= split /\|/, $periodString;
        }
        my @statusIN = ($Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_ROLLED_OVER, $Defs::PERSONREGO_STATUS_TRANSFERRED, $Defs::PERSONREGO_STATUS_PASSIVE);
        my $filterCount = 0;
        foreach my $natPeriodID (@periods)    {
            my $notCondition = 0;
            $notCondition = 1 if ($natPeriodID =~ /^!/);
            $natPeriodID =~ s/!//;
    
            if (not exists $PeriodStatus{$natPeriodID}) {
                my %Reg = (
                    statusIN => \@statusIN,
                    sport => $sport,
                    personType => $personType,
                    nationalPeriodID => $natPeriodID

                );
                my ($count, $reg_ref) = PersonRegistration::getRegistrationData(
                    $Data,
                    $personID,
                    \%Reg
                );
                if ($Data->{'SystemConfig'}{'ActivePeriods_IgnoreHOBBY'})   {
                    $count = 0;
                    foreach my $reg (@{$reg_ref})  {
                        next if ($reg->{'strPersonLevel'} eq $Defs::PERSON_LEVEL_HOBBY);
                        $count++;
                    }
                }
                $PeriodStatus{$natPeriodID} = $count;
            }
            $activeResult = 1 if (! $notCondition and $PeriodStatus{$natPeriodID} and $condition eq 'OR'); #If any are >0 then set activeResult as 1
            $activeResult = 1 if ($notCondition and ! $PeriodStatus{$natPeriodID} and $condition eq 'OR'); #If any are >0 then set activeResult as 1
            if ($condition eq 'AND')    {
                $activeResult = 1 if (! $notCondition and $PeriodStatus{$natPeriodID} and $condition eq 'AND' and ! $filterCount); #Lets check first one, and set to 1 if >0
                $activeResult = 1 if ($notCondition and ! $PeriodStatus{$natPeriodID} and $condition eq 'AND' and ! $filterCount); #Lets check first one, and set to 1 if >0
                $activeResult = 0 if (! $notCondition and ! $PeriodStatus{$natPeriodID} and $condition eq 'AND'); #Now only set to False if no results
                $activeResult = 0 if ($notCondition and $PeriodStatus{$natPeriodID} and $condition eq 'AND'); #Now only set to False if no results
            }
            $filterCount ++;
        }
        $ActiveFilter{$pref->{'strItemActiveFilterPeriods'}} = $activeResult;
    }

    return \%ActiveFilter;
}

sub registrationItemActiveProducts  {

    my ($Data, $personID, $regNature, $personType) = @_;
    $personID || return undef;

    my %ActiveFilter=();

    my $stFilters= qq[
        SELECT DISTINCT
            strItemActiveFilterPaidProducts
        FROM
            tblRegistrationItem
        WHERE
            intRealmID = ?
            AND strRegistrationNature = ?
            AND strPersonType IN ('', ?)
            AND intItemUsingPaidProductFilter= 1
            AND strItemActiveFilterPaidProducts <> ''
    ];
    my $qryFilters = $Data->{'db'}->prepare($stFilters) or query_error($stFilters);
    $qryFilters->execute(
        $Data->{'Realm'},
        $regNature,
        $personType
    );
    my $stProds = qq[
        SELECT DISTINCT
            intProductID 
        FROM
            tblTransactions
        WHERE
            intStatus IN ($Defs::TXN_PAID, $Defs::TXN_HOLD)
            AND intTableType = $Defs::LEVEL_PERSON
            AND intID = ?
            AND curAmount > 0
    ];
    my $qryProducts= $Data->{'db'}->prepare($stProds) or query_error($stProds);
    $qryProducts->execute(
        $personID
    );
    my %ProductsPaid=();
    while (my $dref = $qryProducts->fetchrow_hashref())  {
        $ProductsPaid{$dref->{'intProductID'}} = 1;
    }
    #Put each Products thats purchased into a hash then use that below
    while (my $pref = $qryFilters->fetchrow_hashref())  {
        my $filterString = $pref->{'strItemActiveFilterPaidProducts'};
        my $activeResult = 0;
        my $condition = 'AND';
        $condition = 'OR' if ($pref->{'strItemActiveFilterPaidProducts'} =~ /\|/);
        my @products= ();
        if ($condition eq 'AND')    {
            @products= split /\&/, $filterString;
        }
        if ($condition eq 'OR')    {
            @products= split /\|/, $filterString;
        }
        my $filterCount = 0;
        foreach my $prodID (@products)    {
            $activeResult = 1 if ($ProductsPaid{$prodID} and $condition eq 'OR'); #If any are >0 then set activeResult as 1
            if ($condition eq 'AND')    {
                $activeResult = 1 if ($ProductsPaid{$prodID} and $condition eq 'AND' and ! $filterCount); #Lets check first one, and set to 1 if >0
                $activeResult = 0 if (! $ProductsPaid{$prodID} and $condition eq 'AND'); #Now only set to False if no results
            }
            $filterCount ++;
        }
        $ActiveFilter{$pref->{'strItemActiveFilterPaidProducts'}} = $activeResult;
    }

    return \%ActiveFilter;
}

1;
