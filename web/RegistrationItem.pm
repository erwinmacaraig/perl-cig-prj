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
    my $itc = $Rego_ref->{'InternationalTransfer'} || 0;

    return 0 if (! $itemType);
    my $ActiveFilter_ref='';
    my $personType = $Rego_ref->{'strPersonType'} || $Rego_ref->{'personType'} || '';
    my $sysConfigActiveFilter = 'ACTIVEPERIODS_' . $itemType . '_' . $regNature . '_' . $personType;
    if ($Data->{'SystemConfig'}{$sysConfigActiveFilter} && $Rego_ref->{'intPersonID'})    {
        #If switched on, lets pre-build up Active Results
        $ActiveFilter_ref = registrationItemActivePeriods($Data, $Rego_ref->{'intPersonID'}, $regNature, $personType);
    }

    my $st = qq[
   SELECT 
            RI.intID,
            RI.intRequired,
            RI.intUseExistingThisEntity,
            RI.intUseExistingAnyEntity,
            D.strDocumentName,
            D.strDocumentFor,
			D.strDescription,
            P.strName as strProductName,
            P.strDisplayName as strProductDisplayName,
            TP.intTransactionID,
            RI.intItemUsingActiveFilter,
            RI.strItemActiveFilterPeriods,
            RI.intItemActive
        FROM
            tblRegistrationItem as RI
            LEFT JOIN tblDocumentType as D ON (intDocumentTypeID = RI.intID and strItemType='DOCUMENT')
            LEFT JOIN tblProducts as P ON (P.intProductID= RI.intID and strItemType='PRODUCT')
            LEFT JOIN tblTransactions as TP ON (TP.intProductID = P.intProductID and TP.intPersonRegistrationID = ?)
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
        AND (RI.intFilterFromAge = 0 OR RI.intFilterFromAge <= ?)
        AND (RI.intFilterToAge = 0 OR RI.intFilterToAge >= ?)
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
		    $itc
	        
		) or query_error($st); 

	print STDERR "
	$Rego_ref->{'intPersonRegistrationID'} || '',
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
	        $Rego_ref->{'currentAge'} || 0,
	        $Rego_ref->{'currentAge'} || 0,
		    $itc
	";
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

        ## Lets see if the person was active in the appropriate periods
        if ($dref->{'intItemUsingActiveFilter'})    {
            $ActiveFilter_ref->{$dref->{'strItemActiveFilterPeriods'}} ||= 0;
            next if ($dref->{'intItemActive'} != $ActiveFilter_ref->{$dref->{'strItemActiveFilterPeriods'}});
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
            $Item{'ProductPrice'} = getItemCost($Data, $entityID, $entityLevel, $multiPersonType, $dref->{'intID'}) || 0;
            $Item{'TransactionID'} = $dref->{'intTransactionID'} || 0;
            
        }
        push @Items, \%Item;
    }
    return \@Items;

}

sub registrationItemActivePeriods   {

    my ($Data, $personID, $regNature, $personType) = @_;
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
        my @statusIN = ($Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_ROLLED_OVER, $Defs::PERSONREGO_STATUS_TRANSFERRED);
        my $filterCount = 0;
        foreach my $natPeriodID (@periods)    {
            if (not exists $PeriodStatus{$natPeriodID}) {
                my %Reg = (
                    statusIN => \@statusIN,
                    personType => $personType,
                    nationalPeriodID => $natPeriodID

                );
                my ($count, $reg_ref) = PersonRegistration::getRegistrationData(
                    $Data,
                    $personID,
                    \%Reg
                );
                $PeriodStatus{$natPeriodID} = $count;
            }
            $activeResult = 1 if ($PeriodStatus{$natPeriodID} and $condition eq 'OR'); #If any are >0 then set activeResult as 1
            if ($condition eq 'AND')    {
                $activeResult = 1 if ($PeriodStatus{$natPeriodID} and $condition eq 'AND' and ! $filterCount); #Lets check first one, and set to 1 if >0
                $activeResult = 0 if (! $PeriodStatus{$natPeriodID} and $condition eq 'AND'); #Now only set to False if no results
            }
            $filterCount ++;
        }
        $ActiveFilter{$pref->{'strItemActiveFilterPeriods'}} = $activeResult;
    }

    return \%ActiveFilter;
}

1;
