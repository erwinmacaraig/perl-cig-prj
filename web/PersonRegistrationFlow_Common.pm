package PersonRegistrationFlow_Common;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    displayRegoFlowSummary
    displayRegoFlowSummaryBulk
    displayRegoFlowComplete
    displayRegoFlowCompleteBulk
    displayRegoFlowCheckout
    displayRegoFlowCertificates
    displayRegoFlowDocuments
    displayRegoFlowProducts
    displayRegoFlowProductsBulk
    generateRegoFlow_Gateways
    validateRegoID
    save_rego_products
    add_rego_record
    bulkRegoSubmit
    bulkRegoCreate
    checkUploadedRegoDocuments
    getRegoTXNDetails
);

use strict;
use lib '../..', '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use PersonRegistration;
use RegistrationItem;
use PersonRegisterWhat;
use RegoProducts;
use Reg_common;
use CGI qw(:cgi unescape param);
use Payments;
use RegoTypeLimits;
use TTTemplate;
use Transactions;
use Products;
use WorkFlow;
use Person;
use Data::Dumper;
use POSIX qw(strftime);
use Date::Parse;
use PlayerPassport;
use RegoAgeRestrictions;
use DisplayPayResult;
use InstanceOf;
use EntityTypeRoles;
use PersonSummaryPanel;
use PersonCertifications;
use Switch;
use TermsConditions;

sub displayRegoFlowCompleteBulk {

    my ($Data, $client, $hidden_ref) = @_;
    my $payMethod= $hidden_ref->{'payMethod'} || param('payMethod') || '';

    my ($amountDue, $logIDs) = getRegoTXNDetails($Data, $hidden_ref->{'txnIds'});
    $hidden_ref->{'totalAmount'} = $amountDue;
    my $gateways = '';

    my $paymentResult = '';
    my $payStatus = 0;
    my $logID = param('tl') || 0;
	my $intID = param('rolloverIDs') || 0;
    ($payStatus, $paymentResult) = displayPaymentResult($Data, $logID, 1, '');
	my $receiptLink = qq[printreceipt.cgi?client=$client&ids=$logID&pID=$intID];
	$paymentResult .= qq[
	<div class="row">
         <div class="col-md-12"><a href="$receiptLink" target="receipt">] . $Data->{'lang'}->txt('Print Receipt') . qq[</a></div>
    </div>];
     $payMethod = '' if (!$amountDue and $payStatus == -1);

    my $maObj = getInstanceOf($Data, 'national');
    my $maName = $maObj
            ? $maObj->name()
            : '';
		
    my %PageData = (
        payNowFlag=> ($payMethod eq 'now') ? 1 : 0,
        payNowMsg=> (! $amountDue and $payMethod eq 'now') ? $paymentResult : '',
        payNowStatus=> $payStatus,
        payLaterFlag=> ($amountDue and $payMethod eq 'later') ? 1 : 0,
        target => $Data->{'target'},
        Lang => $Data->{'lang'},
        client=>$client,
	MAName => $maName
    );
        
    my $body = runTemplate($Data, \%PageData, 'registration/completebulk.templ') || '';
    
    return ($body, $gateways);
}

sub displayRegoFlowSummaryBulk  {

    my ($Data, $regoID, $client, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref, $carryString) = @_;
    my $lang=$Data->{'lang'};
	
    my $body = '';

    my ($unpaid_cost, $logIDs) = getRegoTXNDetails($Data, $hidden_ref->{'txnIds'});
    $hidden_ref->{'totalAmount'} = $unpaid_cost;
    my $url = $Data->{'target'}."?client=$client&amp;a=P_HOME;";
    my $pay_url = $Data->{'target'}."?client=$client&amp;a=P_TXNLog_list;";

    my @products= split /:/, $hidden_ref->{'prodIds'};
    foreach my $prod (@products){ $hidden_ref->{"prod_$prod"} =1;}
    my @productQty= split /:/, $hidden_ref->{'prodQty'};
    foreach my $prodQty (@productQty){ 
        my ($prodID, $qty) = split /-/, $prodQty;
        $hidden_ref->{"prodQTY_$prodID"} =$qty;
    }
    my @IDs= split /\|/, $hidden_ref->{'rolloverIDs'};
		my $c = Countries::getISOCountriesHash();
    
    my @People=();
    my $txnCount = 0;
    my $amountDue = 0;
    for my $pID (@IDs)   {
        my $personObj = getInstanceOf($Data, 'person', $pID);
        my %personData = ();
        $regoID = $hidden_ref->{"regoID_$pID"} || 0;
        my ($txnCountSingle, $amountDueSingle, $logIDsSingle, $originalAmount) = getPersonRegoTXN($Data, $pID, $regoID);
        $txnCount += $txnCountSingle;
        $amountDue += $amountDueSingle;
        $personData{'MAID'} = $personObj->getValue('strNationalNum');
        $personData{'Name'} = $personObj->getValue('strLocalFirstname');
        $personData{'Familyname'} = $personObj->getValue('strLocalSurname');
        $personData{'DOB'} = $personObj->getValue('dtDOB');
        $personData{'Gender'} = $Data->{'lang'}->txt($Defs::genderInfo{$personObj->getValue('intGender') || 0}) || '';
        $personData{'Nationality'} = $c->{$personObj->getValue('strISONationality')};
        $personData{'Country'} = $c->{$personObj->getValue('strISOCountryOfBirth')} || '';
        $personData{'AmountDue'} = $amountDueSingle || 0;
        $personData{'txnCountPerson'} = $txnCountSingle || 0;
        push @People, \%personData;
    }

    my $txn_invoice_url = $Defs::base_url."/printinvoice.cgi?client=$client&amp;rID=$hidden_ref->{'rID'}&amp;pID=$personID";
    my $gatewayConfig = undef;
    if ($txnCount && $Data->{'SystemConfig'}{'AllowTXNs_CCs_roleFlow'}) {
        $gatewayConfig = generateRegoFlow_Gateways($Data, $client, "PREGF_CHECKOUT", $hidden_ref, $txn_invoice_url);
        $gatewayConfig->{'amountDue'} = $amountDue;
    }
      
    my $role_ref = getEntityTypeRoles($Data, $hidden_ref->{'d_sport'}, $hidden_ref->{'d_type'});
    $rego_ref->{'roleName'} = $role_ref->{$hidden_ref->{'d_role'}};
    $rego_ref->{'Sport'} = $Defs::sportType{$hidden_ref->{'d_sport'}} || '';
    $rego_ref->{'PersonType'} = $Defs::personType{$hidden_ref->{'d_type'}} || '';
    $rego_ref->{'PersonLevel'} = $Defs::personLevel{$hidden_ref->{'d_level'}} || '';
    $rego_ref->{'AgeLevel'} = $Defs::ageLevel{$hidden_ref->{'d_age'}} || '';
    $rego_ref->{'RegistrationNature'} = $Defs::registrationNature{$hidden_ref->{'d_nat'}} || '';

    my $entityObj = getInstanceOf($Data, 'entity', $entityID);
    if ($entityObj) { $rego_ref->{'strLocalName'} = $entityObj->getValue('strLocalName'); }

    my $editlink =  $Data->{'target'}."?".$carryString;
    $hidden_ref->{'payMethod'} = 'notrequired' if (! $amountDue);

    my %PaymentConfig = (
        totalAmountDue => $amountDue,
			totalPaymentDue => $amountDue,
        dollarSymbol => $Data->{'SystemConfig'}{'DollarSymbol'} || '$',
        paymentMethodText => $Defs::paymentMethod{$hidden_ref->{'payMethod'}} || '',
    );

	my $displayPayment = ($amountDue and $hidden_ref->{'payMethod'}) ? 1 : 0;
    my %PageData = (
        person_home_url => $url,
        people=> \@People,
        registration => $rego_ref,
        txnCount => $txnCount,
        target => $Data->{'target'},
        RegoStatus => $rego_ref->{'strStatus'},
        hidden_ref=> $hidden_ref,
        Lang => $Data->{'lang'},
        client=>$client,
        editlink => $editlink,
        DisplayPayment => $displayPayment,
        payment => \%PaymentConfig,
    );
    
    $body = runTemplate($Data, \%PageData, 'registration/summarybulk.templ') || '';
    return ($body, $gatewayConfig);
}

