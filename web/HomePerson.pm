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
	my $name = $personObj->name();
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
		Details => {
			Active => $Data->{'lang'}->txt(($personObj->getValue('intRecStatus') || '') ? 'Yes' : 'No'),
			strLocalFirstname => $personObj->getValue('strLocalFirstname') || '',
       		strLocalSurname => $personObj->getValue('strLocalSurname') || '',
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
			Nationality => $c->{$personObj->getValue('strISONationality')}
		},
        SummaryPanel => personSummaryPanel($Data, $personID) || '',
	);
	
	my @validdocsforallrego = ();
	my %validdocs = ();
	my $query = qq[SELECT tblDocuments.intDocumentTypeID, tblDocuments.intUploadFileID FROM tblDocuments INNER JOIN tblDocumentType
				ON tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID INNER JOIN tblRegistrationItem 
				ON tblDocumentType.intDocumentTypeID = tblRegistrationItem.intID 
				WHERE strApprovalStatus = 'APPROVED' AND intPersonID = ? AND 
				(tblRegistrationItem.intUseExistingThisEntity = 1 OR tblRegistrationItem.intUseExistingAnyEntity = 1) 
				GROUP BY intDocumentTypeID];
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($personID);
	while(my $dref = $sth->fetchrow_hashref()){
		push @validdocsforallrego, $dref->{'intDocumentTypeID'};
		$validdocs{$dref->{'intDocumentTypeID'}} = $dref->{'intUploadFileID'};
	}
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
		my @alldocs = ();
		my $fileID = 0;
		my $doc;
		my $viewLink;
		my $replaceLink;
		my $addLink; 
		my $displayView = 0;
		my $displayAdd = 0;
		my $displayReplace = 0;
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
						#$documentStatusCount{'MISSING'}++;
						$status = 'MISSING';
					}
					else {
						$status = 'Optional. Not Provided.';
						$displayReplace = 0;
					}
				}
				elsif(grep /$doc->{'intDocumentTypeID'}/,@validdocsforallrego){
					$status = 'APPROVED';
					#$documentStatusCount{'APPROVED'}++;
					$fileID = $validdocs{$doc->{'intDocumentTypeID'}};
				}
			
			}
			else{
				#$documentStatusCount{$tdref->{'strApprovalStatus'}}++;
				$displayReplace = 1;
				$displayAdd = 0;
				$doc->{'intUploadFileID'} ? $fileID = $doc->{'intUploadFileID'} : 0;
			
       		}
			#####
		my $documentName = $doc->{'strDocumentName'};
		$documentName =~ s/[\/*?:@&=+$#']/_/g;

		if($fileID) {
			$displayView = 1;
            $viewLink = qq[ <span style="position: relative"> 
<a href="#" class="btn-inside-docs-panel" onclick="docViewer($fileID,'client=$clm&amp;a=view');return false;">]. $Data->{'lang'}->txt('View') . q[</a></span>];			
        }

		$replaceLink = qq[ <span style="position: relative"><a href="#" class="btn-inside-docs-panel" onclick="replaceFile($fileID,$doc->{'intDocumentTypeID'}, $rego->{'intPersonRegistrationID'}, $personID, '$clm', '$documentName', ' ');return false;">]. $Data->{'lang'}->txt('Replace') . q[</a></span>]; 


		$addLink = qq[ <a href="#" class="btn-inside-docs-panel" onclick="replaceFile(0,$doc->{'intDocumentTypeID'}, $rego->{'intPersonRegistrationID'}, $personID, '$clm','$documentName',' ');return false;">]. $Data->{'lang'}->txt('Add') . q[</a>] if (!$Data->{'ReadOnlyLogin'});

		#push @alldocs, { . " - $rego->{intPersonRegistrationID} "
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
        $rego->{'renew_link'} = '';
        #next if ($rego->{'intEntityID'} != getLastEntityID($Data->{'clientValues'}) and $Data->{'authLevel'} != $Defs::LEVEL_NATIONAL);
        ## Show MA the renew link remvoed as we need them to navigate to the club level for now
        next if ($rego->{'intEntityID'} != getLastEntityID($Data->{'clientValues'}));
        next if ($rego->{'strStatus'} !~ /$Defs::PERSONREGO_STATUS_ACTIVE|$Defs::PERSONREGO_STATUS_PASSIVE/);
        #my $ageLevel = $rego->{'strAgeLevel'}; #'ADULT'; ## HERE NEEDS TO CALCULATE IF MINOR/ADULT
        my $newAgeLevel = '';

		
        if ($rego->{'strAgeLevel'}) { 
            $newAgeLevel = Person::calculateAgeLevel($Data, $rego->{'currentAge'});
        }
        my ($nationalPeriodID, undef, undef) = getNationalReportingPeriod($Data->{db}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $rego->{'strSport'}, $rego->{'personType'}, 'RENEWAL');
        next if ($rego->{'intNationalPeriodID'} == $nationalPeriodID);
        #$renew = $Data->{'target'} . "?client=$client&amp;a=PREGF_TU&amp;pt=$rego->{'strPersonType'}&amp;per=$rego->{'strPersonEntityRole'}&amp;pl=$rego->{'strPersonLevel'}&amp;sp=$rego->{'strSport'}&amp;ag=$newAgeLevel&amp;nat=RENEWAL";
        #$renew = $Data->{'target'} . "?client=$client&amp;a=PF_&amp;pID=$rego->{'intPersonID'}&amp;dnat=RENEWAL&amp;rsp=$rego->{'strSport'}&amp;rpl=$rego->{'strPersonLevel'}&amp;rper=$rego->{'strPersonEntityRole'}&amp;rag=$newAgeLevel&amp;rpt=$rego->{'strPersonType'}";
        $renew = $Data->{'target'} . "?client=$client&amp;a=PF_&amp;pID=$rego->{'intPersonID'}&amp;dnat=RENEWAL&amp;rpID=$rego->{'intPersonRegistrationID'}&amp;_ss=r&amp;rfp=r";
        $rego->{'renew_link'} = $renew;

        $rego->{'Status'} = (($rego->{'strStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE) and $rego->{'intPaymentRequired'}) ? $Defs::personRegoStatus{$Defs::PERSONREGO_STATUS_ACTIVE_PENDING_PAYMENT} : $rego->{'Status'};
    }
	
	#$Reg_ref->[0]{'documents'} = \@reg_docs;
	#push @{$Reg_ref},\%reg_docs;
	
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
			$val = $FieldDefinitions->{'fields'}{$f}{'options'}{$val} || $val;
		}
		if($FieldDefinitions->{'fields'}{$f}{'displaylookup'})	{
			$val = $FieldDefinitions->{'fields'}{$f}{'displaylookup'}{$val} || $val;
		}
		push @{$fields_grouped{$group}}, [$f, $label];
		my $string = '';
		if (($val and $val ne '00/00/0000') or ($is_header))	{
			$string .= qq[<div class="mfloat"><span class = "details-left">$label:</span>] if !$nolabelfields{$f};
			$string .= '<span class="detail-value">'.$val.'</span></div>';
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
