package HomePerson;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(showPersonHome);
@EXPORT_OK =qw(showPersonHome);

use strict;
use lib "..","../..";
use Reg_common;
use Utils;
use InstanceOf;

use Photo;
use TTTemplate;
use Notifications;
use FormHelpers;
#use Seasons;
use PersonRegistration;
use UploadFiles;
use Log;
use Person;
use NationalReportingPeriod;
use DuplicatesUtils;
use Data::Dumper;
use PersonSummaryPanel;
use WorkFlow;
use PersonUtils;
require AccreditationDisplay;

sub showPersonHome	{
	my ($Data, $personID, $FieldDefinitions, $memperms)=@_;
	my $client = $Data->{'client'} || '';
	my $personObj = getInstanceOf($Data, 'person');
	my $allowedit = allowedAction($Data, 'p_e') ? 1 : 0;

	my $cl = setClient($Data->{'clientValues'}) || '';
    my %cv = getClient($cl);
    $cv{'personID'} = $personID;
    $cv{'currentLevel'} = $Defs::LEVEL_PERSON;
    my $clm = setClient(\%cv);


	my $notifications = [];
	my %configchanges = ();
	if ( $Data->{'SystemConfig'}{'PersonFormReLayout'} ) {
        	%configchanges = eval( $Data->{'SystemConfig'}{'PersonFormReLayout'} );
    	}

	my ($fields_grouped, $groupdata) = getMemFields($Data, $personID, $FieldDefinitions, $memperms, $personObj, \%configchanges);
	my ($photo,undef)=handle_photo('P_PH_s',$Data,$personID);
	#my $name = $personObj->name();
	my $name = formatPersonName($Data,$personObj->getValue('strLocalFirstname'),$personObj->getValue('strLocalSurname'),'');
	my $markduplicateURL = '';
	my $adddocumentURL = '';
	my $cardprintingURL = '';
	if(allowedAction($Data, 'm_e'))	{
		if(!$Data->{'SystemConfig'}{'LockPerson'}){
			$adddocumentURL = "$Data->{'target'}?client=$client&amp;a=DOC_L";
			if(DuplicatesUtils::isCheckDupl($Data))	{
				#$markduplicateURL = "$Data->{'target'}?client=$client&amp;a=P_DUP_";
			}
		}
		#if($Data->{'SystemConfig'}{'AllowCardPrinting'})	{
		#	$cardprintingURL = "$Data->{'target'}?client=$client&amp;a=MEMCARD_MLIST";
	#}
		if($Data->{'SystemConfig'}{'AllowCardPrinting'} and
			 ($Data->{'clientValues'}{'authLevel'} > $Defs::LEVEL_CLUB or 
				($Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_CLUB and !$Data->{'SystemConfig'}{'AssocConfig'}->{'DisableClubCardPrinting'}))){
					
					$cardprintingURL = "$Data->{'target'}?client=$client&amp;a=MEMCARD_MLIST";
		}

	}
        my $addregistrationURL = "$Data->{'target'}?client=$client&amp;a=PF_&rfp=r&amp;_ss=r&amp;es=1";
	my $accreditations = ($Data->{'SystemConfig'}{'NationalAccreditation'}) ? AccreditationDisplay::ActiveNationalAccredSummary($Data, $personID) : '';#ActiveAccredSummary($Data, $personID, $Data->{'clientValues'}{'assocID'});

    my $readonly = !( ($personObj->getValue('strStatus') eq 'REGISTERED' ? 1 : 0) || ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 ) );
    $Data->{'ReadOnlyLogin'} ? $readonly = 1 : undef;

    #print STDERR Dumper $personObj;
    my $enableRenew = 1;
    my $enableAdd = 1;
    my $enableCancelLoan = 1;

    $enableRenew = $enableAdd = 0 if $personObj->getValue('strStatus') ne $Defs::PERSON_STATUS_REGISTERED;

    my $c = Countries::getISOCountriesHash();
    
	my %TemplateData = (
        Lang => $Data->{'lang'},
		Name => $name,
		ReadOnlyLogin => $readonly,
		EditDetailsLink => showLink($personID,$client,$Data),
		Notifications => $notifications,
		Photo => $photo,
		MarkDuplicateURL => $markduplicateURL || '',
		AddDocumentURL => $adddocumentURL || '',
		AddRegistrationURL => $addregistrationURL || '',
		CardPrintingURL => $cardprintingURL || '',
		GroupData => $groupdata,		
	    client => $client,
	    url => "$Defs::base_url/viewer.cgi",
        enableRenew => $enableRenew,
        enableAdd => $enableAdd,
		Details => {
			Active => $Data->{'lang'}->txt(($personObj->getValue('intRecStatus') || '') ? 'Yes' : 'No'),
			strLocalFirstname => $personObj->getValue('strLocalFirstname') || '',
       		strLocalSurname => $personObj->getValue('strLocalSurname') || '',
       		strMaidenName => $personObj->getValue('strMaidenName') || '',
			LatinFirstname=> $personObj->getValue('strLatinFirstname') || '',	
			LatinSurname=> $personObj->getValue('strLatinSurname') || '',	
			Address1 => $personObj->getValue('strAddress1') || '',	
			Address2 => $personObj->getValue('strAddress2') || '',	
			Suburb => $personObj->getValue('strSuburb') || '',	
			State => $personObj->getValue('strState') || '',	
			Country => $personObj->getValue('strISOCountry') || '',
			PostalCode => $personObj->getValue('strPostalCode') || '',	
			PhoneHome => $personObj->getValue('strPhoneHome') || '',	
			Email => $personObj->getValue('strEmail') || '',	
			Gender => $Data->{'lang'}->txt($Defs::genderInfo{$personObj->getValue('intGender') || 0}) || '',
			DOB => $personObj->getValue('dtDOB') || '',
			NationalNum => $personObj->getValue('strNationalNum') || '',
			BirthCountry => $personObj->getValue('strISOCountryOfBirth') || '',
			PassportNat => $personObj->getValue('strPassportNationality') || '',
			Status => $personObj->getValue('strStatus') || '',
			Nationality => $c->{$personObj->getValue('strISONationality')},
			intGender => $personObj->getValue('intGender'),
		},
        SummaryPanel => personSummaryPanel($Data, $personID) || '',
	);
	
    my %RegFilters=();
    #$RegFilters{'current'} = 1;
    my @statusIN = ($Defs::PERSONREGO_STATUS_PENDING, $Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_PASSIVE); #, $Defs::PERSONREGO_STATUS_TRANSFERRED, $Defs::PERSONREGO_STATUS_SUSPENDED);
    #$RegFilters{'entityID'} = getLastEntityID($Data->{'clientValues'});
    #$Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? push @statusIN, $Defs::PERSONREGO_STATUS_DELETED : undef;
    
    $RegFilters{'statusIN'} = \@statusIN;
    my ($RegCount, $Reg_ref) = PersonRegistration::getRegistrationData($Data, $personID, \%RegFilters);
	my $status;
	
	my $rego;
    
    foreach $rego (@{$Reg_ref})  {
        my %getwtparams = (
            type => 'PERSON',
            registrationid => $rego->{'intPersonRegistrationID'},
            personid => $rego->{'intPersonID'},
        );

        my $workTaskHistory = WorkFlow::getRegistrationWorkTasks($Data, \%getwtparams);
        $rego->{'worktaskhistory'} = $workTaskHistory;

		my @alldocs = ();
		my $fileID = 0;
		my $doc;
		my $viewLink;
		my $replaceLink;
		my $addLink; 
		my $displayView = 0;
		my $displayAdd = 0;
		my $displayReplace = 0;

        my @regoworktasks = ();
        #push @regoworktask
#BAFF
	    my @validdocsforallrego = ();
	    my %validdocs = ();
	    my $query = qq[
            SELECT 
                DISTINCT
                tblDocuments.strApprovalStatus,
                tblDocuments.intDocumentTypeID,
                tblDocumentType.strActionPending,
                tblDocuments.intUploadFileID
            FROM 
                tblDocuments 
                INNER JOIN tblDocumentType ON (tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID) 
                INNER JOIN tblRegistrationItem ON (tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID )
            WHERE 
                strApprovalStatus IN ('PENDING', 'APPROVED') 
                AND intPersonID = ? 
                AND tblRegistrationItem.intRealmID=? 
                AND tblRegistrationItem.strItemType='DOCUMENT' 
                AND (tblRegistrationItem.intUseExistingThisEntity = 1 OR tblRegistrationItem.intUseExistingAnyEntity = 1) 
                AND tblRegistrationItem.strPersonType IN ('', ?)
                AND tblRegistrationItem.strRegistrationNature IN ('', ?)
                AND tblRegistrationItem.strAgeLevel IN ('', ?)
                AND tblRegistrationItem.strPersonLevel IN ('', ?)
                AND tblRegistrationItem.intOriginLevel = ?
                AND tblRegistrationItem.intEntityLevel = ?
                AND (tblRegistrationItem.intItemForInternationalTransfer = 0 OR tblRegistrationItem.intItemForInternationalTransfer = ?)
                AND (tblRegistrationItem.intItemForInternationalLoan = 0 OR tblRegistrationItem.intItemForInternationalLoan = ?)
            ORDER BY 
                tblDocuments.tTimeStamp DESC, 
                tblDocuments.intUploadFileID DESC
    ];

    my $internationalTransfer = ($rego->{'intNewBaseRecord'} and $rego->{'intInternationalTransfer'}) ? 1 : 0;
    my $internationalLoan = ($rego->{'intNewBaseRecord'} and $rego->{'intInternationalLoan'}) ? 1 : 0;

	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute(
        $personID, 
        $Data->{'Realm'},
        $rego->{'strPersonType'} || '',
        $rego->{'strRegistrationNature'} || '',
        $rego->{'strAgeLevel'} || '',
        $rego->{'strPersonLevel'} || '',
        $rego->{'intOriginLevel'}, 
        $rego->{'intEntityLevel'}, 
        $internationalTransfer,
        $internationalLoan,
    );

	while(my $dref = $sth->fetchrow_hashref()){
        next if $dref->{'strApprovalStatus'} ne 'APPROVED';
        next if exists $validdocs{$dref->{'intDocumentTypeID'}};
		push @validdocsforallrego, $dref->{'intDocumentTypeID'};
		$validdocs{$dref->{'intDocumentTypeID'}} = $dref->{'intUploadFileID'};
	}
		foreach $doc (@{$rego->{'documents'}}) {			
			$displayAdd = 0;
			$fileID = 0;
			$displayView  = 0;			
			$status = $doc->{'strApprovalStatus'};
			if(!$doc->{'strApprovalStatus'}){ 			  
				if(!grep /$doc->{'intDocumentTypeID'}/,@validdocsforallrego){  
					$displayAdd = 1; 
					$fileID = 0;
					if($doc->{'Required'}){				
						$status = 'MISSING';
					}
					else {
						$status = $Data->{'lang'}->txt('Optional. Not Provided');
						$displayReplace = 0;
					}
				}
				elsif(grep /$doc->{'intDocumentTypeID'}/,@validdocsforallrego){
					$status = 'APPROVED';
					$fileID = $validdocs{$doc->{'intDocumentTypeID'}};
				}
			
			}
			else{
				$displayReplace = 1;
				$displayAdd = 0;
				$doc->{'intUploadFileID'} ? $fileID = $doc->{'intUploadFileID'} : 0;
			
       		}
			#####
		my $documentName = $doc->{'strDocumentName'};
		$documentName =~ s/'/\\\'/g;

		my $parameters = qq[&amp;client=$clm&doctype=$doc->{'intDocumentTypeID'}&pID=$personID&regoID=$rego->{'intPersonRegistrationID'}&nff=1];
		

		if($fileID) {
			$displayView = 1;
            $viewLink = qq[ <span style="position: relative"><a href="#" class="btn-inside-docs-panel" onclick="docViewer($fileID,'client=$clm&amp;a=view');return false;">]. $Data->{'lang'}->txt('View') . q[</a></span>];
        }
		$replaceLink = qq[ <span style="position: relative"><a href="#" class="btn-inside-docs-panel" onclick="replaceFile($fileID,'$parameters','$documentName','');return false;">]. $Data->{'lang'}->txt('Replace') . q[</a></span>];
		$addLink = qq[ <a href="#" class="btn-inside-docs-panel" onclick="replaceFile(0,'$parameters','$documentName','');return false;">]. $Data->{'lang'}->txt('Add') . q[</a>] if (!$Data->{'ReadOnlyLogin'});

        if($doc->{'strLockAtLevel'})   {
            if($doc->{'strLockAtLevel'} =~ /\|$Data->{'clientValues'}{'authLevel'}\|/ and getLastEntityID($Data->{'clientValues'}) != $doc->{'DocoEntityID'}){ 
                    #$viewLink = qq[ <button class\"HTdisabled\">]. $Data->{'lang'}->txt('View') . q[</button>];
                    #$replaceLink =   qq[ <button class\"HTdisabled\">]. $Data->{'lang'}->txt('Replace File'). q[</button>];
                    $viewLink= qq[ <span style="position: relative"><a class="HTdisabled btn-inside-docs-panel btn-view-replace">].$Data->{'lang'}->txt('View'). q[</a></span>];
                    $replaceLink= qq[ <span style="position: relative"><a class="HTdisabled btn-inside-docs-panel btn-view-replace">].$Data->{'lang'}->txt('Replace'). q[</a></span>];
            }
        }

        if ($rego->{'intEntityID'} != getLastEntityID($Data->{'clientValues'}) && $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB)    {
            $replaceLink = '';
            $replaceLink= qq[ <span style="position: relative"><a class="HTdisabled btn-inside-docs-panel btn-view-replace">].$Data->{'lang'}->txt('Replace'). q[</a></span>];
        }
		#
		next if(!$doc->{'strApprovalStatus'} && (!grep /$doc->{'intDocumentTypeID'}/,@validdocsforallrego) && ($doc->{'strDocumentName'} eq 'ITC'));		
		#
		
		push @{$rego->{'alldocs'}},{
				strDocumentName => $doc->{'strDocumentName'}, 
				Status => $status,
				DocumentType => $doc->{'intDocumentTypeID'},
				viewLink => $viewLink,
           	    addLink => $addLink,
           		replaceLink => $replaceLink,
				DisplayView => $displayView,
				DisplayAdd => $displayAdd || '',
				DisplayReplace => $displayReplace,
				
			};

		} #end for looping through registration documents
		

		
		my $renew = '';
		my $changelevel= '';
        $rego->{'renew_link'} = '';
        $rego->{'changelevel_link'} = '';
        $rego->{'cancel_loan_link'} = '';

    
        #next if ($rego->{'intEntityID'} != getLastEntityID($Data->{'clientValues'}) and $Data->{'authLevel'} != $Defs::LEVEL_NATIONAL);
        ## Show MA the renew link remvoed as we need them to navigate to the club level for now
        next if ($rego->{'strStatus'} !~ /$Defs::PERSONREGO_STATUS_ACTIVE|$Defs::PERSONREGO_STATUS_PASSIVE/);

        #enable early deactivation of a player loan
        if($rego->{'intPersonRequestID'} and $rego->{'intOnLoan'} and $rego->{'strStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE and ($Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL)) {
            $rego->{'cancel_loan_link'} =  "$Data->{'target'}?client=$client&amp;a=PRA_CL&amp;prqid=$rego->{'intPersonRequestID'}&amp;pid=$rego->{'intPersonID'}";
        }

        next if ($rego->{'intEntityID'} != getLastEntityID($Data->{'clientValues'}));
        #my $ageLevel = $rego->{'strAgeLevel'}; #'ADULT'; ## HERE NEEDS TO CALCULATE IF MINOR/ADULT
        my $newAgeLevel = '';

		
        if ($rego->{'strAgeLevel'}) { 
            $newAgeLevel = Person::calculateAgeLevel($Data, $rego->{'currentAge'});
        }
        my ($nationalPeriodID, undef, undef) = getNationalReportingPeriod($Data->{db}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $rego->{'strSport'}, $rego->{'personType'}, 'RENEWAL');
        $renew = $Data->{'target'} . "?client=$client&amp;a=PF_&amp;pID=$rego->{'intPersonID'}&amp;dnat=RENEWAL&amp;rtargetid=$rego->{'intPersonRegistrationID'}&amp;_ss=r&amp;rfp=r&amp;dsport=$rego->{'strSport'}&amp;dtype=$rego->{'strPersonType'}&amp;dentityrole=$rego->{'strPersonEntityRole'}&amp;nat=RENEWAL"; ## TO default the PersonLevel dlevel=$rego->{'strPersonLevel'}
        if ($rego->{'intOnLoan'})   {
            $renew .= "&amp;dlevel=$rego->{'strPersonLevel'}";
        }


        if (! $rego->{'intOnLoan'} && $Data->{'SystemConfig'}{'changeLevel_' . $rego->{'strPersonType'}})  {
            $changelevel= "$Data->{'target'}?client=$client&amp;a=PF_&rfp=r&amp;_ss=r&amp;es=1&amp;dtype=$rego->{'strPersonType'}&amp;dsport=$rego->{'strSport'}&amp;dentityrole=$rego->{'strPersonEntityRole'}&nat=NEW&dnat=NEW&amp;oldlevel=$rego->{'strPersonLevel'}";
        }
        $rego->{'changelevel_link'} = $changelevel;
        my $pType = $Data->{'lang'}->txt($Defs::personType{$rego->{'strPersonType'}});
        $rego->{'changelevel_button'} = $Data->{'lang'}->txt("Change [_1] Level", $pType);

        $rego->{'Status'} = (($rego->{'strStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE) and $rego->{'intPaymentRequired'}) ? $Defs::personRegoStatus{$Defs::PERSONREGO_STATUS_ACTIVE_PENDING_PAYMENT} : $rego->{'Status'};
        next if ($rego->{'intNationalPeriodID'} == $nationalPeriodID and $rego->{'intIsLoanedOut'} == 0);


        #FC-1105 - disable renewal from lending club if loan isn't completed yet
        #check PersonRequest::deactivatePlayerLoan
        $rego->{'intOnLoan'} ||= 0;
        $rego->{'existOpenLoan'} ||= 0;
        if(
            ($rego->{'intIsLoanedOut'} == 0 and $rego->{'intOnLoan'} == 0)
            or ($rego->{'intIsLoanedOut'} == 1 and $rego->{'existOpenLoan'} == 0)
            or ($rego->{'intOnLoan'} == 1 and $rego->{'intOpenLoan'} == 1)) {
            $rego->{'renew_link'} = $renew;
        }
        else    {
            $rego->{'renew_link'} = '';
            $rego->{'changelevel_link'} = '';
        }

    }
	
	#$Reg_ref->[0]{'documents'} = \@reg_docs;
	#push @{$Reg_ref},\%reg_docs; $personID
    PersonRegistration::hasPendingRegistration($Data, $personID, undef, $Reg_ref);
    PersonRegistration::hasPendingTransferRegistration($Data,$personID,undef, $Reg_ref);
    $TemplateData{'RegistrationInfo'} = $Reg_ref;
	

	my $statuspanel= runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/personregistration.templ',
	);
	$TemplateData{'StatusPanel'} = $statuspanel || '';
	
	my $resultHTML = runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/person.templ',
	);

  $Data->{'NoHeadingAd'} = 1;

	my $title = $name;
	return ($resultHTML, '');
}

sub getMemFields {
	my ($Data, $personID, $FieldDefinitions, $memperms, $personObj, $override_config) = @_;
	my %fields_grouped = ();
	my %fields = ();
	my %nolabelfields = (
		strAddress1 => 1,
		strAddress2 => 1,
		strSuburb => 1,
		strCityOfResidence => 1,
		strState => 1,
		strPostalCode => 1,
		strISOCountry => 1,
	);
	if(scalar($FieldDefinitions)>1){
	
	my @fieldorder=(defined $override_config and exists $override_config->{'order'} and $override_config->{'order'}) ? @{$override_config->{'order'}} : @{$FieldDefinitions->{'order'}};
	for my $f (@fieldorder) 	{
		next if (exists $memperms->{$f} and !$memperms->{$f});
		my $label = $FieldDefinitions->{'fields'}{$f}{'label'} || next;
		my $group=(defined $override_config and exists $override_config->{'sectionname'} and $override_config->{'sectionname'}{$f}) ? $override_config->{'sectionname'}{$f} ||''  : ($FieldDefinitions->{'fields'}{$f}{'sectionname'}  || 'main');
        my $is_header = ($FieldDefinitions->{'fields'}{$f}{'type'} eq 'header') ? 1 : 0;
        
		my $val = $FieldDefinitions->{'fields'}{$f}{'value'} || $personObj->getValue($f) || '';
		if($FieldDefinitions->{'fields'}{$f}{'options'})	{
			$val = $Data->{'lang'}->txt($FieldDefinitions->{'fields'}{$f}{'options'}{$val} || $val);
		}
		if($FieldDefinitions->{'fields'}{$f}{'displaylookup'})	{
			$val = $Data->{'lang'}->txt($FieldDefinitions->{'fields'}{$f}{'displaylookup'}{$val} || $val);
		}
		push @{$fields_grouped{$group}}, [$f, $label];
		my $string = '';
        if($f =~/^dt/)  {
            if($f eq 'dtLastUpdate')    {
                $val = $Data->{'l10n'}{'date'}->TZformat($val,'MEDIUM','MEDIUM');
            }
            else    {
                $val = $Data->{'l10n'}{'date'}->format($val,'MEDIUM');
            }
        }
		if (($val and $val ne '00/00/0000') or ($is_header))	{
			$string .= qq[<div class=""><span class = "details-left">$label:</span>] if !$nolabelfields{$f};
			if(length($label) >= 100)  {
				$string .= '<span class="detail-value"><br/>'.$val.'</span></div>';
			}else{
				$string .= '<span class="detail-value">'.$val.'</span></div>';
			}
			$fields{$group} .= $string;
		}
	}}
	return (\%fields_grouped, \%fields);
}

sub deregistration_check___duplicated {
        my ($personID,$type,$Data)=@_;
        my $db=$Data->{'db'};
        my $st = qq[
                SELECT *
                FROM tblPerson_Types
                WHERE intPersonID=$personID
                        AND intTypeID=$type
                        AND intSubTypeID=0
        ];
        my $q = $db->prepare($st);
        $q->execute();
        my $dref = $q->fetchrow_hashref();
        if ($type == $Defs::PERSON_TYPE_COACH && $dref->{intInt1}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> COACH DEREGISTERED</div>];
        }
        elsif ($type == $Defs::PERSON_TYPE_UMPIRE && $dref->{intInt2}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> UMPIRE DEREGISTERED</div>];
        }
        elsif ($type == $Defs::PERSON_TYPE_MISC && $dref->{intInt2}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> MISC DEREGISTERED</div>];
        }
        elsif ($type == $Defs::PERSON_TYPE_VOLUNTEER && $dref->{intInt2}) {
                return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> VOLUNTEER DEREGISTERED</div>];
        }
        else {
                return 0;
        }
}

sub showLink {
        my ($personID,$client,$Data) = @_;
           
        #check person level 
        my $url = "$Data->{'target'}?client=$client&amp;a=PE_";
        return $url if ($Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL);     
        my %Reg=();
        $Reg{'entityID'} = getLastEntityID($Data->{'clientValues'});
        my $field = Person::loadPersonDetails($Data->{'db'},$personID); 
        if(($field->{'strStatus'} eq $Defs::PERSON_STATUS_REGISTERED || $field->{'strStatus'} eq $Defs::PERSON_STATUS_PENDING || $field->{'strStatus'} eq $Defs::PERSON_STATUS_DUPLICATE) && PersonRegistration::isPersonRegistered($Data,$personID,\%Reg)){
            return  $url; 
        } 
        return undef;
}
1;
