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

require AccreditationDisplay;

sub showPersonHome	{
	my ($Data, $personID, $FieldDefinitions, $memperms)=@_;
	my $client = $Data->{'client'} || '';
	my $personObj = getInstanceOf($Data, 'person');
	my $allowedit = allowedAction($Data, 'p_e') ? 1 : 0;
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
				$markduplicateURL = "$Data->{'target'}?client=$client&amp;a=P_DUP_";
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
    my $addregistrationURL = "$Data->{'target'}?client=$client&amp;a=PF_&rfp=r&amp;_ss=r";
	my $accreditations = ($Data->{'SystemConfig'}{'NationalAccreditation'}) ? AccreditationDisplay::ActiveNationalAccredSummary($Data, $personID) : '';#ActiveAccredSummary($Data, $personID, $Data->{'clientValues'}{'assocID'});

  my $docs = getUploadedFiles(
    $Data,
    $Defs::LEVEL_PERSON,
    $personID,
    $Defs::UPLOADFILETYPE_DOC,
    $Data->{'client'},
  );

    my $readonly = !( ($personObj->getValue('strStatus') eq 'REGISTERED' ? 1 : 0) || ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 ) );
    $Data->{'ReadOnlyLogin'} ? $readonly = 1 : undef;

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
		Documents => $docs,
		GroupData => $groupdata,		
	    client => $client,
	    url => "$Defs::base_url/viewer.cgi",
		Details => {
			Active => $Data->{'lang'}->txt(($personObj->getValue('intRecStatus') || '') ? 'Yes' : 'No'),
			LatinFirstname=> $personObj->getValue('strLatinFirstname') || '',	
			LatinSurname=> $personObj->getValue('strLatinSurname') || '',	
			Address1 => $personObj->getValue('strAddress1') || '',	
			Address2 => $personObj->getValue('strAddress2') || '',	
			Suburb => $personObj->getValue('strSuburb') || '',	
			State => $personObj->getValue('strState') || '',	
			Country => $personObj->getValue('strCountry') || '',	
			PostalCode => $personObj->getValue('strPostalCode') || '',	
			PhoneHome => $personObj->getValue('strPhoneHome') || '',	
			PhoneWork => $personObj->getValue('strPhoneWork') || '',	
			PhoneMobile => $personObj->getValue('strPhoneMobile') || '',	
			Email => $personObj->getValue('strEmail') || '',	
			Gender => $Data->{'lang'}->txt($Defs::genderInfo{$personObj->getValue('intGender') || 0}) || '',
			DOB => $personObj->getValue('dtDOB') || '',
			NationalNum => $personObj->getValue('strNationalNum') || '',
			SquadNum => $personObj->getValue('dblCustomDbl10') || '',
			BirthCountry => $personObj->getValue('strCountryOfBirth') || '',
			PassportNat => $personObj->getValue('strPassportNationality') || '',
			Status => $personObj->getValue('strStatus') || '',
		},

	);
	
    my %RegFilters=();
    #$RegFilters{'current'} = 1;
    my @statusIN = ($Defs::PERSONREGO_STATUS_PENDING, $Defs::PERSONREGO_STATUS_ACTIVE, $Defs::PERSONREGO_STATUS_PASSIVE); #, $Defs::PERSONREGO_STATUS_TRANSFERRED, $Defs::PERSONREGO_STATUS_SUSPENDED);
    #$RegFilters{'entityID'} = getLastEntityID($Data->{'clientValues'});
    #$Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? push @statusIN, $Defs::PERSONREGO_STATUS_DELETED : undef;
    
    $RegFilters{'statusIN'} = \@statusIN;
    my ($RegCount, $Reg_ref) = PersonRegistration::getRegistrationData($Data, $personID, \%RegFilters);
	
	open FH, ">dumpfile.txt";
	
    foreach my $rego (@{$Reg_ref})  {
        my $renew = '';
        $rego->{'renew_link'} = '';
        next if ($rego->{'intEntityID'} != getLastEntityID($Data->{'clientValues'}));
        next if ($rego->{'strStatus'} !~ /$Defs::PERSONREGO_STATUS_ACTIVE|$Defs::PERSONREGO_STATUS_PASSIVE/);
        #my $ageLevel = $rego->{'strAgeLevel'}; #'ADULT'; ## HERE NEEDS TO CALCULATE IF MINOR/ADULT
        my $newAgeLevel = '';

		
        if ($rego->{'strAgeLevel'}) { 
            $newAgeLevel = Person::calculateAgeLevel($Data, $rego->{'currentAge'});
        }
        my ($nationalPeriodID, undef, undef) = getNationalReportingPeriod($Data->{db}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $rego->{'strSport'}, $rego->{'personType'}, 'RENEWAL');
        next if ($rego->{'intNationalPeriodID'} == $nationalPeriodID);
$renew = $Data->{'target'} . "?client=$client&amp;a=PREGF_TU&amp;pt=$rego->{'strPersonType'}&amp;per=$rego->{'strPersonEntityRole'}&amp;pl=$rego->{'strPersonLevel'}&amp;sp=$rego->{'strSport'}&amp;ag=$newAgeLevel&amp;nat=RENEWAL";
        $rego->{'renew_link'} = $renew;

        $rego->{'Status'} = (($rego->{'strStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE) and $rego->{'intPaymentRequired'}) ? $Defs::personRegoStatus{$Defs::PERSONREGO_STATUS_ACTIVE_PENDING_PAYMENT} : $rego->{'Status'};
    }
	
	#$Reg_ref->[0]{'documents'} = \@reg_docs;
	#push @{$Reg_ref},\%reg_docs;
    $TemplateData{'RegistrationInfo'} = $Reg_ref;
	
	print FH "Dump of template data \n" . Dumper($TemplateData{'RegistrationInfo'}) . "\n"; 



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
		strCountry => 1,
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
			$string .= qq[<div class=""><span class = "details-left">$label:</div>] if !$nolabelfields{$f};
			$string .= '<span class="detail-value">'.$val.'</span></span>';
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
        my $url = "$Data->{'target'}?client=$client&amp;a=P_DTE";
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