sub displayRegoFlowSummary {

    my ($Data, $regoID, $client, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref, $carryString) = @_;
    my $lang=$Data->{'lang'};
	
#print STDERR "~~~~~~~~~~~~~~~~~~~~~~~~displayRegoFlowSummary $personID\n";
    my $ok = 0;
    if ($rego_ref->{'strRegistrationNature'} eq 'RENEWAL'
            or $rego_ref->{'registrationNature'} eq 'RENEWAL'
            or $rego_ref->{'strRegistrationNature'} eq 'TRANSFER'
            or $rego_ref->{'registrationNature'} eq 'TRANSFER'
            or $rego_ref->{'strRegistrationNature'} eq 'DOMESTIC_LOAN'
            or $rego_ref->{'registrationNature'} eq 'DOMESTIC_LOAN'
    ) {
        $ok=1;
    }
    else    {
        $ok = checkRegoTypeLimits($Data, $personID, $regoID, $rego_ref->{'strSport'}, $rego_ref->{'strPersonType'}, $rego_ref->{'strPersonEntityRole'}, $rego_ref->{'strPersonLevel'}, $rego_ref->{'strAgeLevel'});
    }
    my $body = '';
    if (!$ok)   {
        my $error = $lang->txt("You cannot register this combination, limit exceeded");
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_T";
        my %PageData = (
            return_url => $url,
            error => $error,
            target => $Data->{'target'},
            Lang => $lang,
            client => $client,
        );
        $body = runTemplate($Data, \%PageData, 'registration/error.templ') || '';
    }
        my $gatewayConfig = undef;
    my $amountDue = 0;
    if ($ok)   {
        my @products= split /:/, $hidden_ref->{'prodIds'};
        foreach my $prod (@products){ $hidden_ref->{"prod_$prod"} =1;}
        my @productQty= split /:/, $hidden_ref->{'prodQty'};
        foreach my $prodQty (@productQty){ 
            my ($prodID, $qty) = split /-/, $prodQty;
            $hidden_ref->{"prodQTY_$prodID"} =$qty;
        }
        #($hidden_ref->{'txnIds'}, undef) = save_rego_products($Data, $regoID, $personID, $entityID, $rego_ref->{'entityLevel'}, $rego_ref, $hidden_ref); #\%params);

        my $url = $Data->{'target'}."?client=$client&amp;a=P_HOME;";
        my $pay_url = $Data->{'target'}."?client=$client&amp;a=P_TXNLog_list;";
	 	my $txnCount = 0;
		my $logIDs;
		my $txn_invoice_url = $Defs::base_url."/printinvoice.cgi?client=$client&amp;rID=$hidden_ref->{'rID'}&amp;pID=$personID";
        my $originalAmount=0;
        ($txnCount, $amountDue, $logIDs, $originalAmount) = getPersonRegoTXN($Data, $personID, $regoID);
         if ($txnCount && $Data->{'SystemConfig'}{'AllowTXNs_CCs_roleFlow'}) {
            $gatewayConfig = generateRegoFlow_Gateways($Data, $client, "PREGF_CHECKOUT", $hidden_ref, $txn_invoice_url);
         }
        $gatewayConfig->{'amountDue'} = $amountDue;
         
          
	    my $personObj = getInstanceOf($Data, 'person', $personID);
        return if (! $personObj);
		my $c = Countries::getISOCountriesHash();
		
		my %personData = ();
		$personData{'Name'} = $personObj->getValue('strLocalFirstname');
        $personData{'Familyname'} = $personObj->getValue('strLocalSurname');
        $personData{'Maidenname'} = $personObj->getValue('strMaidenName');
		$personData{'DOB'} = $personObj->getValue('dtDOB');
		$personData{'Gender'} = $Data->{'lang'}->txt($Defs::genderInfo{$personObj->getValue('intGender') || 0}) || '';
		$personData{'Nationality'} = $c->{$personObj->getValue('strISONationality')};
		$personData{'Country'} = $c->{$personObj->getValue('strISOCountryOfBirth')} || '';
		$personData{'Region'} = $personObj->getValue('strRegionOfBirth') || '';

		$personData{'Addressone'} = $personObj->getValue('strAddress1') || '';
		$personData{'Addresstwo'} = $personObj->getValue('strAddress2') || '';
		$personData{'City'} = $personObj->getValue('strSuburb') || '';
		$personData{'State'} = $personObj->getValue('strState') || '';
		$personData{'Postal'} = $personObj->getValue('strPostalCode') || '';
		$personData{'Phone'} = $personObj->getValue('strPhoneHome') || '';
		$personData{'Countryaddress'} = $c->{$personObj->getValue('strISOCountry')} || '';
		$personData{'Email'} = $personObj->getValue('strEmail') || '';
		
		#$personData{''} = $personObj->getValue('') || '';

 		my $languages = PersonLanguages::getPersonLanguages( $Data, 1, 0);
		for my $l ( @{$languages} ) {
			if($l->{intLanguageID} == $personObj->getValue('intLocalLanguage')){
				$personData{'Language'} = $l->{'language'};			
				last;	
			}
		}
        my $role_ref = getEntityTypeRoles($Data, $rego_ref->{'strSport'}, $rego_ref->{'strPersonType'});
        $rego_ref->{'roleName'} = $role_ref->{$rego_ref->{'strPersonEntityRole'}};
		####################################################

		my %existingDocuments;
        my $locale = $Data->{'lang'}->getLocale();
		my $query = qq[
		SELECT
        tblDocuments.intDocumentTypeID as ID,  
        tblUploadedFiles.strOrigFilename,
        tblUploadedFiles.intFileID,
        tblDocumentType.strDocumentName as Name,
        COALESCE (LT_D.strString1,tblDocumentType.strDocumentName) as Name
        FROM tblDocuments
        INNER JOIN tblDocumentType
            ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID
        INNER JOIN tblRegistrationItem 
            ON tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID 
        INNER JOIN tblUploadedFiles
            ON tblUploadedFiles.intFileID = tblDocuments.intUploadFileID 
        AND tblDocuments.intPersonID = ?
        AND tblDocuments.intPersonRegistrationID = ?
        AND tblRegistrationItem.intRealmID = ?
        AND tblRegistrationItem.strItemType='DOCUMENT'
            LEFT JOIN tblLocalTranslations AS LT_D ON (
                LT_D.strType = 'DOCUMENT'
                AND LT_D.intID = tblDocumentType.intDocumentTypeID
                AND LT_D.strLocale = '$locale'
            )

        ORDER BY tblDocuments.intDocumentID DESC
		];
	

		my $sth = $Data->{'db'}->prepare($query);
		$sth->execute($personID,$regoID, $Data->{'Realm'});
		 while(my $dref = $sth->fetchrow_hashref()){		
            if(! exists $existingDocuments{$dref->{'ID'}}){
                $existingDocuments{$dref->{'ID'}} = $dref;
            }
		} 
## BAFF: Below needs WHERE tblRegistrationItem.strPersonType = XX AND tblRegistrationItem.strRegistrationNature=XX AND tblRegistrationItem.strAgeLevel = XX AND tblRegistrationItem.strPersonLevel=XX AND tblRegistrationItem.intOriginLevel = XX
	$query = qq[
        SELECT
            tblDocuments.intDocumentTypeID as ID,
            tblUploadedFiles.strOrigFilename,
            tblUploadedFiles.intFileID,
            COALESCE (LT_D.strString1,tblDocumentType.strDocumentName) as Name

        FROM tblDocuments
            INNER JOIN tblDocumentType ON (tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID)
        INNER JOIN tblRegistrationItem ON (tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID)
        INNER JOIN tblUploadedFiles ON (tblUploadedFiles.intFileID = tblDocuments.intUploadFileID )
            LEFT JOIN tblLocalTranslations AS LT_D ON (
                LT_D.strType = 'DOCUMENT'
                AND LT_D.intID = tblDocumentType.intDocumentTypeID
                AND LT_D.strLocale = '$locale'
            )

        WHERE 
            strApprovalStatus IN ('APPROVED', 'PENDING')
            AND intPersonID = ?
            AND (tblRegistrationItem.intUseExistingThisEntity = 1 OR tblRegistrationItem.intUseExistingAnyEntity = 1) 
            AND tblRegistrationItem.intRealmID=?
            AND tblRegistrationItem.strItemType='DOCUMENT'
     AND tblRegistrationItem.strPersonType IN ('', ?)
     AND tblRegistrationItem.strRegistrationNature IN ('', ?)
     AND tblRegistrationItem.strAgeLevel IN ('', ?)
     AND tblRegistrationItem.strPersonLevel IN ('', ?)
     AND tblRegistrationItem.intOriginLevel = ?
     AND tblRegistrationItem.intEntityLevel = ?
        ORDER BY tblDocuments.intDocumentID DESC
    ];

     #AND tblRegistrationItem.intEntityLevel = ? ##### PUT INT


    my $certifications = getPersonCertifications(
        $Data,
        $personID,
        $rego_ref->{'strPersonType'},
        0
    );

    my @certString;
    foreach my $cert (@{$certifications}) {
        push @certString, $cert->{'strCertificationName'};
    }


$sth = $Data->{'db'}->prepare($query);
		$sth->execute(
            $personID,
            $Data->{'Realm'},
            $rego_ref->{'strPersonType'} || '',
            $rego_ref->{'strRegistrationNature'} || '',
            $rego_ref->{'strAgeLevel'} || '',
            $rego_ref->{'strPersonLevel'} || '',
          $originLevel,
          $rego_ref->{'intEntityLevel'},
        );
		 while(my $dref = $sth->fetchrow_hashref()){		
            if(! exists $existingDocuments{$dref->{'ID'}}){
                $existingDocuments{$dref->{'ID'}} = $dref;
            }
		} 

		################################################
        $hidden_ref->{'payMethod'} = 'notrequired' if (! $amountDue);
        my %PaymentConfig = (
            totalAmountDue => $amountDue,
			totalPaymentDue => $amountDue,
            dollarSymbol => $Data->{'SystemConfig'}{'DollarSymbol'} || '$',
            paymentMethodText => $Defs::paymentMethod{$hidden_ref->{'payMethod'}} || '',
        );
            
        my $editlink =  $Data->{'target'}."?".$carryString;
	my $displayPayment = ($amountDue and $hidden_ref->{'payMethod'}) ? 1 : 0;
        $displayPayment = 0 if ($Data->{'SelfRego'} and ! $Data->{'SystemConfig'}{'SelfRego_PaymentOn'});
        my %PageData = (
            person_home_url => $url,
			person => \%personData,
			registration => $rego_ref,
			alldocs => \%existingDocuments,
			txnCount => $txnCount,
            target => $Data->{'target'},
            RegoStatus => $rego_ref->{'strStatus'},
            hidden_ref=> $hidden_ref,
            Lang => $Data->{'lang'},
            client=>$client,
            editlink => $editlink,
            certifications => join(', ', @certString),
            DisplayPayment => $displayPayment,
            payment => \%PaymentConfig,
        );
        
        $body = runTemplate($Data, \%PageData, 'registration/summary.templ') || '';
        my $logID = param('tl') || 0;
        $logIDs->{$logID}=1;
        foreach my $id (keys %{$logIDs}) {
            next if ! $id;
       #     $body .= displayPayResult($Data, $id);
            #$body .= displayPaymentResult($Data, $id, 1, '');
        }
    }
	
    #return $body;
    return ($body, $gatewayConfig);
}
    
sub displayRegoFlowComplete {

    my ($Data, $regoID, $client, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_;

    my $lang=$Data->{'lang'};

    my $ok = 1;
    my $run = $hidden_ref->{'run'} || param('run') || 0;
    if ($rego_ref->{'strRegistrationNature'} eq 'RENEWAL' or $rego_ref->{'registrationNature'} eq 'RENEWAL' or $rego_ref->{'strRegistrationNature'} eq 'TRANSFER' or $rego_ref->{'registrationNature'} eq 'TRANSFER') {
        $ok=1;
    }
    else    {
        $ok = $run ? 1 : checkRegoTypeLimits($Data, $personID, $regoID, $rego_ref->{'strSport'}, $rego_ref->{'strPersonType'}, $rego_ref->{'strPersonEntityRole'}, $rego_ref->{'strPersonLevel'}, $rego_ref->{'strAgeLevel'});
    }
    my $payMethod= $hidden_ref->{'payMethod'} || param('payMethod') || '';
    my $body = '';
    my $gateways = '';
    if (!$ok)   {
        my $error = $lang->txt("You cannot register this combination, limit exceeded");
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_T";
        my %PageData = (
            return_url => $url,
            error => $error,
            target => $Data->{'target'},
            Lang => $lang,
            client => $client,
        );
        $body = runTemplate($Data, \%PageData, 'registration/error.templ') || '';
    }
    $rego_ref->{'personTypeText'} = $Defs::personType{$rego_ref->{'personType'}} || $Defs::personType{$rego_ref->{'strPersonType'}} || '';
    if ($ok)   {
        PersonRegistration::submitPersonRegistration(
            $Data, 
            $personID,
            $regoID,
            $rego_ref
         ) if ! $run;
         
        my @products= split /:/, $hidden_ref->{'prodIds'};
        foreach my $prod (@products){ $hidden_ref->{"prod_$prod"} =1;}
        my @productQty= split /:/, $hidden_ref->{'prodQty'};
        foreach my $prodQty (@productQty){ 
            my ($prodID, $qty) = split /-/, $prodQty;
            $hidden_ref->{"prodQTY_$prodID"} =$qty;
        }
        #($hidden_ref->{'txnIds'}, undef) = save_rego_products($Data, $regoID, $personID, $entityID, $rego_ref->{'entityLevel'}, $rego_ref, $hidden_ref); #\%params);

        my $url = $Data->{'target'}."?client=$client&amp;a=P_HOME;";
        my $pay_url = $Data->{'target'}."?client=$client&amp;a=P_TXNLog_list;";
	 	my $txnCount = 0;
		my $logIDs;
        my $amountDue = 0;
        my $originalAmount=0;
		my $txn_invoice_url = $Defs::base_url."/printinvoice.cgi?client=$client&amp;rID=$hidden_ref->{'rID'}&amp;pID=$personID";
        ($txnCount, $amountDue, $logIDs, $originalAmount) = getPersonRegoTXN($Data, $personID, $regoID);
        if (! $originalAmount and defined $logIDs) {
            foreach my $id (keys %{$logIDs}) {
                next if ! $id;
                product_apply_transaction($Data, $id);
                my $valid =0;
                ($valid, $rego_ref) = validateRegoID(
                    $Data,
                    $personID,
                    $regoID,
                    $entityID
                );
            }
        }
        $rego_ref->{'personTypeText'} = $Defs::personType{$rego_ref->{'personType'}} || $Defs::personType{$rego_ref->{'strPersonType'}} || '';
        $rego_ref->{'personRegoStatus'} = $Defs::personRegoStatus{$rego_ref->{'strStatus'}} || '';
        savePlayerPassport($Data, $personID) if (! $run);
        $hidden_ref->{'run'} = 1;
         #if ($txnCount && $Data->{'SystemConfig'}{'AllowTXNs_CCs_roleFlow'}) {
         #   $gateways = generateRegoFlow_Gateways($Data, $client, "PREGF_CHECKOUT", $hidden_ref, $txn_invoice_url);
         #}
         
       
	    my $personObj = getInstanceOf($Data, 'person', $personID);
	    my $maObj = getInstanceOf($Data, 'national', 0, $entityID);
        my $maName = $maObj
            ? $maObj->name()
            : '';
		
		my %personData = ();
        my $c = Countries::getISOCountriesHash();

		$personData{'Name'} = $personObj->getValue('strLocalFirstname');
        $personData{'Familyname'} = $personObj->getValue('strLocalSurname');
		$personData{'DOB'} = $personObj->getValue('dtDOB');
		$personData{'Gender'} = $Data->{'lang'}->txt($Defs::genderInfo{$personObj->getValue('intGender') || 0}) || '';
		$personData{'Nationality'} = $c->{$personObj->getValue('strISONationality')};
		$personData{'Country'} = $personObj->getValue('strISOCountryOfBirth') || '';
		$personData{'Region'} = $personObj->getValue('strRegionOfBirth') || '';

		$personData{'Addressone'} = $personObj->getValue('strAddress1') || '';
		$personData{'Addresstwo'} = $personObj->getValue('strAddress2') || '';
		$personData{'City'} = $personObj->getValue('strSuburb') || '';
		$personData{'State'} = $personObj->getValue('strState') || '';
		$personData{'Postal'} = $personObj->getValue('strPostalCode') || '';
		$personData{'Phone'} = $personObj->getValue('strPhoneHome') || '';
		$personData{'Countryaddress'} = $personObj->getValue('strISOCountry') || '';
		$personData{'Email'} = $personObj->getValue('strEmail') || '';
		$rego_ref->{'MA'} = $maName || '';
		
		#$personData{''} = $personObj->getValue('') || '';
		
	
 		my $languages = PersonLanguages::getPersonLanguages( $Data, 1, 0);
		for my $l ( @{$languages} ) {
			if($l->{intLanguageID} == $personObj->getValue('intLocalLanguage')){
				$personData{'Language'} = $l->{'language'};			
				last;	
			}
		}
	   my $clubReg = getLastEntityID($Data->{'clientValues'});
       my $cl = setClient($Data->{'clientValues'}) || '';
       my %cv = getClient($cl);
       #$cv{'clubID'} = $rego_ref->{'intEntityID'};
       if ($Data->{'clientValues'}{'clubID'} > 0)   {
            $cv{'clubID'} = $clubReg;
            $cv{'currentLevel'} = $Defs::LEVEL_CLUB;
       }
       elsif ($Data->{'clientValues'}{'regionID'} > 0)    {
            $cv{'regionID'} = $clubReg;
            $cv{'currentLevel'} = $Defs::LEVEL_REGION;

       }
       else {
            $cv{'entityID'} = $clubReg; ## As its getLastEntityID
            $cv{'currentLevel'} = $Defs::LEVEL_NATIONAL;
        }

       my $clm = setClient(\%cv);

        my $client        = unescape($client);
        my %tempClientValues = getClient($client);
        $tempClientValues{personID} = $personID;
        my $tempClient = setClient(\%tempClientValues);

#       $cv{'entityID'} = $maObj->getValue('intEntityID');
#       $cv{'currentLevel'} = $Defs::LEVEL_NATIONAL;
#       my $mlm = setClient(\%cv);

    $cv{'entityID'} = getID($Data->{'ClientValues'}, $Data->{'ClientValues'}{'authLevel'});
    $cv{'currentLevel'} = $originLevel;
    my $originClient = setClient(\%cv);
   
	    ## PaymentMethod
        #payLaterOn	 = 1/0
        my $logID = param('tl') || 0;
        my $paymentResult = '';
        my $payStatus = 0;
        ($payStatus, $paymentResult) = displayPaymentResult($Data, $logID, 1, '');

        $payMethod = '' if (!$amountDue and $payStatus == -1);
        my %PageData = (
            payLaterFlag=> ($amountDue and $payMethod eq 'later') ? 1 : 0,
            payNowFlag=> ($payMethod eq 'now') ? 1 : 0,
            payNowMsg=> (! $amountDue and $payMethod eq 'now') ? $paymentResult : '',
            payNowStatus=> $payStatus,
            person_home_url => $url,
			person => \%personData,
			registration => $rego_ref,
            gateways => $gateways,
			txnCount => $txnCount,
            target => $Data->{'target'},
            RegoStatus => $rego_ref->{'strStatus'},
            hidden_ref=> $hidden_ref,
            Lang => $Data->{'lang'},
            url => $Defs::base_url,
            dtype => $hidden_ref->{'dtype'} || '',
            dtypeText => $Data->{'lang'}->txt($Defs::personType{$hidden_ref->{'dtype'}}) || '',
            client=>$clm,
            clientrego=>$tempClient,
            #maclient => $mlm,
            originLevel => $originLevel,
            originClient => $originClient,
            PersonSummaryPanel => personSummaryPanel($Data, $personObj->ID()),
        );
        
        if($rego_ref->{'strRegistrationNature'} eq $Defs::REGISTRATION_NATURE_TRANSFER) {
            $body = runTemplate($Data, \%PageData, 'personrequest/transfer/complete.templ') || '';
        }
        else {
            #my $template = 'registration/complete.templ';
            my $template = $Data->{'SystemConfig'}{'regoFlow_ApprovalMessage'} || 'registration/complete.templ';            
            $template = 'registration/complete_sr.templ' if ($Data->{'SelfRego'});
            $body = runTemplate($Data, \%PageData, $template) || '';
        }
    }
    return ($body, $gateways);
}
sub getRegoTXNDetails  {

    my ($Data, $txns) = @_;

    $txns =~ s/:/,/g;

    return 0 if ! $txns;
    my $st = qq[
        SELECT 
            intStatus, 
            intTransLogID, 
            curAmount
        FROM tblTransactions
        WHERE
            intRealmID =?
            AND intTransactionID IN ($txns)
    ];
	my $qry = $Data->{'db'}->prepare($st);
	$qry->execute($Data->{'Realm'}); #, @transactions);
    my $amount = 0;
    my %tlogIDs=();
    while (my $dref= $qry->fetchrow_hashref())  {
        $tlogIDs{$dref->{'intTransLogID'}} = 1 if ($dref->{'intTransLogID'} and ! exists $tlogIDs{$dref->{'intTransLogID'}});
        if ($dref->{'intStatus'} == 0)  {
            $amount = $amount + $dref->{'curAmount'};
        }
    }
    return ($amount, \%tlogIDs);
}

sub getPersonRegoTXN    {

    my ($Data, $personID, $regoID) = @_;

    my $st = qq[
        SELECT curAmount, intTransLogID, intTransactionID, intStatus
        FROM tblTransactions
        WHERE
            intRealmID =?
            AND intID = ?
            AND intPersonRegistrationID = ?
            AND intPersonRegistrationID > 0
            AND intTableType = $Defs::LEVEL_PERSON
    ];
	my $qry = $Data->{'db'}->prepare($st);
	$qry->execute($Data->{'Realm'}, $personID, $regoID);
    my $count = 0;
   my %tlogIDs=();
    my $amount = 0;
    my $originalAmount= 0;
    while (my $dref= $qry->fetchrow_hashref())  {
        $tlogIDs{$dref->{'intTransLogID'}} = 1 if ($dref->{'intTransLogID'} and ! exists $tlogIDs{$dref->{'intTransLogID'}});
        $originalAmount += $dref->{'curAmount'};
        if ($dref->{'intStatus'} == 0)  {
            $amount += $dref->{'curAmount'};
            $count++;
        }
    }
    return ($count, $amount, \%tlogIDs, $originalAmount);
}

sub displayRegoFlowCheckout {

    return '';

    ### NOT USED 
    my ($Data, $hidden_ref) = @_;

    my $gCount = param('gatewayCount') || $hidden_ref->{'gatewayCount'} || 0;
    my $cc_submit = '';
    foreach my $i (1 .. $gCount)    {
        if (param("cc_submit[$i]") or $hidden_ref->{"cc_submit[$i]"}) {
            $cc_submit = param("pt_submit[$i]") || $hidden_ref->{"pt_submit[$i]"};
        }
    }
    my @transactions= split /:/, $hidden_ref->{'txnIds'};
        
    my $checkout_body = Payments::checkoutConfirm($Data, $cc_submit, \@transactions,1);
    my $body = qq[PAY];
    $body .= $checkout_body;
    return $body;
}
sub displayRegoFlowCertificates{
	my ($Data, $regoID, $client, $originLevel, $entityLevel, $entityID, $rego_ref, $personID, $hidden_ref) = @_;
	my $lang=$Data->{'lang'};
		
	my @certificates = ();
	#SQL QUERY FOR THE DROPDOWN BOX FOR 
	my $query = qq[SELECT intCertificationTypeID, strCertificationName FROM tblCertificationTypes WHERE strCertificationtype = ? AND intRealmID = ? ORDER BY intDisplayOrder, strCertificationName];
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($rego_ref->{'personType'},$Data->{'Realm'});
	while(my $dref = $sth->fetchrow_hashref()){
		#$certificates{$dref->{'intCertificationTypeID'}} = $dref->{'strCertificationName'};				
	    push @certificates, {
	    	k => $dref->{'intCertificationTypeID'},
	    	val => $dref->{'strCertificationName'},
	    };	
	}
	my @statuses = ();
	foreach my $k (keys %Defs::person_certification_status){
		push @statuses, {
			k => $k,
			val => $Defs::person_certification_status{$k},
		};
	}	
	 my %PageData = (
        nextaction => "PREGF_PCU",
        target => $Data->{'target'},
        certificationtypes => \@certificates,
        statuses => \@statuses,
        hidden_ref => $hidden_ref,
        Lang => $Data->{'lang'},
        client => $client,       
  );  
   my $pagedata = runTemplate($Data, \%PageData, 'registration/certificate_flow_backend.templ') || '';

  return $pagedata;
}

sub checkUploadedRegoDocuments {
    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_; 
	my $documents = getRegistrationItems(
        $Data,
        'REGO',
        'DOCUMENT',
        $originLevel,
        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
        $entityID,
        $entityRegisteringForLevel,
        0,
        $rego_ref,
     );

#print STDERR "~~~~~~~~~~~~~~~CHECK UPLOADED REGO DOCUMENTS:$entityRegisteringForLevel $entityID $personID $regoID\n";
	#check for Approved Documents that do not need to be uploaded
	my @validdocsforallrego = ();
## BAFF: Below needs WHERE tblRegistrationItem.strPersonType = XX AND tblRegistrationItem.strRegistrationNature=XX AND tblRegistrationItem.strAgeLevel = XX AND tblRegistrationItem.strPersonLevel=XX AND tblRegistrationItem.intOriginLevel = XX
	my $query = qq[
            SELECT 
                tblDocuments.intDocumentTypeID 
            FROM 
                tblDocuments INNER JOIN tblDocumentType ON (tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID)
                INNER JOIN tblRegistrationItem ON (tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID)
			WHERE 
                strApprovalStatus IN ('PENDING','APPROVED') 
                AND intPersonID = ? 
                AND tblRegistrationItem.intRealmID=? 
                AND (tblRegistrationItem.intUseExistingThisEntity = 1 OR tblRegistrationItem.intUseExistingAnyEntity = 1) 
                AND tblRegistrationItem.strItemType='DOCUMENT'
          AND tblRegistrationItem.strPersonType IN ('', ?)
          AND tblRegistrationItem.strRegistrationNature IN ('', ?)
          AND tblRegistrationItem.strAgeLevel IN ('', ?)
          AND tblRegistrationItem.strPersonLevel IN ('', ?)
          AND tblRegistrationItem.intOriginLevel = ?
          AND tblRegistrationItem.intEntityLevel = ?
			GROUP BY intDocumentTypeID];

	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute(
        $personID, 
        $Data->{'Realm'},
      $rego_ref->{'strPersonType'} || '',
      $rego_ref->{'strRegistrationNature'} || '',
      $rego_ref->{'strAgeLevel'} || '',
      $rego_ref->{'strPersonLevel'} || '',
      $originLevel,
      $entityRegisteringForLevel,
    );
	while(my $dref = $sth->fetchrow_hashref()){
		push @validdocsforallrego, $dref->{'intDocumentTypeID'};
	}
	#end
	
	my @required = ();
    foreach my $dc (@{$documents}){ 
		#next if(!$dc);
        #next if(!$rego_ref->{'InternationalTransfer'} && $dc->{'DocumentFor'} eq 'TRANSFERITC');	#will only be included when there is an ITC
        next if( grep /$dc->{'ID'}/,@validdocsforallrego);
		if( $dc->{'Required'} ) {
			push @required,$dc;
		}		
	}
	my $total = scalar @required;
	
    return ('',1) if(!$total); # no required documents

     $query = qq[SELECT distinct(strDocumentName),tblDocumentType.intDocumentTypeID as ID FROM tblDocuments INNER JOIN tblDocumentType
                                        ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID
                                        INNER JOIN tblRegistrationItem ON tblRegistrationItem.intID = tblDocumentType.intDocumentTypeID WHERE
                                        tblDocuments.intPersonID = ? AND tblDocuments.intPersonRegistrationID = ? AND tblRegistrationItem.intRequired = 1 AND tblRegistrationItem.intRealmID=? AND tblRegistrationItem.strItemType='DOCUMENT'];

   my @uploaded_docs = ();
   my %uploaded_docs_hash = ();
    $sth = $Data->{'db'}->prepare($query);
    $sth->execute($personID, $regoID, $Data->{'Realm'});
	
	while(my $dref = $sth->fetchrow_hashref()){
		#push @uploaded_docs,$dref->{'strDocumentName'};
		$uploaded_docs_hash{$dref->{'ID'}} = $dref->{'strDocumentName'};		
	}   
    
	my @diff=();
	#check for document not uploaded
	foreach my $rdc (@required){
		if(!exists $uploaded_docs_hash{$rdc->{'ID'}}){
			push @diff, $rdc->{'Name'};
		}
	}
	#foreach my $rdc (@required){		
	#	if(!grep /\Q$rdc->{'Name'}\E/,@uploaded_docs){
	#		push @diff,$rdc->{'Name'};
	#	}
	#}
	
	my $error_message = '<p><br /><ul>';
	foreach my $d (@diff){		
		$error_message .= qq[<li> $d </li>]; 
	}
   
	$error_message .= '</ul> </p>';
	
	$sth->finish();

	return ($error_message, 0) if (@diff);
	return('',1);
}
sub displayRegoFlowDocuments{
    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref, $noFormFields) = @_;
    my $lang=$Data->{'lang'};
	$hidden_ref->{'pID'} = $personID;
     
     my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_DU&amp;rID=$regoID"; 
     my $documents = getRegistrationItems(
        $Data,
        'REGO',
        'DOCUMENT',
        $originLevel,
        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
        $entityID,
        $entityRegisteringForLevel,
        0,
        $rego_ref,
     );
    
	
    my @docos = (); 

    my %existingDocuments;
	#check for uploaded documents present for a particular registration and person
    #my $query = qq[
	#				SELECT distinct(tblDocuments.intDocumentTypeID), tblDocumentType.strDocumentName
	#				FROM tblDocuments 
	#					INNER JOIN tblDocumentType
	#				ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID
	#				INNER JOIN tblRegistrationItem 
	#				ON tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID
	#				WHERE tblDocuments.intPersonID = ? AND intPersonRegistrationID = ?;	
	#];
   
#print STDERR "~~~~~~~~~~~~~~~displayRegoFlowDocuments\n";
## BAFF: Below needs WHERE tblRegistrationItem.strPersonType = XX AND tblRegistrationItem.strRegistrationNature=XX AND tblRegistrationItem.strAgeLevel = XX AND tblRegistrationItem.strPersonLevel=XX AND tblRegistrationItem.intOriginLevel = XX
    my $locale = $Data->{'lang'}->getLocale();
    my $query = qq [
        SELECT
            tblDocuments.intDocumentTypeID as ID,
            tblRegistrationItem.intUseExistingThisEntity as UseExistingThisEntity,
            tblRegistrationItem.intUseExistingAnyEntity as UseExistingAnyEntity,
            tblUploadedFiles.strOrigFilename,
            tblUploadedFiles.intFileID,
            tblUploadedFiles.intAddedByTypeID as AddedByTypeID,
            COALESCE (LT_D.strString1,tblDocumentType.strDocumentName) as Name,
            COALESCE(LT_D.strNote,tblDocumentType.strDescription) AS Description

        FROM tblDocuments
        INNER JOIN tblDocumentType ON (tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID)
        INNER JOIN tblRegistrationItem ON (tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID )
        INNER JOIN tblUploadedFiles ON ( tblUploadedFiles.intFileID = tblDocuments.intUploadFileID )
        LEFT JOIN tblLocalTranslations AS LT_D ON (
            LT_D.strType = 'DOCUMENT'
            AND LT_D.intID = tblDocumentType.intDocumentTypeID
            AND LT_D.strLocale = '$locale'
        )

        WHERE
            tblDocuments.intPersonID = ?
            AND tblDocuments.intPersonRegistrationID = ?
            AND tblRegistrationItem.intRealmID=?
            AND tblRegistrationItem.strItemType='DOCUMENT'
AND tblRegistrationItem.strPersonType IN ('', ?)
      AND tblRegistrationItem.strAgeLevel IN ('', ?)
      AND tblRegistrationItem.strPersonLevel IN ('', ?)
      AND tblRegistrationItem.strRegistrationNature IN ('', ?)
      AND tblRegistrationItem.intOriginLevel = ?
      AND tblRegistrationItem.intEntityLevel = ?
        ORDER BY tblDocuments.intDocumentID DESC
    ];

	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute(
        $personID,
        $regoID, 
        $Data->{'Realm'},
        $rego_ref->{'strPersonType'} || '',
        $rego_ref->{'strAgeLevel'} || '',
        $rego_ref->{'strPersonLevel'} || '',
        $rego_ref->{'strRegistrationNature'} || '',
        $originLevel,
        $entityRegisteringForLevel,
    );
       #$rego_ref->{'intOriginLevel'},
       # $entityRegisteringForLevel,

	my @uploaded_docs = ();
	while(my $dref = $sth->fetchrow_hashref()){		
        #push @uploaded_docs, $dref->{'intDocumentTypeID'};		
        if(! exists $existingDocuments{$dref->{'ID'}}){
            $existingDocuments{$dref->{'ID'}} = $dref;
        }
	}
	
	my @diff = ();	
       
	#compare whats in the system and what docos are missing both required and optional
	foreach my $doc_ref (@{$documents}){
    
		next if(!$doc_ref);	
        #next if(!$rego_ref->{'InternationalTransfer'} && $doc_ref->{'DocumentFor'} eq 'TRANSFERITC');	
		if(!grep /$doc_ref->{'ID'}/,@uploaded_docs){
			push @diff,$doc_ref;	
		}
	}

    my %PersonRef = ();
    $PersonRef{'strPersonType'} = $rego_ref->{'strPersonType'} || '';
    $PersonRef{'strAgeLevel'} = $rego_ref->{'strAgeLevel'} || '';
    my $personRegoNature = 'NEW';
    my $pref = Person::loadPersonDetails($Data->{'db'}, $personID);

    if ($pref->{'strStatus'} ne $Defs::PERSON_STATUS_INPROGRESS){
        $personRegoNature = 'RENEWAL';
    }
    
	my @required_docs_listing = ();
	my @optional_docs_listing = ();	
	my @validdocsforallrego = ();
## BAFF: Below needs WHERE tblRegistrationItem.strPersonType = XX AND tblRegistrationItem.strRegistrationNature=XX AND tblRegistrationItem.strAgeLevel = XX AND tblRegistrationItem.strPersonLevel=XX AND tblRegistrationItem.intOriginLevel = XX
	$query = qq[
        SELECT
            tblDocuments.intDocumentTypeID as ID,
            tblRegistrationItem.intUseExistingThisEntity as UseExistingThisEntity,
            tblRegistrationItem.intUseExistingAnyEntity as UseExistingAnyEntity,
            tblUploadedFiles.strOrigFilename,
            tblUploadedFiles.intFileID,
            tblUploadedFiles.intAddedByTypeID as AddedByTypeID,
            COALESCE (LT_D.strString1,tblDocumentType.strDocumentName) as Name,
            COALESCE(LT_D.strNote,tblDocumentType.strDescription) AS Description
        FROM 
            tblDocuments
            INNER JOIN tblDocumentType ON (tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID)
            INNER JOIN tblRegistrationItem ON (tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID )
            INNER JOIN tblUploadedFiles ON (tblUploadedFiles.intFileID = tblDocuments.intUploadFileID )
            LEFT JOIN tblLocalTranslations AS LT_D ON (
                LT_D.strType = 'DOCUMENT'
                AND LT_D.intID = tblDocumentType.intDocumentTypeID
                AND LT_D.strLocale = '$locale'
            )

        WHERE 
            strApprovalStatus IN ('APPROVED', 'PENDING')
            AND intPersonID = ?
            AND (tblRegistrationItem.intUseExistingThisEntity = 1 OR tblRegistrationItem.intUseExistingAnyEntity = 1) 
            AND tblRegistrationItem.intRealmID=?
            AND tblRegistrationItem.strItemType='DOCUMENT'
      AND tblRegistrationItem.strPersonType IN ('', ?)
     AND tblRegistrationItem.strPersonLevel IN ('', ?)
      AND tblRegistrationItem.strRegistrationNature IN ('', ?)
      AND tblRegistrationItem.strAgeLevel IN ('', ?)
     AND tblRegistrationItem.intOriginLevel = ?
     AND tblRegistrationItem.intEntityLevel = ?
        ORDER BY tblDocuments.intDocumentID DESC
    ];

	$sth = $Data->{'db'}->prepare($query);
	$sth->execute(
        $personID, 
        $Data->{'Realm'},
        $rego_ref->{'strPersonType'} || '',
        $rego_ref->{'strPersonLevel'} || '',
        $rego_ref->{'strRegistrationNature'} || '',
        $rego_ref->{'strAgeLevel'} || '',
        $originLevel,
        $entityRegisteringForLevel,
    );

	while(my $dref = $sth->fetchrow_hashref()){
        if(! exists $existingDocuments{$dref->{'ID'}}){
            $existingDocuments{$dref->{'ID'}} = $dref;
        }
	}

	foreach my $dc (@diff){   
		if($dc->{'Required'}){
			#check here 
            #next if( grep /$dc->{'ID'}/,@validdocsforallrego);
            if(defined $existingDocuments{$dc->{'ID'}}){
			    push @required_docs_listing, $existingDocuments{$dc->{'ID'}};
            }
            else {
			    push @required_docs_listing, $dc;
            }
		}  	
		else {
            if(defined $existingDocuments{$dc->{'ID'}}){
			    push @optional_docs_listing, $existingDocuments{$dc->{'ID'}};
            }
            else {
			    push @optional_docs_listing, $dc;
            }
		}
    	
    }

   
    
  my $cgi = new CGI;
  my $currentURL = $cgi->url(-full => 1, query => 1);
  my %PageData = (
        nextaction => "PREGF_DU",
        target => $Data->{'target'},
        documents => \@required_docs_listing,
	optionaldocs => \@optional_docs_listing,
        hidden_ref => $hidden_ref,
        Lang => $Data->{'lang'},
        client => $client,
        regoID => $regoID,
        NoFormFields =>$noFormFields,
	url => $Defs::base_url,
	currentURL => $currentURL,
	nature => $rego_ref->{'strRegistrationNature'},
  );
	my $pagedata = runTemplate($Data, \%PageData, 'registration/document_flow_backend.templ') || '';

    return $pagedata;
}

sub displayRegoFlowProducts {

    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref, $noFormFields) = @_;
    my $lang=$Data->{'lang'};

    my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
#    my $pref = loadPersonDetails($Data->{'db'}, $personID);
 #   $rego_ref->{'Nationality'} = $pref->{'strISONationality'};
    my $CheckProducts = getRegistrationItems(
        $Data,
        'REGO',
        'PRODUCT',
        $originLevel,
        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
        $entityID,
        $entityRegisteringForLevel,
        0,
        $rego_ref,
    );
	
    my @prodIDs = ();
	my $totalamountchk = 0;
    my %ProductRules=();
    foreach my $product (@{$CheckProducts})  {
        #next if($product->{'UseExistingThisEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'THIS_ENTITY'));
        #next if($product->{'UseExistingAnyEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'ANY_ENTITY'));

        $product->{'HaveForAnyEntity'} =1 if($product->{'UseExistingAnyEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'ANY_ENTITY'));
        $product->{'HaveForThisEntity'} =1 if($product->{'UseExistingThisEntity'} && checkExistingProduct($Data, $product->{'ID'}, $Defs::LEVEL_PERSON, $personID, $entityID, 'THIS_ENTITY'));
        if ($product->{'HaveForThisEntity'} == 1 or $product->{'HaveForAnyEntity'} == 1)    {
            next unless ($Data->{'SystemConfig'}{'Products_DontHideExisting'});
        }

        push @prodIDs, $product->{'ID'};
        $ProductRules{$product->{'ID'}} = $product;
		#$totalamountchk += $product->{'ProductPrice'};
		$totalamountchk += $product->{'ProductPrice'} if($product->{'Required'} && $product->{'ProductPrice'} > 0);
     }
    my $product_body='';
    if (@prodIDs)   {
        $product_body= getRegoProducts($Data, \@prodIDs, 0, $entityID, $regoID, $personID, $rego_ref, 0, \%ProductRules, 0, 0);

    }
    else    {
        return '';
    }
        my $displayPayment = $Data->{'SystemConfig'}{'AllowTXNs_CCs_roleFlow'};
        $displayPayment = 0 if ($Data->{'SelfRego'} and ! $Data->{'SystemConfig'}{'SelfRego_PaymentOn'});
	my $maObj = getInstanceOf($Data, 'national');
        my $maName = $maObj
            ? $maObj->name()
            : '';
		$rego_ref->{'MA'} = $maName || '';

    my ($termsId, $product_terms) = getTerms($Data, 'PRODUCT');
     my %PageData = (
        nextaction=>"PREGF_PU",
        target => $Data->{'target'},
        product_body => $product_body,
        mandatoryPayment => $displayPayment,
        hidden_ref=> $hidden_ref,
        Lang => $Data->{'lang'},
        client=>$client,
		amountCheck => $totalamountchk,
        NoFormFields =>$noFormFields,
		AssociationName => $maName,
		payMethod => $rego_ref->{'payMethod'},
		productTerms => $product_terms || '',
    );
	
    my $pagedata = runTemplate($Data, \%PageData, 'registration/product_flow_backend.templ') || '';

    return $pagedata;
}
sub displayRegoFlowProductsBulk {

    my ($Data, $regoID, $client, $entityRegisteringForLevel, $originLevel, $rego_ref, $entityID, $personID, $hidden_ref) = @_;
    my $lang=$Data->{'lang'};

    my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
    my $pref = Person::loadPersonDetails($Data->{'db'}, $personID);
    $rego_ref->{'Nationality'} = $pref->{'strISONationality'};
    my $CheckProducts = getRegistrationItems(
        $Data,
        'REGO',
        'PRODUCT',
        $originLevel,
        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
        $entityID,
        $entityRegisteringForLevel,
        0,
        $rego_ref,
    );
    my @prodIDs = ();
    my %ProductRules=();
	my $totalamountchk = 0;
    foreach my $product (@{$CheckProducts})  {
        push @prodIDs, $product->{'ID'};
        $ProductRules{$product->{'ID'}} = $product;
		$totalamountchk += $product->{'ProductPrice'} if($product->{'Required'} && $product->{'ProductPrice'} > 0);
     }
    my $product_body='';
    if (@prodIDs)   {
        $product_body= getRegoProducts($Data, \@prodIDs, 0, $entityID, $regoID, $personID, $rego_ref, 0, \%ProductRules, 0,1);
     }
    else    {
        return '';
    }

     my %PageData = (
        nextaction=>"PREGFB_PU",
        target => $Data->{'target'},
        product_body => $product_body,
        allowManualPay=> 0,
        mandatoryPayment => $Data->{'SystemConfig'}{'AllowTXNs_CCs_roleFlow'},
        manualPaymentTypes => \%Defs::manualPaymentTypes,
        hidden_ref=> $hidden_ref,
        Lang => $Data->{'lang'},
        NoFormFields =>1,
        client=>$client,
		amountCheck => $totalamountchk,
		payMethod => $rego_ref->{'payMethod'},
    );
    my $pagedata = runTemplate($Data, \%PageData, 'registration/product_flow_backend.templ') || '';

    return $pagedata;
}
 

sub generateRegoFlow_Gateways   {

    my ($Data, $client, $nextAction, $hidden_ref, $txn_invoice_url) = @_;

    my $lang = $Data->{'lang'};
    my ($paymentSettings, $paymentTypes) = getPaymentSettings($Data, 0, 0, $Data->{'clientValues'});
    my %gatewayBtns = ();
    my $gatewayCount = 0;
    my $paymentType = 0;
    foreach my $gateway (@{$paymentTypes})  {
        $gatewayCount++;
        my $pType = $gateway->{'paymentType'};
        $paymentType = $pType;
        last;
    }
    my $target = 'paytry.cgi';#$Data->{'target'};

    my $txnList = displayTXNToPay($Data, $hidden_ref->{'txnIds'}, $paymentSettings);
    if ($gatewayCount == 1) {
        $hidden_ref->{"pt_submit[1]"} = $paymentType; 
        $hidden_ref->{"cc_submit[1]"} = $paymentType; 
        $hidden_ref->{"gatewayCount"} = 1;
    }
    else    {
        $hidden_ref->{"gatewayCount"} = $gatewayCount;
    }
    $hidden_ref->{"client"} = $client;
    my $HiddenFields = '';
    foreach my $hf (keys %{$hidden_ref})    {
        next if $hf eq 'rfp';
        $HiddenFields .= qq[<input type="hidden" name="$hf" value="$hidden_ref->{$hf}">\n];
    }
    my %GatewayConfig= (
        nextaction=>$nextAction,
        Target => $target,
        txnList =>$txnList,
        ContinueBtns=> \%gatewayBtns,
        HiddenFields=> $HiddenFields,
        client=>$client,
		txn_invoice_url => $txn_invoice_url,
    );
    return \%GatewayConfig;
}

sub validateRegoID {
    my ($Data, $personID, $regoID, $entityID) = @_;

    my %Reg = (
        personRegistrationID => $regoID,
        entityID => $entityID || 0,
    );
    my ($count, $regs) = PersonRegistration::getRegistrationData(
        $Data, 
        $personID,
        \%Reg
    );
    if ($count) {
        return ($count, $regs->[0]);
    }
    return (0, undef);

}

sub save_rego_products {
    my ($Data, $regoID, $personID, $entityID, $entityLevel, $rego_ref, $params) = @_;

    my $session='';

    my $CheckProducts = getRegistrationItems(
        $Data,
        'REGO',
        'PRODUCT',
        $rego_ref->{'intOriginLevel'} || $rego_ref->{'originLevel'},
        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
        $entityID,
        $entityLevel,
        0,
        $rego_ref,
    );
    my ($txns_added, $amount) = insertRegoTransaction($Data, $regoID, $personID, $params, $entityID, $entityLevel, 1, $session, $CheckProducts);
    my $txnIds = join(':',@{$txns_added});
    return ($txnIds, $amount);
}


sub add_rego_record{
    my (
        $Data,
        $personID,
        $entityID,
        $entityLevel,
        $originLevel,
        $personType,
        $personEntityRole,
        $personLevel,
        $sport,
        $ageLevel,
        $registrationNature,
        $ruleFor,
        $nationality,
        $personRequestID,
        $MAComment
    ) = @_;

    my $clientValues = $Data->{'clientValues'};
    my $rego_ref = {
        status => 'INPROGRESS',
        personType => $personType || '',
        personEntityRole=> $personEntityRole || '',
        personLevel => $personLevel || '',
        sport => $sport || '',
        ageLevel => $ageLevel || '',
        registrationNature => $registrationNature || '',
        originLevel => $originLevel,
        originID => $entityID,
        entityID => $entityID,
        entityLevel => $entityLevel,
        personID => $personID,
        current => 1,
        ruleFor=>$ruleFor,
        personRequestID => $personRequestID,
        MAComment => $MAComment || '',
    };
    my ($personStatus, $prStatus) = PersonRegistration::checkIsSuspended($Data, $personID, $entityID, $rego_ref->{'personType'});
    return (0, undef, 'SUSPENDED') if ($personStatus eq 'SUSPENDED' or $prStatus eq 'SUSPENDED');
    	
    warn "REGISTRATION NATURE $rego_ref->{'registrationNature'}";
    if ($rego_ref->{'registrationNature'} ne 'RENEWAL'
        and $rego_ref->{'registrationNature'} ne 'TRANSFER'
        and $rego_ref->{'registrationNature'} ne 'DOMESTIC_LOAN') {
        print STDERR "ABOUT TO CHECK TYP LIMITS FOR : " . $rego_ref->{'sport'} . "|" . $rego_ref->{'personType'} . "|" . $rego_ref->{'personLevel'} . "|" . $rego_ref->{'entityID'} ."\n\n";
        my $ok = checkRegoTypeLimits($Data, $personID, 0, $rego_ref->{'sport'}, $rego_ref->{'personType'}, $rego_ref->{'personEntityRole'}, $rego_ref->{'personLevel'}, $rego_ref->{'ageLevel'}, $rego_ref->{'entityID'}); 
        return (0, undef, 'LIMIT_EXCEEDED') if (!$ok);
    }

    if ($rego_ref->{'registrationNature'} eq 'RENEWAL') {
        my $ok = PersonRegistration::checkRenewalRegoOK($Data, $personID, $rego_ref);
        return (0, undef, 'RENEWAL_FAILED') if (!$ok);
    }
    if ($rego_ref->{'registrationNature'} eq 'NEW') {
        my $ok = PersonRegistration::checkNewRegoOK($Data, $personID, $rego_ref);
        return (0, undef, 'NEW_FAILED') if (!$ok);
    }
	
    my ($regID,$rc) = PersonRegistration::addRegistration($Data,$rego_ref);
    if ($regID)     {
        return ($regID, $rego_ref, '');
    }
    return (0, undef, '');
}
sub bulkRegoCreate  {

    my ($Data, $bulk_ref, $rolloverIDs, $productIDs, $productQtys, $markPaid, $paymentType) = @_;
    my $body = 'Submitting';
    my @IDs= split /\|/, $rolloverIDs;

    my $totalAmount=0;
    my @total_txns_added=();
        my @Ages = ('ADULT',
            'MINOR'
    );

	#generate a single invoice number for each registration renewal	
	my $invoiceID = 0;
	if(!$Data->{'SystemConfig'}{'bulkRego_eachInvoice'}){		
		my $invoiceNumber;
		#Generate invoice number 
		my $stt = qq[INSERT INTO tblInvoice (tTimeStamp, intRealmID) VALUES (NOW(), $Data->{'Realm'})];
		my $qryy=$Data->{'db'}->prepare($stt); 
		$qryy->execute();
		$invoiceID =  $qryy->{mysql_insertid} || 0;	
		$invoiceNumber = Payments::TXNtoInvoiceNum($invoiceID); 

		$stt = qq[UPDATE tblInvoice SET strInvoiceNumber = ? WHERE intInvoiceID = ?];		
		$qryy=$Data->{'db'}->prepare($stt); 
		$qryy->execute($invoiceNumber,$invoiceID); 
		$qryy->finish();
	}

    my %RegoIDs=();
    for my $pID (@IDs)   {
        my %Rego=();
        %Rego = %{$bulk_ref};
        $Rego{'intPersonID'} = $pID;
        my $personObj = new PersonObj(db => $Data->{'db'}, ID => $pID, cache => $Data->{'cache'});
        $personObj->load();
        $Rego{'Nationality'} = $personObj->getValue('strISONationality') || '';
        $Rego{'DOB'} = $personObj->getValue('dtDOB_Format') || '';
        my $CheckProducts = getRegistrationItems(
            $Data,
            'REGO',
            'PRODUCT',
            $bulk_ref->{'originLevel'},
            $bulk_ref->{'registrationNature'},
            $bulk_ref->{'entityID'},
            $bulk_ref->{'entityLevel'},
            0,
            \%Rego,
        );
        my %AllowedProducts=();
        my @productIDsAllowed=();

    my %ProductRules=();
         foreach my $product (@{$CheckProducts})  {
            #my $productPrice = $product->{'ProductPrice'};
            push @productIDsAllowed, $product->{'ID'};
            $ProductRules{$product->{'ID'}} = $product;
        }

        my $pref = Person::loadPersonDetails($Data->{'db'}, $pID) if ($pID);
        my $ageLevelOptions = checkRegoAgeRestrictions(
            $Data,
            $pID,
            0,
            $bulk_ref->{'sport'},
            $bulk_ref->{'personType'},
            $bulk_ref->{'personEntityRole'},
            $bulk_ref->{'personLevel'},
            @Ages
        );
        
        $bulk_ref->{'ageLevel'}='';
        if (defined $ageLevelOptions)   {
            $bulk_ref->{'ageLevel'}=$ageLevelOptions->[0]{'value'};#'ADULT';
        }
        my ($regoID, $rego_ref, $msg) = add_rego_record(
            $Data, 
            $pID, 
            $bulk_ref->{'entityID'}, 
            $bulk_ref->{'entityLevel'}, 
            $bulk_ref->{'originLevel'}, 
            $bulk_ref->{'personType'}, 
            $bulk_ref->{'personEntityRole'}, 
            $bulk_ref->{'personLevel'}, 
            $bulk_ref->{'sport'}, 
            $bulk_ref->{'ageLevel'}, 
            $bulk_ref->{'registrationNature'},
            "BULKREGO"
        );
        next if (! $regoID);
        # Now lets see what products are allowed
        my $AllowedRegoProducts = getRegoProducts($Data, \@productIDsAllowed, 0, $bulk_ref->{'entityID'}, $regoID, $pID, \%Rego, 0, \%ProductRules, 1, 0);
        
        foreach my $productIDAllowed (@{$AllowedRegoProducts}) {
            $AllowedProducts{$productIDAllowed->{'ProductID'}} = 1;
        }
            
	    cleanRegoTransactions($Data,$regoID, $pID, $Defs::LEVEL_PERSON);
        $RegoIDs{$pID} = $regoID;
        WorkFlow::cleanTasks(
            $Data,
            $pID,
            $bulk_ref->{'entityID'},
            $regoID,
            'REGO'
        );
        my @products = split /\:/, $productIDs;
        my %Products=();
        foreach my $product (@products) {
            next if ! $AllowedProducts{$product};
            $Products{'prod_'.$product} =1;
        }
        my @productQty= split /:/, $productQtys;
        foreach my $prodQty (@productQty){
            my ($prodID, $qty) = split /-/, $prodQty;
            $Products{"prodQTY_$prodID"} =$qty;
        }
		#generate individual invoice number for each registration renewal
		if($Data->{'SystemConfig'}{'bulkRego_eachInvoice'}){
			my $invoiceNumber = 0;
			#Generate invoice number 
			my $stt = qq[INSERT INTO tblInvoice (tTimeStamp, intRealmID) VALUES (NOW(), $Data->{'Realm'})];
			my $qryy=$Data->{'db'}->prepare($stt); 
			$qryy->execute();
			$invoiceID =  $qryy->{mysql_insertid} || 0;	
			$invoiceNumber = Payments::TXNtoInvoiceNum($invoiceID); 

			$stt = qq[UPDATE tblInvoice SET strInvoiceNumber = ? WHERE intInvoiceID = ?];		
			$qryy=$Data->{'db'}->prepare($stt); 
			$qryy->execute($invoiceNumber,$invoiceID); 
			$qryy->finish();
		}

        my ($txns_added, $amount) = insertRegoTransaction(
            $Data, 
            $regoID, 
            $pID, 
            \%Products, 
            $bulk_ref->{'entityID'}, 
            $bulk_ref->{'entityLevel'}, 
            $Defs::LEVEL_PERSON, 
            '',
            $CheckProducts,
			$invoiceID
        );
        $totalAmount = $totalAmount + $amount;
        push @total_txns_added, @{$txns_added};
        ## Below was for each to have their own tblTransLog
        #if ($paymentType and $markPaid)  {
        #    my %Settings=();
        #    $Settings{'paymentType'} = $paymentType;
        #    my $logID = createTransLog($Data, \%Settings, $bulk_ref->{'entityID'},$txns_added, $amount); 
        #    UpdateCart($Data, undef, $Data->{'client'}, undef, undef, $logID);
        #    product_apply_transaction($Data,$logID);
        #}
        #  savePlayerPassport($Data, $pID);
    }
    if (scalar(@total_txns_added) and $paymentType and $markPaid)  {
        my %Settings=();
        $Settings{'paymentType'} = $paymentType;
        my $logID = createTransLog($Data, \%Settings, $bulk_ref->{'entityID'},\@total_txns_added, $totalAmount);
        processTransLog($Data->{'db'}, '', 'OK', 'OK', 'APPROVED', $logID, \%Settings, undef, undef, '', '', '', '', '', '','',1);
        UpdateCart($Data, undef, $Data->{'client'}, undef, 'OK', $logID);
        product_apply_transaction($Data,$logID);
    }
    my $txnIds = join(':',@total_txns_added);    
 
    return ($totalAmount, $txnIds, \%RegoIDs);
}

sub bulkRegoSubmit {

    my ($Data, $bulk_ref, $rolloverIDs) = @_;

    my $body = 'Submitting';
    my @IDs= split /\|/, $rolloverIDs;

    for my $pID (@IDs)   {
        my $pref = Person::loadPersonDetails($Data->{'db'}, $pID) if ($pID);
        my $regoID=param('regoID_'.$pID);
        next if (! $regoID);
        #cleanTasks(
        #    $Data,
        #    $pID,
        #    $bulk_ref->{'entityID'},
        #    $regoID,
        #    'REGO'
        #);
	
       my ($txnCount, $amountDue, $logIDs, $originalAmount) = getPersonRegoTXN($Data, $pID, $regoID);
	my %Reg = ();
	$Reg{'CountTXNs'} = $txnCount;
	
       PersonRegistration::submitPersonRegistration(
            $Data,
            $pID,
            $regoID,
            \%Reg
        );
        savePlayerPassport($Data, $pID);
            if (! $originalAmount and defined $logIDs) {
                foreach my $id (keys %{$logIDs}) {
                    next if ! $id;
                    product_apply_transaction($Data, $id);
                }
            }
    }
}

#sub checkingBulkRenewalProducts {
#
#
# my $CheckProducts = getRegistrationItems(
#        $Data,
#        'REGO',
#        'PRODUCT',
#        $originLevel,
#        $rego_ref->{'strRegistrationNature'} || $rego_ref->{'registrationNature'},
#        $entityID,
#        $entityRegisteringForLevel,
#        0,
#        $rego_ref,
#    );
#
#}
1;

