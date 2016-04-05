package Person;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  handlePerson
  getAutoPersonNum
  person_details
  updatePersonNotes
  prePersonAdd
  check_valid_date
  postPersonUpdate
  loadPersonDetails
  calculateAgeLevel
);

use strict;
use lib '.', '..', 'Clearances';
use Defs;

use Reg_common;
use Utils;
use HTMLForm;
use Countries;
use Postcodes;
use CustomFields;
use FieldLabels;
use ConfigOptions qw(ProcessPermissions);
use GenCode;
use AuditLog;
use DeQuote;
use Duplicates;
use DuplicatesUtils;
#use ProdTransactions;
#use EditPersonClubs;
use CGI qw(cookie unescape);
use Payments;
use TransLog;
use Transactions;
use ConfigOptions;
use ListPersons;

use Clearances;
use GenAgeGroup;
use GridDisplay;
use InstanceOf;

use FieldCaseRule;
use HomePerson;
use InstanceOf;
use Photo;
use AccreditationDisplay;
use DefCodes;

use Log;
use Data::Dumper;

use PrimaryClub;
use DuplicatePrevention;
use RecordTypeFilter;
use PersonRegistrationDetail;

use Documents;
use WorkFlow;
use TTTemplate;
use PersonRequest;
use BulkPersons;
use PersonLanguages;
use ListAuditLog;
use DuplicateFlow;

sub handlePerson {
    my ( $action, $Data, $personID ) = @_;

    my $resultHTML = '';
    my $personName = my $title = '';
    my $lang = $Data->{'lang'};

    my $clrd_out = 0;
    if ( $Data->{'SystemConfig'}{'Clearances_FilterClearedOut'} ) {
        my $club = $Data->{'clientValues'}{'clubID'};
        my $st   = qq[
			SELECT
				intPersonID,
				MCC.intClubID,
				strName as ClubName
			FROM
				tblPerson_ClubsClearedOut as MCC
					INNER JOIN tblClub as C ON (C.intClubID = MCC.intClubID)
			WHERE
				intPersonID=$personID
				AND intAssocID = $Data->{'clientValues'}{'assocID'}
		];
        my $query = $Data->{'db'}->prepare($st);
        $query->execute;
        my $clubs = '';
        while ( my $dref = $query->fetchrow_hashref() ) {
            $clrd_out = 1 if ( $dref->{'intClubID'} == $club );
            $clubs .= qq[, ] if $clubs;
            $clubs .= $dref->{'ClubName'};
        }
        $Data->{'PersonClrdOut'} = $clubs ? qq[<b>Cleared Out of: $clubs</b>] : '';
        $Data->{'PersonClrdOut_ofClub'}        = $clrd_out if ( $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_CLUB );
        $Data->{'PersonClrdOut_ofCurrentClub'} = $clrd_out if ( $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_ASSOC );
    }

    if ( $action =~ /P_PH_/ ) {
        my $newaction = '';
        ( $resultHTML, $title, $newaction ) = handle_photo( $action, $Data, $personID );
        $action = $newaction if $newaction;
    }

# TEST
    if ( $action =~ /^P_DT/ ) {
        #Person Details
        ( $resultHTML, $title ) = person_details( $action, $Data, $personID );
    }
    elsif ( $action =~ /^P_A/ ) {
	    #Person Details
        ( $resultHTML, $title ) = person_details( $action, $Data, $personID );
	}
    elsif ( $action =~ /^P_LSROup/ ) {
        ( $resultHTML, $title ) = bulkPersonRolloverUpdate( $Data, $action );
    }
    elsif ( $action =~ /^P_LSRO/ ) {
        ( $resultHTML, $title ) = bulkPersonRollover( $Data, $action );
    }
    elsif ( $action =~ /^P_L/ ) {
        ( $resultHTML, $title ) = listPersons( $Data, getID($Data->{'clientValues'}), $action );
    }
    elsif ( $action =~ /^P_PRS_L/ ) {
        ( $resultHTML, $title ) = listPersons( $Data, getID($Data->{'clientValues'}), $action );
    }
    elsif ( $action =~ /P_CLB_/ ) {
        ( $resultHTML, $title ) = handlePersonClub( $action, $Data, $personID );
    }
    #elsif ( $action =~ /P_PRODTXN_/ ) {
    #    ( $resultHTML, $title ) = handleProdTransactions( $action, $Data, $personID );
    #}
    elsif ( $action =~ /P_TXN_/ ) {
        ( $resultHTML, $title ) = Transactions::handleTransactions( $action, $Data, $personID );
    }
    elsif ( $action =~ /P_TXNLog/ ) {
        my $entityID = getLastEntityID($Data->{'clientValues'});
        ( $resultHTML, $title ) = TransLog::handleTransLogs( $action, $Data, $entityID, $personID );
    }
    elsif ( $action =~ /P_PAY_/ ) {
        ( $resultHTML, $title ) = handlePayments( $action, $Data, 0 );
    }
    elsif ( $action =~ /^P_DUP_/ ) {
        ( $resultHTML, $title ) = PersonDupl( $action, $Data, $personID );
    }
    elsif ( $action =~ /^P_DEL/ ) {

        #($resultHTML,$title)=delete_person($Data, $personID);
    }
    elsif ( $action =~ /^P_TRANSFER/ ) {
        ( $resultHTML, $title ) = PersonTransfer($Data);
    }
    elsif ( $action =~ /P_CLR/ ) {
        ($resultHTML, $title) = listRequests( $Data, $personID );
    }
    elsif ( $action =~ /^P_HOME/ ) {
        my ( $FieldDefinitions, $memperms ) = person_details( '', $Data, $personID, {}, 1 );
        ( $resultHTML, $title ) = showPersonHome( $Data, $personID, $FieldDefinitions, $memperms );
    }
    elsif ( $action =~ /^P_NACCRED/ ) {
        ( $resultHTML, $title ) = handleAccreditationDisplay( $action, $Data, $personID );
    }
    elsif ( $action =~ /P_REGOS/ ) {
        ($resultHTML , $title)= personRegistrationsHistory( $Data, $personID ) ;
        $title = $lang->txt('Registration History');
    }
    elsif ( $action =~ /P_DUPH/ ) {
        ($resultHTML , $title)= personDupMergingHistory( $Data, $personID ) ;
        $title = $lang->txt('Duplicate Merging History');
    }
    elsif ( $action eq 'P_REGO' ) {
        my $entityID = getLastEntityID($Data->{'clientValues'});
        my $prID = safe_param( 'prID', 'number' );
        $resultHTML = personRegistrationDetail($action, $Data, $entityID, $prID) || '';
        $title = $lang->txt('Registration History');
    }
    elsif ( $action =~ /P_DOCS/ ) {
        ($resultHTML,$title) =  listDocuments($Data, $personID);
         my $client = setClient( $Data->{'clientValues'} ) || '';
         $resultHTML .= Documents::list_docs($Data, $personID, $client );
           }
    elsif($action =~ /P_PASS/){
    	($resultHTML,$title) = listPlayerPassport($Data, $personID);
    } 
    elsif($action =~ /P_HISTLOG/){
    	($resultHTML,$title) = listPersonAuditLog($Data, $personID);
    } 
    elsif($action =~ /P_CERT/){
    	($resultHTML, $title) = PersonCertifications::handleCertificates($action,$Data,$personID);  
    }
    elsif($action =~ /P_SEARCH/){
        #place holder atm
    	($resultHTML, $title) = (undef, undef);
    }
    else {
        print STDERR "Unknown action $action\n";
    }
    return ( $resultHTML, $title );
}

sub listPlayerPassport {
	my ($Data, $personID) = @_;

	my $query = qq[ SELECT strPersonLevel, strEntityName, strMAName, dtFrom, IF(dtTo > NOW(), '', dtTo) as dtTo FROM tblPlayerPassport WHERE intPersonID = ? ORDER BY intPlayerPassportID, dtFrom,dtTo 
	];
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($personID);
	my @rowdata = ();
	while(my $passportref = $sth->fetchrow_hashref()){
		push @rowdata,{
			From => $passportref->{'dtFrom'},
			To => $passportref->{'dtTo'},
			Club => $passportref->{'strEntityName'},
			Level => $Defs::personLevel{$passportref->{'strPersonLevel'}} || '',
			MAName => $passportref->{'strMAName'},
		};
	}
	$sth->finish();
	my $PageContent = {
		Lang => $Data->{'lang'},
		Passport => \@rowdata,
	};
	 my $title = '';
	 my $resultHTML = runTemplate($Data, $PageContent, 'registration/playerpassport.templ') || '';
	 $title = $Data->{'lang'}->txt('Player Passport');
	 return ($resultHTML, $title);
}

sub personDupMergingHistory {


    my ($Data, $personID) = @_;

    my $FieldLabels   = FieldLabels::getFieldLabels( $Data, $Defs::LEVEL_PERSON );
    my $natnumname = $Data->{'SystemConfig'}{'NationalNumName'} || 'National Number';
    my $lang = $Data->{'lang'};

    my $st = qq[
        SELECT
            PD.intChildPersonID,
            P.strNationalNum,
            P.strLocalFirstname,
            P.strLocalSurname,
            P.strLatinFirstname,
            P.strLatinSurname,
            P.dtDOB,
            PD.dtUpdated
        FROM
            tblPersonDuplicates as PD
            INNER JOIN tblPerson as P ON (
                P.intPersonID = PD.intChildPersonID
            )
        WHERE PD.intParentPersonID = ?
    ];
            
	my $qry = $Data->{'db'}->prepare($st); 
    $qry->execute($personID);
    
    my %RegFilters=();
    my @rowdata = ();
    my $results = 0;
    my $client           = setClient( $Data->{'clientValues'} ) || '';
   
    my %tempClientValues = getClient($client);
    $tempClientValues{currentLevel} = $Defs::LEVEL_PERSON;
    while (my $rego = $qry->fetchrow_hashref()) {
      $results=1;
      $tempClientValues{personID} = $rego->{intChildPersonID};
        my $tempClient = setClient(\%tempClientValues);
      push @rowdata, {
        id => $rego->{'intChildPersonID'} || 0,
        NationalNum=> $rego->{'strNationalNum'} || '',
        LocalFirstname=> $rego->{'strLocalFirstname'} || '',
        LocalSurname=> $rego->{'strLocalSurname'} || '',
        LatinFirstname=> $rego->{'strLatinFirstname'} || '',
        LatinSurname=> $rego->{'strLatinSurname'} || '',
        dtUpdated=> $Data->{'l10n'}{'date'}->TZformat($rego->{'dtUpdated'},'MEDIUM','SHORT') || '',
        dtUpdated_RAW=> $rego->{'dtUpdated'} || '',
        dob=> $Data->{'l10n'}{'date'}->TZformat($rego->{'dtDOB'},'MEDIUM',''),
        dob_RAW => $rego->{'dtDOB'},
        SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=P_HOME",
      };
    }

    my $addlink='';
    my $title=$lang->txt('Duplicate Merging History');
    my @headers = (
        {
            name  => $Data->{'lang'}->txt($natnumname),
            field => 'NationalNum',
        },
        {
            name  => $FieldLabels->{'strLocalFirstname'},
            field => 'LocalFirstname',
        },
        {
            name  => $FieldLabels->{'strLocalSurname'},
            field  => 'LocalSurname',
            width  => 30,
        },
        {
            name  => $FieldLabels->{'strLatinFirstname'},
            field => 'LatinFirstname',
        },
        {
            name  => $FieldLabels->{'strLatinSurname'},
            field  => 'LatinSurname',
            width  => 30,
        },

        {
            name  => $FieldLabels->{'dtDOB'},
            field  => 'dob',
            width  => 30,
        },
        {
            name  => $Data->{'lang'}->txt('Date Merged'),
            field => 'dtUpdated',
            sortdata => 'dtUpdated_RAW',
            defaultShow => 1,
        },
        {
            type  => 'Selector',
            field => 'SelectLink',
        },
    );

    my $grid  = showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '100%',
    );

    my $resultHTML = qq[
        <div class="clearfix">
            $grid
        </div>
    ];

    return ($resultHTML,$title);
}
sub personRegistrationsHistory   {


    my ($Data, $personID) = @_;

    my $lang = $Data->{'lang'};

    my %RegFilters=();
    my @statusNOTIN = ($Defs::PERSONREGO_STATUS_DELETED, $Defs::PERSONREGO_STATUS_INPROGRESS);
    $RegFilters{'statusNOTIN'} = \@statusNOTIN;
    my ($RegCount, $Reg_ref) = PersonRegistration::getRegistrationData($Data, $personID, \%RegFilters);
    my @rowdata = ();
    my $results = 0;
    my $client           = setClient( $Data->{'clientValues'} ) || '';
    my $validToDate;
    my $validFromDate;
   
    foreach my $rego (@{$Reg_ref})  {
      $results=1;
        my $name = $rego->{'strLocalName'};
        $name .= " ($rego->{'strLatinName'})" if $rego->{'strLatinName'};
        $validFromDate = ($rego->{'dtFrom'} and $rego->{'dtFrom'} ne '0000-00-00') ? $Data->{'l10n'}{'date'}->TZformat($rego->{'dtFrom'},'MEDIUM','NONE') : $Data->{'l10n'}{'date'}->TZformat($rego->{'npdtFrom'},'MEDIUM','NONE');
        
        $validToDate = ($rego->{'dtTo'} and $rego->{'dtTo'} ne '0000-00-00') ? $Data->{'l10n'}{'date'}->TZformat($rego->{'dtTo'},'MEDIUM','NONE') : $Data->{'l10n'}{'date'}->TZformat($rego->{'npdtTo'},'MEDIUM','NONE');
        
      push @rowdata, {
        id => $rego->{'intPersonRegistrationID'} || 0,
        EntityLocalName=> $name,
        EntityLatinName=> $rego->{'strLatinName'} || '',
        dtApproved=> $Data->{'l10n'}{'date'}->TZformat($rego->{'dtApproved'},'MEDIUM','SHORT') || '',
        dtApproved_RAW=> $rego->{'dtApproved'} || '',
        PersonType=> $lang->txt($rego->{'PersonType'} || ''),
        PersonLevel=> $lang->txt($rego->{'PersonLevel'} || ''),
        AgeLevel=> $lang->txt($rego->{'AgeLevel'} || ''),
        RegistrationNature=> $lang->txt($rego->{'RegistrationNature'} || ''),
        Status=> $lang->txt($rego->{'Status'} || ''),
        PersonEntityRole=> $lang->txt($rego->{'strPersonEntityRole'} || ''),
        Sport=> $lang->txt($rego->{'Sport'} || ''),
        Date => $Data->{'l10n'}{'date'}->TZformat($rego->{'dtApproved'},'MEDIUM','SHORT') || $Data->{'l10n'}{'date'}->TZformat($rego->{'dtLastUpdated'},'MEDIUM','SHORT') || $Data->{'l10n'}{'date'}->TZformat($rego->{'dtAdded'},'MEDIUM','SHORT') || '',
        Date_RAW => $rego->{'dtApproved'} || $rego->{'dtLastUpdated'} || $rego->{'dtAdded'} || '',
        SelectLink => "$Data->{'target'}?client=$client&amp;a=P_REGO&amp;prID=$rego->{'intPersonRegistrationID'}",
        ValidFrom => $validFromDate || '',
        ValidTo => $validToDate || '',
      };
    }

    my $addlink='';
    my $title=$lang->txt('Registration History');
    my %tempClientValues = getClient($client);
    {
        my $tempClient = setClient(\%tempClientValues);
        $addlink=qq[<span class = "btn-inside-panels"><a class="btn-inside-panels" href="$Data->{'target'}?client=$client&amp;a=VENUE_DTA">].$Data->{'lang'}->txt('Add').qq[</a></span>] if (!$Data->{'ReadOnlyLogin'});

    }

    my $modoptions=qq[<div class="changeoptions">$addlink</div>];
    $title=$modoptions.$title;
    my $rectype_options=show_recordtypes(
        $Data,
        '',
        '',
        \%Defs::personRegoStatus,
        { 'ALL' => $Data->{'lang'}->txt('All'), },
    ) || '';
    $rectype_options='';

    my @headers = (
        {
            name  => $Data->{'lang'}->txt('Registration'),
            field => 'RegistrationNature',
        },
        {
            name  => $Data->{'lang'}->txt('Registered To'),
            field => 'EntityLocalName',
            defaultShow => 1,
        },
        {
            name   => $Data->{'lang'}->txt('Type'),
            field  => 'PersonType',
            width  => 30,
            defaultShow => 1,
        },
        {
            name   => $Data->{'lang'}->txt('Sport'),
            field  => 'Sport',
            width  => 30,
        },
        {
            name  => $Data->{'lang'}->txt('Level'),
            field => 'PersonLevel',
        },
        {
            name  => $Data->{'lang'}->txt('Age Level'),
            field => 'AgeLevel',
        },
        {
            name  => $Data->{'lang'}->txt('Status'),
            field => 'Status',
        },
        {
            name => $Data->{'lang'}->txt('Valid From'),
            field => 'ValidFrom',
        },
        {
            name => $Data->{'lang'}->txt('Valid To'),
            field => 'ValidTo',
        },
        {
            name  => $Data->{'lang'}->txt('Date'),
            field => 'Date',
            sortdata => 'Date_RAW',
            defaultShow => 1,
        },
        {
            type  => 'Selector',
            field => 'SelectLink',
        },
    );

    my $filterfields = [
        {
            field     => 'strLocalName',
            elementID => 'id_textfilterfield',
            type      => 'regex',
        },
        {
            field     => 'strStatus',
            elementID => 'dd_actstatus',
            allvalue  => 'ALL',
        },
    ];

    my $grid  = showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '100%',
        filters => $filterfields,
    );

    my $resultHTML = qq[
        <div class="clearfix">
            $grid
        </div>
    ];

    return ($resultHTML,$title);
}
sub listDocuments {
    my ($Data, $personID) = @_;
    my $resultHTML = '';
    my $lang = $Data->{'lang'};
    my $db = $Data->{'db'};
	
    my $client = $Data->{'client'};
    my %clientValues = getClient($client);
    my $currLoginID = $Data->{'clientValues'}{'_intID'};
	my $myCurrentLevelValue = $clientValues{'authLevel'};
    my %RegFilters=();
    my @statusNOTIN = ($Defs::PERSONREGO_STATUS_DELETED, $Defs::PERSONREGO_STATUS_INPROGRESS);
    $RegFilters{'statusNOTIN'} = \@statusNOTIN;
    my ($RegCount, $Reg_ref) = PersonRegistration::getRegistrationData($Data, $personID, \%RegFilters);
    my $obj = getInstanceOf($Data, 'entity', $currLoginID);
	
	
    my $pRIDRef = ${$Reg_ref}[0];
	my $cnt = 0;
	my $regoIDtemp = 0;
	my $viewLink;
    my $replaceLink;

	
	my $fileLink = "#";
	my $grid = '';
my @headers = (
       		 {
           	 name => $lang->txt('Type'),
          	  field => 'strDocumentName',
                defaultShow => 1,
       		 },
       		 {
      	      name => $lang->txt('Status'),
      	      field => 'ApprovalStatus',
     		   },
      		 {
      	      name => $lang->txt('Date Uploaded'),
     	       field => 'DateUploaded',
     	       sortdata => 'DateUploaded_RAW',
      		 },
      		 {
       		     name => $lang->txt('View'),
       		     field => 'ViewDoc',
       		     type => 'HTML',
             sortable => 0,
                defaultShow => 1,
      		  },
      		  {
       		 	name => $lang->txt('Replace'),
        			field => 'ReplaceFile',
        			type => 'HTML',
             sortable => 0,
      		  },
   			 );
			 my $filterfields = [
       			 {
          		  field     => 'ApprovalStatus',
          		  elementID => 'dd_actstatus',
          		  allvalue  => 'ALL',
      			  },
   			 ];
			
	foreach my $registration (@{$Reg_ref}){
		$cnt++;
		my @rowdata = ();
		#get the documents here		
		$grid .= qq[<br /><h2 class="section-header">].$lang->txt($registration->{'PersonType'}).' - '. $lang->txt($registration->{'Sport'}) .' - ' . $lang->txt($registration->{'PersonLevel'})  . ' ' . $lang->txt('for') . qq[ $registration->{'strNationalPeriodName'} ] . $lang->txt('in') . qq[ $registration->{'strLocalName'}</h2>];
			
			#loop over rego documents
			foreach my $regodoc (@{$registration->{'documents'}}){
				next if(!$regodoc->{'intUploadFileID'});
                $regodoc->{'ApprovalStatus'} = $Defs::DocumentStatus{$regodoc->{'strApprovalStatus'}} || '';
				#perform query for intUseThisEntity and intUseAnyEntity
## BAFF: Below needs WHERE tblRegistrationItem.strPersonType IN ('', XX) AND tblRegistrationItem.strRegistrationNature=XX AND tblRegistrationItem.strAgeLevel = XX AND tblRegistrationItem.strPersonLevel=XX AND tblRegistrationItem.intOriginLevel = XX
				my $query = qq[
                    SELECT 
                        intUseExistingThisEntity,
                        intUseExistingAnyEntity 
                    FROM 
                        tblRegistrationItem 
                        INNER JOIN tblDocumentType ON (tblRegistrationItem.intID = tblDocumentType.intDocumentTypeID)
                        INNER JOIN tblDocuments ON (tblDocuments.intDocumentTypeID = tblDocumentType.intDocumentTypeID)
                    WHERE 
						tblDocuments.strApprovalStatus IN ('PENDING', 'APPROVED') 
                        AND intPersonRegistrationID = ? 
                        AND tblDocumentType.intDocumentTypeID = ? 
                        AND tblDocuments.intPersonID = ? 
                        AND tblRegistrationItem.intRealmID=? 
                        AND tblRegistrationItem.strItemType='DOCUMENT'
                        AND tblRegistrationItem.strPersonType IN ('', ?)
                        AND tblRegistrationItem.strRegistrationNature IN ('', ?)
                        AND tblRegistrationItem.strAgeLevel IN ('', ?)
                        AND tblRegistrationItem.strPersonLevel IN ('', ?)
                ];

			   my $sth = $db->prepare($query); 
               $sth->execute(
                    $regodoc->{'intPersonRegistrationID'}, 
                    $regodoc->{'intDocumentTypeID'},
                    $personID, 
                    $Data->{'Realm'},
                    $registration->{'strPersonType'} || '',
                    $registration->{'strRegistrationNature'} || '',
                    $registration->{'strAgeLevel'} || '',
                    $registration->{'strPersonLevel'} || '',
               );
            
			   my $dref = $sth->fetchrow_hashref(); 
          my $parentCheck= authstring($regodoc->{'intUploadFileID'});
				#checks for strLockAtLevel and intUseExistingThisEntity and intUseExistingAnyEntity and Owner against Currently Logged
                #if(! $regodoc->{'strLockAtLevel'} || ($regodoc->{'strLockAtLevel'} =~ /\|$Data->{'clientValues'}{'authLevel'}\|/ and getLastEntityID($Data->{'clientValues'}) != $regodoc->{'DocoEntityID'}) || $dref->{'intUseExistingThisEntity'} || $dref->{'intUseExistingAnyEntity'} || $registration->{'intEntityID'} == $currLoginID){	

			   if($dref->{'intUseExistingThisEntity'} || $dref->{'intUseExistingAnyEntity'} || $registration->{'intEntityID'} == $currLoginID){	
			        $viewLink = qq[ <a class="btn-main btn-view-replace" href="#" onclick="docViewer($regodoc->{'intUploadFileID'},'client=$client&chk=$parentCheck');return false;">]. $lang->txt('View') . q[</a>];
    				$replaceLink =   qq[ <a class="btn-main btn-view-replace" href="$Data->{'target'}?client=$client&amp;a=DOC_L&amp;f=$regodoc->{'intUploadFileID'}&amp;regoID=$regodoc->{'intPersonRegistrationID'}&amp;dID=$regodoc->{'intDocumentTypeID'}">]. $lang->txt('Replace File'). q[</a>];	

				}
			#	else{
					#my @authorizedLevelsArr = split(/\|/,$regodoc->{'strLockAtLevel'});
					##check level of the owner
					#my $ownerlevel = $obj->getValue('intEntityLevel');					
					#$viewLink = qq[ <button class\"HTdisabled\">]. $lang->txt('View') . q[</button>];    
                	#$replaceLink =   qq[ <button class\"HTdisabled\">]. $lang->txt('Replace File'). q[</button>];
#
#					if(grep(/^$myCurrentLevelValue/,@authorizedLevelsArr) && $myCurrentLevelValue >  $ownerlevel ){
#
#    					$viewLink = qq[ <a class="btn-main btn-view-replace" href="#" onclick="docViewer($regodoc->{'intUploadFileID'},'client=$client');return false;">]. $lang->txt('View') . q[</a></span>];
#
#        				$replaceLink =   qq[ <a class="btn-main btn-view-replace" href="$Data->{'target'}?client=$client&amp;a=DOC_L&amp;f=$regodoc->{'intUploadFileID'}&amp;regoID=$regodoc->{'intPersonRegistrationID'}&amp;dID=$regodoc->{'intDocumentTypeID'}">]. $lang->txt('Replace File'). q[</a>];	
#
#					}									
                    
        if($regodoc->{'strLockAtLevel'})   {
            if($regodoc->{'strLockAtLevel'} =~ /\|$Data->{'clientValues'}{'authLevel'}\|/ and getLastEntityID($Data->{'clientValues'}) != $regodoc->{'DocoEntityID'}){
                    #$viewLink = qq[ <button class\"HTdisabled\">]. $Data->{'lang'}->txt('View') . q[</button>];
                    #$replaceLink =   qq[ <button class\"HTdisabled\">]. $Data->{'lang'}->txt('Replace File'). q[</button>];
                    $viewLink= qq[ <span style="position: relative"><a class="HTdisabled btn-main btn-view-replace">].$Data->{'lang'}->txt('View'). q[</a></span>];
                    $replaceLink= qq[ <span style="position: relative"><a class="HTdisabled btn-main btn-view-replace">].$Data->{'lang'}->txt('Replace'). q[</a></span>];
            }
        }
        
        if ($registration->{'intEntityID'} != getLastEntityID($Data->{'clientValues'}) && $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB)    {
            $replaceLink = '';
            $replaceLink= qq[ <span style="position: relative"><a class="HTdisabled btn-main btn-view-replace">].$Data->{'lang'}->txt('Replace'). q[</a></span>];
        }
		#		}
				push @rowdata, {
	       			id => $regodoc->{'intUploadFileID'} || 0,
	        		#oldSelectLink => $fileLink,
	        		strDocumentName => $regodoc->{'strDocumentName'},
		    		ApprovalStatus => $regodoc->{'ApprovalStatus'},
            		DateUploaded => $regodoc->{'DateUploaded'},
            		DateUploaded_RAW => $regodoc->{'DateUploaded_RAW'},
            		ViewDoc => $viewLink,
            		ReplaceFile => $replaceLink,
     			};
			}

my $addlink='';
	    {
      		$addlink=qq[<span class = "button-small generic-button"><a class="btn-inside-panels" href="$Data->{'target'}?client=		$client&amp;a=DOC_L">].$Data->{'lang'}->txt('Add').qq[</a></span>] if (!$Data->{'ReadOnlyLogin'});
 		}
   my $query = qq[
         SELECT strDocumentName, intDocumentTypeID FROM tblDocumentType WHERE strDocumentFor = ? AND intRealmID IN (0,?)
    ];
    my $sth = $db->prepare($query);
    $sth->execute($Defs::DOC_FOR_PERSON,$Data->{'Realm'});
    my $doclisttype = qq[  
                    <div> 
                              <form action="$Data->{'target'}" id="personDocAdd">
                              <input type="hidden" name="client" value="$client" />
                              <input type="hidden" name="a" value="DOC_L" />
							  <input type="hidden" name="RegistrationID" value="$registration->{'intPersonRegistrationID'}" />
                              <label>]. $lang->txt('Document Type') . qq[</label>
                              <select name="doclisttype" id="doclisttype">
                              <option value=""> </option>
                       ];
    while(my $dref = $sth->fetchrow_hashref()){
        $doclisttype .= qq[<option value="$dref->{'intDocumentTypeID'}">].$lang->txt($dref->{'strDocumentName'}).qq[</option>];
    }  
	$doclisttype .= qq[ </select>
                        <input type="submit" class="btn-inside-panels" value="].$lang->txt('Add').qq[" />
					</form></div>];

	 my $modoptions=qq[<div class="changeoptions"></div>];
			#
			$grid .= qq[
                    <div class="clearfix">].showGrid(
       		  Data => $Data,
      		  columns => \@headers,
      		  rowdata => \@rowdata,
       		  gridid => "grid$registration->{'intPersonRegistrationID'}",
       		  width => '100%',
       		  coloredTop => 'no',
			);
			$grid .= qq[<br /><br /><p>].$lang->txt('Add a new document to this registration').qq[</p>$doclisttype </div>];
		#

		
	}
        my $title = $lang->txt('Registration Documents');
        #my $title = '';

        #$modoptions
        #$resultHTML = qq[<div class="pageHeading">Registration Documents</div>].$grid;
		
		

        $resultHTML = qq[          
						<div class="col-md-12">$grid</div>
					];


    return ($resultHTML,$title);

} ## end sub listDocuments

sub updatePersonNotes {

    my ( $db, $personID, $notes_ref ) = @_;
    $personID ||= 0;

    my @noteFields  = (qw(strNotes));
    my %Notes       = ();
    my %notes_ref_l = %{$notes_ref};

    #deQuote($db, \%notes_ref_l);
    my ( $insert_cols, $insert_vals, $update_vals ) = ( "", "", "" );
    my @value_list;

    for my $f (@noteFields) {
        next if ( !exists $notes_ref_l{ 'd_' . $f } and !exists $notes_ref_l{$f} );

        $Notes{$f} = $notes_ref_l{ 'd_' . $f } || $notes_ref_l{$f} || '';
        my $fieldname = $f;
        $insert_cols .= qq[, $fieldname];

        $insert_vals .= qq[, ?];
        $update_vals .= qq[, $fieldname = ? ];
        push @value_list, $Notes{$f};
    }

    my $st = qq[
        INSERT INTO tblPersonNotes
            (intPersonID $insert_cols)
        VALUES
            ($personID $insert_vals)
        ON DUPLICATE KEY UPDATE tTimeStamp=NOW() $update_vals
    ];

    my $query = $db->prepare($st);
    $query->execute( @value_list, @value_list );
}

sub PersonTransfer {

    my ($Data) = @_;

    my $client           = setClient( $Data->{'clientValues'} ) || '';
    my $body             = '';
    my $cgi              = new CGI;
    my %params           = $cgi->Vars();
    my $db               = $Data->{'db'};
    my $transfer_natnum  = $params{'transfer_natnum'} || '';
    my $transfer_surname = $params{'transfer_surname'} || '';
    my $transfer_dob     = $params{'transfer_dob'} || '';
    my $personID         = $params{'personID'} || 0;
    $transfer_dob = '' if !check_valid_date($transfer_dob);
    $transfer_dob = _fix_date($transfer_dob) if ( check_valid_date($transfer_dob) );
    deQuote( $db, \$transfer_natnum );
    deQuote( $db, \$transfer_surname );
    deQuote( $db, \$transfer_dob );
    my $confirmed = $params{'transfer_confirm'} || 0;
    my $assocTypeIDWHERE = exists $Data->{'SystemConfig'}{'PersonTransfer_AssocType'} ? qq[ AND A.intAssocTypeID = $Data->{'SystemConfig'}{'PersonTransfer_AssocType'} ] : '';
    my $st = qq[
		SELECT
            M.intPersonID,
            A.strName,
            A.intAssocID,
            MA.strStatus,
            CONCAT(M.strLocalFirstname, ' ', M.strLocalSurname) as PersonName,
            DATE_FORMAT(dtDOB,'%d/%m/%Y') AS dtDOB,
            DATE_FORMAT(dtDOB, "%Y%m%d") as DOBAgeGroup,
            M.intGender
		FROM tblPerson as M
			INNER JOIN tblPerson_Associations as MA ON (MA.intPersonID = M.intPersonID)
			INNER JOIN tblAssoc as A ON (A.intAssocID = MA.intAssocID)
		WHERE M.intRealmID = $Data->{'Realm'}
			$assocTypeIDWHERE
			AND M.strLocalSurname = $transfer_surname
			AND (M.strNationalNum = $transfer_natnum OR M.dtDOB= $transfer_dob)
			AND M.intSystemStatus = $Defs::PERSONSTATUS_ACTIVE
	];
    $st .= qq[ AND M.intPersonID = $personID] if $personID;

    if ( !$params{'transfer_surname'} and ( !$params{'transfer_dob'} or !$params{'transfer_surname'} ) ) {
        my $assocType = '';
        my $assocTypeIDWHERE = exists $Data->{'SystemConfig'}{'PersonTransfer_AssocType'} ? qq[ AND intSubTypeID = $Data->{'SystemConfig'}{'PersonTransfer_AssocType'} ] : '';
        if ($assocTypeIDWHERE) {
            my $st = qq[
				SELECT strSubTypeName
				FROM tblRealmSubTypes
				WHERE intRealmID = $Data->{'Realm'}
		                        $assocTypeIDWHERE
			];
            my $query = $db->prepare($st);
            $query->execute;
            my $dref = $query->fetchrow_hashref() || undef;
            $assocType = qq[ <b>(from $dref->{strSubTypeName} only)</b>];
        }
        $body .= qq[
			<form action="$Data->{'target'}" method="POST" style="float:left;" onsubmit="document.getElementById('btnsubmit').disabled=true;return true;">
                                <p>If you wish to Transfer a person to this Association $assocType, please fill in the Surname and $Data->{'SystemConfig'}{'NationalNumName'} or Date of Birth below and click <b>Transfer Person</b>.</p>

                        <table>
				<tr><td><span class="label">Person's Surname:</td><td><span class="formw"><input type="text" name="transfer_surname" value=""></td></tr>
				<tr><td><b>AND</b></td></tr>
				<tr><td>&nbsp;</td></tr>
				<tr><td><span class="label">$Data->{'SystemConfig'}{'NationalNumName'}:</td><td><span class="formw"><input type="text" name="transfer_natnum" value=""></td></tr>
				<tr><td><b>OR</b></td></tr>
				<tr><td><span class="label">Person's Date of Birth:</td><td><span class="formw"><input type="text" name="transfer_dob" value="">&nbsp;<i>dd/mm/yyyy</li></td></tr>
			</table>
                                <input type="hidden" name="a" value="P_TRANSFER">
                                <input type="hidden" name="client" value="$client">
                                <input type="submit" value="Transfer Person" id="btnsubmit" name="btnsubmit"  class="btn-main">
                        </form>
		];
    }
    elsif ( !$confirmed and !$personID ) {
        my $query = $db->prepare($st);
        $query->execute;
        $body .= qq[
                                <p>Please select a person to be transferred and click the <b>select</b> link.</p>
                        <p>
                        	<table>
                               	<tr><td>&nbsp;</td>
								<td><span class="label">$Data->{'SystemConfig'}{'NationalNumName'}:</td>
                               	<td><span class="label">Person's Name:</td>
                               	<td><span class="label">Person's Date Of Birth:</td>
                               	<td><span class="label">Linked To:</td>
							</tr>
		];
        my $count = 0;
        while ( my $dref = $query->fetchrow_hashref() ) {
            $count++;
            my $href = qq[client=$client&amp;a=P_TRANSFER&amp;transfer_surname=$params{'transfer_surname'}&amp;transfer_dob=$params{'transfer_dob'}&amp;transfer_natnum=$params{'transfer_natnum'}];
            $body .= qq[<tr><td><a href="$Data->{'target'}?$href&amp;personID=$dref->{intPersonID}">select</a></td>
							<td>$dref->{strNationalNum}</td>
							<td>$dref->{PersonName}</td>
							<td>$dref->{dtDOB}</td>
							<td>$dref->{strName}</td></tr>];
        }
        $body .= qq[</table>];
        if ( !$count ) {
            $body = qq[<p class="warningmsg">No Persons found</p>];
        }

    }
    elsif ( !$confirmed and $personID ) {
        my $query = $db->prepare($st);
        $query->execute;
        $body .= qq[
                        <form action="$Data->{'target'}" method="POST" style="float:left;" onsubmit="document.getElementById('btnsubmit').disabled=true;return true;">
                                <p>Please review the person to be transferred and click the <b>Confirm Transfer</b> button below.</p>

                        <p>
                                <table>
                                <tr><td><span class="label">$Data->{'SystemConfig'}{'NationalNumName'}:</td><td><span class="formw">:$params{'transfer_natnum'}</td></tr>
                                <tr><td><span class="label">Person's Surname:</td><td><span class="formw">:$params{'transfer_surname'}</td></tr>
                                <tr><td><span class="label">Person's DOB:</td><td><span class="formw">:$params{'transfer_dob'}</td></tr>
                                <tr><td><span class="label">Linked to:</td><td>&nbsp;</td></tr>
                ];
        my $count     = 0;
        my $thisassoc = 0;
        while ( my $dref = $query->fetchrow_hashref() ) {
            $thisassoc = 1 if ( $dref->{intAssocID} == $Data->{'clientValues'}{'assocID'} );
            $count++;
            $body .= qq[<tr><td colspan="2">$dref->{strName}</td></tr>];
        }
        $body .= qq[
                                </table><br>
                                <input type="hidden" name="a" value="P_TRANSFER">
                                <input type="hidden" name="transfer_confirm" value="1">
                                <input type="hidden" name="transfer_natnum" value="$params{'transfer_natnum'}">
                                <input type="hidden" name="transfer_surname" value="$params{'transfer_surname'}">
                                <input type="hidden" name="transfer_dob" value="$params{'transfer_dob'}">
                                <input type="hidden" name="personID" value="$personID">
                                <input type="hidden" name="client" value="$client">
                                <input type="submit" value="Confirm transfer" id="btnsubmit" name="btnsubmit"  class="btn-main">
                        </form>
                ];
        $body = qq[<p class="warningmsg">Person already exists in this Association</p>] if ($thisassoc);
        if ( !$count ) {
            $body = qq[<p class="warningmsg">Person not found</p>];
        }
    }
    elsif ($confirmed) {
        $st .= qq[ LIMIT 1];
        my $query = $db->prepare($st);
        $query->execute;
        my ( $personID, undef, $oldAssocID, $recstatus, undef, undef, $DOBAgeGroup, $Gender ) = $query->fetchrow_array();
        $DOBAgeGroup ||= '';
        $Gender      ||= 0;
        $personID    ||= 0;
        my $assocID      = $Data->{clientValues}{'assocID'} || 0;
        my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
        my %types        = ();

        $types{'intMSRecStatus'} = 1;
        if ( $personID and $assocID ) {
            my $genAgeGroup ||= new GenAgeGroup( $Data->{'db'}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $assocID );
            my $ageGroupID = $genAgeGroup->getAgeGroup( $Gender, $DOBAgeGroup ) || 0;
            warn("INSERT personRego & any products");
            my $mem_st = qq[
				UPDATE tblPerson
				SET intPlayer = 1
				WHERE intPersonID = $personID
				LIMIT 1
			];
            $db->do($mem_st);
            my %tempClientValues = %{ $Data->{clientValues} };
            $tempClientValues{personID}     = $personID;
            $tempClientValues{currentLevel} = $Defs::LEVEL_PERSON;
            my $tempClient = setClient( \%tempClientValues );
            $body = qq[ <div class="OKmsg">The person has been transferred</div><br><a href="$Data->{'target'}?client=$tempClient&amp;a=P_HOME">click here to display persons record</a>];

        }
    }
    else {
        return ( "Invalid Option", "Transfer Person" );
    }
    return ( $body, "Person Transfer" );

}

sub person_details {
    my ( $action, $Data, $personID, $prefillData, $returndata ) = @_;
    $returndata ||= 0;


    my $option = 'display';

    	$option = 'edit' if $action eq 'P_DTE' and allowedAction( $Data, 'm_e' );
    	$option = 'add'  if $action eq 'P_A' and allowedAction( $Data, 'm_a' );
    	$option = 'add' if ( $Data->{'RegoForm'} and !$personID );


    $personID = 0 if $option eq 'add';
    my $hideWebCamTab = $Data->{SystemConfig}{hide_webcam_tab} ? qq[&hwct=1] : '';
    my $field = loadPersonDetails( $Data, $personID ) || ();


    if ( $prefillData and ref $prefillData ) {
        if ($personID) {
            for my $k ( keys %{$prefillData} ) { $field->{$k} ||= $prefillData->{$k} if $prefillData->{$k}; }
        }
        else {
            $field = $prefillData;
        }
    }
    my $natnumname = $Data->{'SystemConfig'}{'NationalNumName'} || 'National Number';
    my $FieldLabels   = FieldLabels::getFieldLabels( $Data, $Defs::LEVEL_PERSON );

     my $isocountries = getISOCountriesHash();

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'},
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'} || $field->{'intAssocTypeID'},
        assocID    => $Data->{'clientValues'}{'assocID'},
        hideCodes  => $Data->{'SystemConfig'}{'AssocConfig'}{'hideDefCodes'},
        locale     => $Data->{'lang'}->getLocale(),
    );

    my $CustomFieldNames = CustomFields::getCustomFieldNames( $Data, $field->{'intAssocTypeID'} ) || '';
    my $fieldsdefined = 1;
    my %genderoptions = ();
    for my $k ( keys %Defs::PersonGenderInfo ) {
        next if !$k;
        next if ( $Data->{'SystemConfig'}{'NoUnspecifiedGender'} and $k eq $Defs::GENDER_NONE );
        $genderoptions{$k} = $Defs::PersonGenderInfo{$k} || '';
    }

    my $client = setClient( $Data->{'clientValues'} ) || '';

    my $photolink = '';
    if ($field->{'intPersonID'}) {
        my $hash = authstring($field->{'intPersonID'});
        $photolink = qq[<img src = "getphoto.cgi?pa=$field->{'intPersonID'}f$hash" onerror="this.style.display='none'" height='200px'>];
    }
    my $field_case_rules = get_field_case_rules({dbh=>$Data->{'db'}, client=>$client, type=>'Person'});
	my @reverseYNOrder = ('',1,0);

    my $mrt_config = '';
       #readonly      => $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 0 : 1,


    my $languages = getPersonLanguages( $Data, 1, 0);
    my %languageOptions = ();
    my $nonLatin = 0;
    my @nonLatinLanguages =();
    for my $l ( @{$languages} ) {
        $languageOptions{$l->{'intLanguageID'}} = $l->{'language'} || next;
        if($l->{'intNonLatin'}) {
            $nonLatin = 1 ;
            push @nonLatinLanguages, $l->{'intLanguageID'};
        }
    }
    my $nonlatinscript = '';
    if($nonLatin)   {
        my $vals = join(',',@nonLatinLanguages);
        $nonlatinscript =   qq[
           <script>
                jQuery(document).ready(function()  {
                    jQuery('#l_row_strLatinFirstname').hide();
                    jQuery('#l_row_strLatinSurname').hide();
                    jQuery('#l_intLocalLanguage').change(function()   {
                        var lang = parseInt(jQuery('#l_intLocalLanguage').val());
                        nonlatinvals = [$vals];
                        if(nonlatinvals.indexOf(lang) !== -1 )  {
                            jQuery('#l_row_strLatinFirstname').show();
                            jQuery('#l_row_strLatinSurname').show();
                        }
                        else    {
                            jQuery('#l_row_strLatinFirstname').hide();
                            jQuery('#l_row_strLatinSurname').hide();
                        }
                    });
                });
            </script>

        ];
    }


    my %FieldDefinitions = (
        fields => {
            strFIFAID => {
                label       => $Data->{'SystemConfig'}{'person_strFIFAID'} ? $FieldLabels->{'strFIFAID'} : '',
                value       => $field->{strFIFAID},
                type        => 'text',
                size        => '14',
                readonly    => 1,
                sectionname => 'details',
            },
            strNationalNum => {
                label       => $FieldLabels->{'strNationalNum'},
                value       => $field->{strNationalNum},
                type        => 'text',
                size        => '14',
                readonly    => 1,
                sectionname => 'details',
            },

            strStatus => {
                label         => $Data->{'SystemConfig'}{'person_strStatus'}? $FieldLabels->{'strStatus'} : '',
                value         => $field->{strStatus},
                type          => 'lookup',
                sectionname   => 'details',
                options       => \%Defs::personStatus,
                readonly      => $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 0 : 1,
                noadd         => 1,
            },
            strTitle => {
                label       => $FieldLabels->{'strTitle'},
                value       => $field->{strTitle},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'details',
            },
            strLocalFirstname => {
                label       => $FieldLabels->{'strLocalFirstname'},
                value       => $field->{strLocalFirstname},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
                first_page  => 1,
            },
            strLocalSurname => {
                label       => $Data->{'SystemConfig'}{'strLocalSurname_Text'} ? $Data->{'SystemConfig'}{'strLocalSurname_Text'} : $FieldLabels->{'strLocalSurname'},
                value       => $field->{strLocalSurname},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
                first_page  => 1,
            },
            intLocalLanguage=> {
                label       => $FieldLabels->{'intLocalLanguage'},
                value       => $field->{intLocalLanguage},
                type        => 'lookup',
                options     => \%languageOptions,
                sectionname => 'other',
                firstoption => [ '', 'Select Language' ],
            },
            strLatinFirstname => {
                label       => $Data->{'SystemConfig'}{'person_strLatinNames'} ? $FieldLabels->{'strLatinFirstname'} : '' ,
                value       => $field->{strLatinFirstname},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
                first_page  => 1,
            },
            strLatinSurname => {
                label       => $Data->{'SystemConfig'}{'person_strLatinNames'} ?  $FieldLabels->{'strLatinSurname'} : '',
                value       => $field->{strLatinSurname},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
                first_page  => 1,
            },
            strMaidenName => {
                label       => $FieldLabels->{'strMaidenName'},
                value       => $field->{strMaidenName},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
            },
            strPreferredName => {
                label       => $FieldLabels->{'strPreferredName'},
                value       => $field->{strPreferredName},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
            },

            dtSuspendedUntil=> {
                label       => $FieldLabels->{'dtSuspendedUntil'},
                value       => $field->{dtSuspendedUntil},
                type        => 'date',
                datetype    => 'dropdown',
                format      => 'dd/mm/yyyy',
                sectionname => 'other',
                validate    => 'DATE',
            },
            dtDOB => {
                label       => $FieldLabels->{'dtDOB'},
                value       => $field->{dtDOB},
                type        => 'date',
                datetype    => 'dropdown',
                format      => 'dd/mm/yyyy',
                sectionname => 'details',
                validate    => 'DATE',
                compulsory => 1,
                first_page  => 1,
            },
            strRegionOfBirth => {
                label       => $FieldLabels->{'strRegionOfBirth'},
                value       => $field->{strRegionOfBirth},
                type        => 'text',
                size        => '30',
                maxsize     => '45',
                sectionname => 'other',
            },
            strPlaceOfBirth => {
                label       => $FieldLabels->{'strPlaceOfBirth'},
                value       => $field->{strPlaceOfBirth},
                type        => 'text',
                size        => '30',
                maxsize     => '45',
                sectionname => 'other',
            },
             strISOCountryOfBirth => {
                label       => $FieldLabels->{'strISOCountryOfBirth'},
                value       => $field->{strISOCountryOfBirth},
                type        => 'lookup',
                options     => $isocountries,
                sectionname => 'other',
                firstoption => [ '', 'Select Country' ],
            },

            intGender => {
                label       => $FieldLabels->{'intGender'},
                value       => $field->{intGender},
                type        => 'lookup',
                options     => \%genderoptions,
                compulsory => 1,
                sectionname => 'details',
                firstoption => [ '', " " ],
                first_page  => 1,
            },
            strAddress1 => {
                label       => $FieldLabels->{'strAddress1'},
                value       => $field->{strAddress1},
                type        => 'text',
                size        => '50',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strAddress2 => {
                label       => $FieldLabels->{'strAddress2'},
                value       => $field->{strAddress2},
                type        => 'text',
                size        => '50',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strSuburb => {
                label       => $FieldLabels->{'strSuburb'},
                value       => $field->{strSuburb},
                type        => 'text',
                size        => '30',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strState => {
                label       => $FieldLabels->{'strState'},
                value       => $field->{strState},
                type        => 'text',
                size        => '50',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strPostalCode => {
                label       => $FieldLabels->{'strPostalCode'},
                value       => $field->{strPostalCode},
                type        => 'text',
                size        => '15',
                maxsize     => '15',
                sectionname => 'contact',
            },
            strPhoneHome => {
                label       => $FieldLabels->{'strPhoneHome'},
                value       => $field->{strPhoneHome},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'contact',
            },

            strPhoneMobile => {
                label       => $FieldLabels->{'strPhoneMobile'},
                value       => $field->{strPhoneMobile},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'contact',
            },
            strEmail => {
                label       => $FieldLabels->{'strEmail'},
                value       => $field->{strEmail},
                type        => 'text',
                size        => '50',
                maxsize     => '200',
                sectionname => 'contact',
                validate    => 'EMAIL',
            },
            intEthnicityID => {
                label       => $FieldLabels->{'intEthnicityID'},
                value       => $field->{intEthnicityID},
                type        => 'lookup',
                options     => $DefCodes->{-8},
                order       => $DefCodesOrder->{-8},
                sectionname => 'details',
                firstoption => [ '', " " ],
            },
            strPreferredLang => {
                label       => $FieldLabels->{'strPreferredLang'},
                value       => $field->{strPreferredLang},
                type        => 'text',
                size        => '20',
                maxsize     => '50',
                sectionname => 'other',
            },
            strEmergContName => {
                label       => $FieldLabels->{'strEmergContName'},
                value       => $field->{strEmergContName},
                type        => 'text',
                size        => '30',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strEmergContNo => {
                label       => $FieldLabels->{'strEmergContNo'},
                value       => $field->{strEmergContNo},
                type        => 'text',
                size        => '30',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strEmergContRel => {
                label       => $FieldLabels->{'strEmergContRel'},
                value       => $field->{strEmergContRel},
                type        => 'text',
                size        => '30',
                maxsize     => '100',
                sectionname => 'contact',
            },


            strP1FName => {
                label       => $FieldLabels->{'strP1FName'},
                value       => $field->{strP1FName},
                type        => 'text',
                size        => '30',
                maxsize     => '50',
                sectionname => 'parent',
            },
            strP1SName => {
                label       => $FieldLabels->{'strP1SName'},
                value       => $field->{strP1SName},
                type        => 'text',
                size        => '30',
                maxsize     => '50',
                sectionname => 'parent',
            },

            strP1Phone => {
                label       => $FieldLabels->{'strP1Phone'},
                value       => $field->{strP1Phone},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'parent',
             },
            strP1Email => {
                label       => $FieldLabels->{'strP1Email'},
                value       => $field->{strP1Email},
                type        => 'text',
                size        => '50',
                maxsize     => '200',
                sectionname => 'parent',
                validate    => 'EMAIL',
           },
           strISOCountry => {
                label       => $FieldLabels->{'strISOCountry'},
                value       => $field->{strISOCountry},
                type        => 'lookup',
                options     => $isocountries,
                sectionname => 'contact',
                firstoption => [ '', 'Select Country' ],
            },
            strISONationality => {
                label       => $FieldLabels->{'strISONationality'},
                value       => $field->{strISONationality}  || $Data->{'SystemConfig'}{'personNationalityDefault'},
                type        => 'lookup',
                options     => $isocountries,
                sectionname => 'details',
                firstoption => [ '', 'Select Country' ],
                compulsory => 1,

            },
            dtLastUpdate => {
                label       => 'Last Updated',
                value       => $field->{tTimeStamp},
                type        => 'date',
                format      => 'dd/mm/yyyy',
                sectionname => 'other',
                readonly    => 1,
            },
            strBirthCert => {
        		label       => $FieldLabels->{'strBirthCert'},
                value       => $field->{'strBirthCert'},
                type        => 'text',
                size        => '40',
                maxsize     => '50',  
                sectionname => 'identification'              
        	},
        	strBirthCertCountry => {
        		label       => $FieldLabels->{'strBirthCertCountry'},
                value       => $field->{'strBirthCertCountry'},
                type        => 'lookup',
                options     => $isocountries,
                firstoption => [ '', 'Select Country' ],
                sectionname => 'identification', 
        	},
        	dtBirthCertValidityDateFrom => {
        		label       => $FieldLabels->{'dtValidFrom'},
                value       => $field->{'dtBirthCertValidityDateFrom'},
                type        => 'date',
                datetype    => 'dropdown',
                format      => 'dd/mm/yyyy',
                validate    => 'DATE',
                sectionname => 'identification', 
        	},
        	dtBirthCertValidityDateTo => {
        		label       => $FieldLabels->{'dtValidUntil'},
                value       => $field->{'dtBirthCertValidityDateTo'},
                type        => 'date',
                datetype    => 'dropdown',
                format      => 'dd/mm/yyyy',
                validate    => 'DATE',
                sectionname => 'identification', 
        	},
        	strBirthCertDesc => {
        		label => $FieldLabels->{'strDescription'},
      	        value => $field->{'strBirthCertDesc'},
                type => 'textarea',
                rows => '10',
                cols => '40',
                sectionname => 'identification',
        	},
        	strPassportNo => { 
               	label => $FieldLabels->{'strPassportNo'},
               	value => $field->{'strPassportNo'},
               	type => 'text',
               	size => '40',
               	maxsize => '50',
            	sectionname => 'identification',
        	},
        	 strPassportNationality => {
              	label => $FieldLabels->{'strPassportNationality'},
               	value => $field->{'strPassportNationality'},
               	type        => 'lookup',
                options     => $isocountries,
                firstoption => [ '', 'Select Country' ],
                sectionname => 'identification',
            },
        	 
            strNotes => {
                label             => $FieldLabels->{'strNotes'},
                value             => $field->{strPersonNotes},
                type              => 'textarea',
                sectionname       => 'other',
                rows              => 5,
                cols              => 45,
                SkipAddProcessing => 1,
                SkipProcessing    => 1,
            },
            strPassportIssueCountry => {
                	label => $FieldLabels->{'strPassportIssueCountry'},
                	value => $field->{'strPassportIssueCountry'},
                	type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],  
                    sectionname => 'identification',              	
                },
                dtPassportExpiry => {
                	label => $FieldLabels->{'dtPassportExpiry'},
                	value => $field->{'dtPassportExpiry'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    minyear => '1980',
                    maxyear => (localtime)[5] + 1900 + 15,
                    sectionname => 'identification',
                },
                strOtherPersonIdentifier => {
                	label => $FieldLabels->{'strOtherPersonIdentifier'},
                	value => $field->{'strOtherPersonIdentifier'},
                	type => 'text',
                	size => '40',
                	maxsize => '50',       
                	sectionname => 'identification',         	
                },
                strOtherPersonIdentifierIssueCountry => {
                	label => $FieldLabels->{'strOtherPersonIdentifierIssueCountry'},
                	value => $field->{'strOtherPersonIdentifierIssueCountry'},
                	type        => 'lookup',
                    options     => $isocountries,
                    firstoption => [ '', 'Select Country' ],
                    sectionname => 'identification',
                },
                dtOtherPersonIdentifierValidDateFrom => {
                	label => $FieldLabels->{'dtValidFrom'},
                	value => $field->{'dtOtherPersonIdentifierValidDateFrom'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'identification',
                },
                dtOtherPersonIdentifierValidDateTo => {
                	label => $FieldLabels->{'dtValidUntil'},
                	value => $field->{'dtOtherPersonIdentifierValidDateTo'},
                	type        => 'date',
                    datetype    => 'dropdown',
                    format      => 'dd/mm/yyyy',
                    validate    => 'DATE',
                    sectionname => 'identification',
                },
                strOtherPersonIdentifierDesc => {
                	label => $FieldLabels->{'strDescription'},
                	value => $field->{'strOtherPersonIdentifierDesc'},
                    type => 'textarea',
                    rows => '10',
                    cols => '40',   
                    sectionname => 'identification',             	
                },
                intOtherPersonIdentifierTypeID=> {
                	label => $FieldLabels->{'intOtherPersonIdentifierTypeID'},
                	value => $field->{'intOtherPersonIdentifierTypeID'},
                    type        => 'lookup',
                    options     => $DefCodes->{-20},
                    order       => $DefCodesOrder->{-20},
                    firstoption => [ '', " " ],
                    sectionname => 'identification',             	
                },
	
            PhotoUpload => {
                label => ($Data->{'SystemConfig'}{'person_intPhoto'} && $Data->{'SystemConfig'}{'person_demographic'})? 'Photo' : '',
                type  => 'htmlblock',
                value => q[
                <div id="photoupload_result">] . $photolink . q[</div>
                <div id="photoupload_form"></div>
                <input type="button" value = " Upload Photo " id = "photoupload" class="button generic-button">
                <input type="hidden" name = "d_PhotoUpload" value = "] . ( $photolink ? 'valid' : '' ) . q[">
                <script>
                jQuery('#photoupload').click(function() {
                        jQuery('#photoupload_form').html('<iframe src="regoformphoto.cgi?client=] . $client . $hideWebCamTab . q[" style="width:750px;height:650px;border:0px;"></iframe>');
                        jQuery('#photoupload_form').dialog({
                                width: 800,
                                height: 700,
                                modal: true,
                                title: 'Upload Photo'
                            });
                    });
                </script>
                ],
                SkipAddProcessing => 1,
                SkipProcessing    => 1,
            },
            SPident   => { type => '_SPACE_', sectionname => 'citizenship' },
            SPcontact => { type => '_SPACE_', sectionname => 'contact' },
            SPdetails => { type => '_SPACE_', sectionname => 'details' },

        },
        order => [
        qw(strNationalNum strPersonNo strStatus strLocalFirstname  strLocalSurname strMaidenName intLocalLanguage strISONationality strISOCountry dtDOB intGender strLatinFirstname strLatinSurname strPreferredName strRegionOfBirth strPlaceOfBirth strISOCountryOfBirth strAddress1 strAddress2 strSuburb strState strPostalCode strCountry strPhoneHome strPhoneMobile strEmail SPcontact intDeceased strPreferredLang strEmergContName strEmergContNo strEmergContNo2 
            strBirthCert 
            strBirthCertCountry 
            dtBirthCertValidityDateFrom
            dtBirthCertValidityDateTo
            strBirthCertDesc
            strPassportNo
            strPassportNationality
            strPassportIssueCountry
            dtPassportExpiry
            strOtherPersonIdentifier
            strOtherPersonIdentifierIssueCountry
            dtOtherPersonIdentifierValidDateFrom
            dtOtherPersonIdentifierValidDateTo
            strOtherPersonIdentifierDesc 
            intOtherPersonIdentifierTypeID
            strP1FName 
            strP1SName 
            strP1Phone 
            strP1Email 
            dtSuspendedUntil
        ),

        map("strNatCustomStr$_", (1..15)),
        map("dblNatCustomDbl$_", (1..10)),
        map("dtNatCustomDt$_", (1..5)),
        map("intNatCustomLU$_", (1..10)),
        map("intNatCustomBool$_", (1..5)),
        qw(
        strNotes SPdetails dtLastUpdate
        )
        ],
        fieldtransform => {
            textcase => {
                strLocalFirstname => $field_case_rules->{'strLocalFirstname'} || '',
                strLocalSurname   => $field_case_rules->{'strLocalSurname'}   || '',
                strSuburb    => $field_case_rules->{'strSuburb'}    || '',
            }
        },
        sections => [
        [ 'regoform',       q{} ],
        [ 'details',        'Personal Details' ],
        [ 'contact',        'Contact Details' ],
        [ 'identification', 'Identification' ],
        [ 'profile',        'Profile' ],
        [ 'contracts',      'Contracts' ],
        [ 'citizenship',    'Citizenship' ],
        [ 'parent',         'Parent/Guardian' ],
        [ 'custom1',        $Data->{'SystemConfig'}{'MF_CustomGroup1'} ],
        [ 'other',          'Other Details' ],
        [ 'records',        'Initial Person Records' ],
        ],
        options => {
            labelsuffix          => ':',
            hideblank            => 1,
            target               => $Data->{'target'},
            formname             => 'm_form',
            submitlabel          => $Data->{'lang'}->txt( 'Update ' . $Data->{'LevelNames'}{$Defs::LEVEL_PERSON} ),
            buttonloc            => $Data->{'SystemConfig'}{'HTMLFORM_ButtonLocation'} || 'both',
            OptionAfterProcessed => 'display',
            updateSQL            => qq[
            UPDATE tblPerson
            SET --VAL--
            WHERE tblPerson.intPersonID=$personID
            ],
            addSQL => qq[
            INSERT INTO tblPerson (intRealmID, strStatus, --FIELDS--)
            VALUES ($Data->{'Realm'},  'INPROGRESS', --VAL--)
            ],
            NoHTML               => 1,
            afterupdateFunction  => \&postPersonUpdate,
            afterupdateParams    => [ $option, $Data, $Data->{'db'}, $personID, $field ],
            afteraddFunction     => \&postPersonUpdate,
            afteraddParams       => [ $option, $Data, $Data->{'db'} ],
            beforeaddFunction    => \&prePersonAdd,
            beforeaddParams      => [ $option, $Data, $Data->{'db'} ],
            afteraddAction       => 'edit',

            auditFunction  => \&auditLog,
            auditAddParams => [
            $Data,
            'Add',
            'Person'
            ],
            auditEditParams => [
            $personID,
            $Data,
            'Update',
            'Person',
            ],
            auditEditParamsAddFields => 1,

            LocaleMakeText        => $Data->{'lang'},
            pre_button_bottomtext => $Data->{'SystemConfig'}{'PersonFooterText'} || '',
        },
        carryfields => {
            client => $client,
            a      => $action,
        },
    );

    ######################################################
    # generate custom fileds definitions
    ######################################################

    # map("strNatCustomStr$_", (1..15)),
    for my $i (1..15) {
        my $fieldname = "strNatCustomStr$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'text',
            size  => '30',
            maxsize     => '50',
            sectionname => 'other',
            readonly    => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
        };
    }

    # map("dblNatCustomDbl$_", (1..10)),
    for my $i (1..10) {
        my $fieldname = "dblNatCustomDbl$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'text',
            size  => '10',
            maxsize     => '15',
            sectionname => 'other',
            readonly    => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
        };
    }

    # map("dtNatCustomDt$_", (1..5)),
    for my $i (1..5) {
        my $fieldname = "dtNatCustomDt$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'date',
            format      => 'dd/mm/yyyy',
            sectionname => 'other',
            validate    => 'DATE',
            readonly    => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
        };
    }

    # map("intNatCustomLU$_", (1..10)),
    my @intNatCustomLU_DefsCodes = (undef, -53, -54, -55, -64, -65, -66, -67, -68,-69,-70);
    for my $i (1..10) {
        my $fieldname = "intNatCustomLU$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'lookup',
            options     => $DefCodes->{$intNatCustomLU_DefsCodes[$i]},
            order       => $DefCodesOrder->{$intNatCustomLU_DefsCodes[$i]},
            firstoption => [ '', " " ],
            sectionname => 'other',
            readonly    => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
            translateLookupValues => 1,
        };
    }

    # map("intNatCustomBool$_", (1..5)),
    for my $i (1..5) {
        my $fieldname = "intNatCustomBool$i";

        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'checkbox',
            sectionname   => 'other',
            displaylookup => { 1 => $Data->{'lang'}->txt('Yes'), 0 => $Data->{'lang'}->txt('No') },
            readonly      => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
        };
    }
    my $resultHTML = '';
    
    my $fieldperms = $Data->{'Permissions'};
   
    my $memperm = ProcessPermissions($fieldperms, \%FieldDefinitions, 'Person',);
   
    
             
    if($Data->{'SystemConfig'}{'AllowDeRegister'}) {
        $memperm->{'intDeRegister'}=1;
    }
    
    my %configchanges = ();
    if ( $Data->{'SystemConfig'}{'PersonFormReLayout'} ) {
        %configchanges = eval( $Data->{'SystemConfig'}{'PersonFormReLayout'} );
    }
    
    
    return \%FieldDefinitions if $Data->{'RegoForm'};
    return ( \%FieldDefinitions, $memperm ) if $returndata;
    my $processed = 0;
    my $header ='';
    my $tabs = '';
    my $fd = \%FieldDefinitions;
    ( $resultHTML, $processed, $header, $tabs ) = handleHTMLForm( \%FieldDefinitions, $memperm, $option, 0, $Data->{'db'}, \%configchanges );

    if ($option ne 'display') {
        $resultHTML .= '';
    }
$tabs = '
<div class="new_tabs_wrap">
<ul class="new_tabs">
  '.$tabs.'
	<li><a id="a_showall" href="#showall" class="tab_links">Show All</a></li>
</ul>
</div>
								';
my $person_photo = qq[
        <div class="person-edit-info">
<div class="photo">$photolink</div>
        <span class="button-small mobile-button"><a href="?client='.$client.'&amp;a=P_PH_d">Add/Edit Photo</a></span>
      </div>
];
        #<h4>Documents</h4>
        #<span class="btn-inside-panels"><a href="?client='.$client.'&amp;a=DOC_L">Add Document</a></span>
$person_photo = '' if($option eq 'add');
#$tabs = '' if($option eq 'add'); #WR: may need to go back in
	$resultHTML =qq[
 $tabs
$person_photo
			<div class="col-md-9"><div class="panel-body">$resultHTML</div></div>
<style type="text/css">.pageHeading{font-size:48px;font-family:"DINMedium",sans-serif;letter-spacing:-2px;margin:40px 0;}.ad_heading{margin: 36px 0 0 0;}</style>] if!$processed;
    $resultHTML = qq[<p>$Data->{'PersonClrdOut'}</p> $resultHTML] if $Data->{'PersonClrdOut'};
    $option = 'display' if $processed;
    my $chgoptions = '';
    my $title = ( !$field->{strLocalFirstname} and !$field->{strLocalSurname} ) ? "Add New $Data->{'LevelNames'}{$Defs::LEVEL_PERSON}" : "$field->{strLocalFirstname} $field->{strLocalSurname}";

    if ( $option eq 'display' ) {

        $chgoptions .= qq[<a href="$Data->{'target'}?client=$client&amp;a=P_DEL"  onclick="return confirm('Are you sure you want to Delete this $Data->{'LevelNames'}{$Defs::LEVEL_PERSON}');"><img src="images/delete_icon.gif" border="0" alt="Delete $Data->{'LevelNames'}{$Defs::LEVEL_PERSON}" title="Delete $Data->{'LevelNames'}{$Defs::LEVEL_PERSON}"></a>]
          if ( allowedAction( $Data, 'm_d' ) and $Data->{'SystemConfig'}{'AllowPersonDelete'} );

        $chgoptions = '' if $Data->{'SystemConfig'}{'LockPerson'};

        $chgoptions = qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;

        $resultHTML = $resultHTML;

        my @taboptions = ();
        my @tabdata    = ();

        #if ( $clubStatus == $Defs::RECSTATUS_INACTIVE and $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB ) {
        #    $chgoptions = '';
        #    $title .= " - <b><i>Restricted Access</i></b> ";
        #}

        $title = $chgoptions . $title;
        $title .= " - ON PERMIT " if $Data->{'PersonOnPermit'};

        my $clearancehistory = clearanceHistory( $Data, $personID ) || '';
        if ($clearancehistory) {
            push @tabdata, qq[<div id="clearancehistory_dat">$clearancehistory</div>];
            my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
            push @taboptions, [ 'clearancehistory_dat', "$txt_Clr History" ];
        }

        my $tabstr    = '';
        my $tabheader = '';

        $tabheader = qq[<ul>$tabheader</ul>] if $tabheader;
	if ($tabstr) {
            $Data->{'AddToPage'}->add( 'js_bottom', 'inline', "jQuery('#persontabs').tabs();" );

            $resultHTML .= qq[
				<div class = "small-widget-text">
				<div id="persontabs" style="float:left;clear:right;width:99%;">
					$tabheader
					$tabstr
				</div><!-- end persontabs -->
				</div>
			];
        }

    }
    return ( $resultHTML, $title );
}

sub loadPersonDetails {
    my ( $Data, $id) = @_;
    return {} if !$id;
    my $db = $Data->{'db'};
    my $statement = qq[
	SELECT
		tblPerson.*,
		DATE_FORMAT(dtPassportExpiry,'%d/%m/%Y') AS dtPassportExpiry,
		DATE_FORMAT(dtDOB,'%d/%m/%Y') AS dtDOB,
		dtDOB AS dtDOB_RAW,
		TIMESTAMPDIFF(YEAR, dtDOB, CURDATE()) as currentAge,
		DATE_FORMAT(dtPoliceCheck,'%d/%m/%Y') AS dtPoliceCheck,
		DATE_FORMAT(dtPoliceCheckExp,'%d/%m/%Y') AS dtPoliceCheckExp,
		DATE_FORMAT(dtNatCustomDt1,'%d/%m/%Y') AS dtNatCustomDt1,
		DATE_FORMAT(dtNatCustomDt2,'%d/%m/%Y') AS dtNatCustomDt2,
		DATE_FORMAT(dtNatCustomDt3,'%d/%m/%Y') AS dtNatCustomDt3,
		DATE_FORMAT(dtNatCustomDt4,'%d/%m/%Y') AS dtNatCustomDt4,
		DATE_FORMAT(dtNatCustomDt5,'%d/%m/%Y') AS dtNatCustomDt5,
		MN.strNotes
		FROM
			tblPerson
			LEFT JOIN tblPersonNotes as MN ON (
				MN.intPersonID = tblPerson.intPersonID
			)
    	WHERE
		    tblPerson.intPersonID = ?
	];

    my $query = $db->prepare($statement);
    $query->execute( $id);
    my $field = $query->fetchrow_hashref();
    if ($field) {
        if ( !defined $field->{dtDOB} ) {
            $field->{dtDOB_year} = $field->{dtDOB_month} = $field->{dtDOB_day} = $field->{dtDOB} = '';
        }
        else {
            ( $field->{dtDOB_year}, $field->{dtDOB_month}, $field->{dtDOB_day} ) = $field->{dtDOB_RAW} =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
            $field->{'currentAge'} = PersonUtils::personAge($Data, $field->{'dtDOB_RAW'});
        }
    }

    $query->finish;
   
    foreach my $key ( keys %{$field} ) {
        if ( !defined $field->{$key} ) { $field->{$key} = ''; }
       
    }
    
    return $field;
}

sub NewRegoButton   {

    my ($Data, $clm) = @_;

    my $lang = $Data->{'lang'};
    return qq[
        <a href="$Data->{'target'}?client=$clm&amp;a=PF_&amp;rfp=r&amp;_ss=r">]. $lang->txt('Add Registration') . qq[</a>
    ];
}

sub postPersonUpdate {
    my ( $id, $params, $action, $Data, $db, $personID, $fields ) = @_;

    $personID ||= 0;
    $id ||= $personID;
    return ( 0, undef ) if !$db;

    my $assocID = $Data->{'clientValues'}{'assocID'} || 0;
    my $entityID = getLastEntityID($Data->{'clientValues'});
    $Data->{'cache'}->delete( 'swm', "PersonObj-$id-$entityID" ) if $Data->{'cache'};
    $Data->{'cache'}->delete( 'swm', "PersonObj-$id" ) if $Data->{'cache'};

    my %types        = ();
    my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
    $types{'intPlayerStatus'} = $params->{'d_intPlayer'} if exists( $params->{'d_intPlayer'} );
    $types{'intCoachStatus'}  = $params->{'d_intCoach'}  if exists( $params->{'d_intCoach'} );
    $types{'intUmpireStatus'} = $params->{'d_intUmpire'} if exists( $params->{'d_intUmpire'} );
    $types{'intMiscStatus'}  = $params->{'d_intMisc'}  if exists( $params->{'d_intMisc'} );
    $types{'intVolunteerStatus'}  = $params->{'d_intVolunteer'}  if exists( $params->{'d_intVolunteer'} );

    my $genAgeGroup ||= new GenAgeGroup( $Data->{'db'}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $Data->{'clientValues'}{'assocID'} );
    my $st = qq[
		SELECT DATE_FORMAT(dtDOB, "%Y%m%d"), intGender, intInternationalTransfer
		FROM tblPerson
		WHERE intPersonID = ?
	];
    my $qry = $db->prepare($st);
    $qry->execute($id);
    my ( $DOBAgeGroup, $Gender, $itc ) = $qry->fetchrow_array();
    $DOBAgeGroup ||= '';
    $Gender      ||= 0;
    my $ageGroupID = $genAgeGroup->getAgeGroup( $Gender, $DOBAgeGroup ) || 0;

    updatePersonNotes( $db, $id, $params );

    if ( $action eq 'add' ) {
        $types{'intMSRecStatus'} = 1;
        if ($id) {

        }
        #getAutoPersonNum( $Data, undef, $id, $Data->{'clientValues'}{'assocID'} );
        #Seasons::insertPersonSeasonRecord( $Data, $id, $assocSeasons->{'newRegoSeasonID'}, $Data->{'clientValues'}{'assocID'}, 0, $ageGroupID, \%types ) if ($id);
        my $cl = setClient( $Data->{'clientValues'} ) || '';
        my %cv = getClient($cl);
        $cv{'personID'}     = $id;
        $cv{'currentLevel'} = $Defs::LEVEL_PERSON;
        my $clm = setClient( \%cv );
        if ( $params->{'isDuplicate'} ) {
            my $st = qq[
                UPDATE tblPerson SET intSystemStatus=$Defs::PERSONSTATUS_POSSIBLE_DUPLICATE
                WHERE intPersonID=$id
            ];
            $db->do($st);
            my $body = DuplicateExplanation($Data);
            $body .= NewRegoButton($Data, $clm);
            return (0, $body);
        }
        else {
            my $rc = WorkFlow::addWorkFlowTasks(
                $Data,
                'PERSON',
                'NEW',
                $Data->{'clientValues'}{'authLevel'} || 0,
                getID($Data->{'clientValues'}) || 0,
                $id,
                0,
                0,
		$itc
            );

            my $body = qq[
                <div class="OKmsg"> $Data->{'LevelNames'}{$Defs::LEVEL_PERSON} Added Successfully</div><br>
            ];
                #<a href="$Data->{'target'}?client=$clm&amp;a=P_HOME">Display Details for $params->{'d_strLocalFirstname'} $params->{'d_strLocalSurname'}</a><br><br>
                #<b>or</b><br><br>
                #<a href="$Data->{'target'}?client=$cl&amp;a=P_A&amp;l=$Defs::LEVEL_PERSON">Add another $Data->{'LevelNames'}{$Defs::LEVEL_PERSON}</a>
            $body .= qq[<br>]. NewRegoButton($Data, $clm);
            return (0, $body);

            #</RE>
        }
    }
    else {
        my $status = $params->{'d_strStatus'} || $params->{'strStatus'} || 0;
        if ( $status == 1 ) {
            my $st = qq[UPDATE tblPerson SET intSystemStatus = 1 WHERE intPersonID = $id AND intSystemStatus = 0 LIMIT 1];
            $db->do($st);
        }
        warn("INSERT PRODUCTS");

        ## CHECK IF FIRSTNAME, SURNAME OR DOB HAVE CHANGED
        my $firstname_p = $params->{'d_strLocalFirstname'} || $params->{'strLocalFirstname'} || '';
        my $lastname_p  = $params->{'d_strLocalSurname'}   || $params->{'strLocalSurname'}   || '';
        my $dob_p       = $params->{'d_dtDOB'}        || $params->{'dtDOB'}        || '';
        my $email_p     = $params->{'d_strEmail'}     || $params->{'strEmail'}     || '';

        my $isonat_p    = $params->{'d_strISONationality'} || $params->{'strISONationality'} || '';

        my $firstname_f = $fields->{'strLocalFirstname'} || '';
        my $lastname_f  = $fields->{'strLocalSurname'}   || '';
        my $dob_f       = $fields->{'dtDOB'}        || '';
        my $email_f     = $fields->{'strEmail'}     || '';

        my $isonat_f    = $fields->{'strISONationality'} || '';

        my ( $d, $m, $y ) = split /\//, $dob_f;
        $dob_f = qq[$y-$m-$d];
        my ( $dob_p_y, $dob_p_m, $dob_p_d ) = split /-/, $dob_p if ($dob_p);
        $dob_p = sprintf( "%02d-%02d-%02d", $dob_p_y, $dob_p_m, $dob_p_d ) if ($dob_p);

        my $dupl_check = 0;
        $dupl_check = 1 if ( $firstname_p and $firstname_p ne $firstname_f );
        $dupl_check = 1 if ( $lastname_p  and $lastname_p ne $lastname_f );
        $dupl_check = 1 if ( $dob_p       and $dob_p ne $dob_f );

        if ( $dupl_check == 1 ) {
            my $st = qq[UPDATE tblPerson SET intSystemStatus = 2 WHERE intPersonID = $id LIMIT 1];
            $db->do($st);
        }

        my @fieldsToTriggerWF = split /\|/, $Data->{'SystemConfig'}{'triggerWorkFlowPersonDataUpdate'};
        
        if(scalar(@fieldsToTriggerWF)) {
            my $triggerWFPersonUpdate = 0;
            foreach (@fieldsToTriggerWF) {
                my $field = $_;
                next if !$field || $triggerWFPersonUpdate;

                my $prevVal = $params->{'d_' . $field};
                my $currVal = $fields->{$field};

                if($field eq 'dtDOB'){
                    my ( $d, $m, $y ) = split /\//, $currVal;
                    $currVal = qq[$y-$m-$d];
                    my ( $dob_p_y, $dob_p_m, $dob_p_d ) = split /-/, $prevVal if ($prevVal);
                    $prevVal = sprintf( "%02d-%02d-%02d", $dob_p_y, $dob_p_m, $dob_p_d ) if ($prevVal);
                }
                #check input field value and pre-update person details
                $triggerWFPersonUpdate = 1 if($currVal and $currVal ne $prevVal);
            }

            if($triggerWFPersonUpdate){
                #FC-71 - set person status to PENDING and add WF for re-approval
                my $st = qq[UPDATE tblPerson SET strStatus = "$Defs::PERSON_STATUS_PENDING" WHERE intPersonID = $id LIMIT 1];
                
                if($db->do($st)) {
                    my $originEntityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'authLevel'}) || getLastEntityID($Data->{'clientValues'});

                    my $rc = WorkFlow::addWorkFlowTasks(
                        $Data,
                        'PERSON',
                        'AMENDMENT',
                        $Data->{'clientValues'}{'authLevel'} || 0,
                        $originEntityID,
                        $id,
                        0,
                        0,
			$itc
                    );
                }

            }

        }

    }

    return ( 1, '' );
}

sub prePersonAdd {
    my ( $params, $action, $Data, $db, $typeofDuplCheck ) = @_;

    if ($Data->{'SystemConfig'}{'checkPrimaryClub'} or $Data->{'SystemConfig'}{'DuplicatePrevention'}) {

        my %newPerson = (
            firstname => $params->{'d_strLocalFirstname'},
            surname   => $params->{'d_strLocalSurname'},
            dob       => $params->{'d_dtDOB'},
        );

        my $resultHTML = '';

        #At some stage PrimaryClub and DuplicatePrevention may/should become intertwined.
        #Currently, PrimaryClub workings haven't been finalised; nor has primary club been set for each person.

        if ($Data->{'SystemConfig'}{'checkPrimaryClub'}) {
            my $format = 1; #This should be set to 2 when the TransferLink part is working...mick

            $resultHTML = checkPrimaryClub($Data, \%newPerson, $format);
        }

        if (!$resultHTML) {
            if ($Data->{'SystemConfig'}{'DuplicatePrevention'}) {
                my $prefix = (exists $params->{'formID'} and $params->{'formID'}) ? 'yn' : 'd_int';

                my @personTypes = ($prefix.'Player', $prefix.'Coach', $prefix.'MatchOfficial', $prefix.'Official', $prefix.' Misc', $prefix.' Volunteer');

                my @registeringAs = ();

                foreach my $personType (@personTypes) {
                    push @registeringAs, $personType if (exists $params->{$personType} and $params->{$personType});
                }

                $resultHTML = duplicate_prevention($Data, \%newPerson, \@registeringAs);
            }
        }

        return (0, $resultHTML) if $resultHTML;
    }

    #This Function checks for duplicates
    my $realmID = $Data->{'Realm'} || 0;

    $typeofDuplCheck ||= '';

    my $duplcheck = $typeofDuplCheck || DuplicatesUtils::isCheckDupl($Data) || '';

    if ($duplcheck) {

        #Check for Duplicates
        my @FieldsToCheck = DuplicatesUtils::getDuplFields($Data);
        return ( 1, '' ) if !@FieldsToCheck;

        my $st        = q{};
        my $wherestr  = q{};
        my $joinCheck = q{};

        my ( @st_fields, @where_fields, @joinCheck_fields );

        if ( $params->{'ID'} ) {
            $wherestr .= 'AND tblPerson.intPersonID <> ?';
            push @where_fields, $params->{'ID'};
        }

        for my $i (@FieldsToCheck) {
            if ( $i =~ /^dt/ and $Data->{'RegoFormID'} ) {

                $wherestr .= qq[ AND $i=COALESCE(STR_TO_DATE(?,'%d/%m/%Y'), STR_TO_DATE(?, '%Y-%m-%d'))];

                my $date = $params->{ 'd_' . $i };
                push @where_fields, $date, $date;
            }
            else {
                $wherestr .= " AND  $i = ?";
                push @where_fields, $params->{ 'd_' . $i };
            }
        }

        if ( $params->{'ID_IN'} ) {
            $wherestr     = 'AND tblPerson.intPersonID = ?';
            @where_fields = ( $params->{'ID_IN'} );
        }

        if ( $duplcheck eq 'realm' ) {
            $st = qq[
				SELECT tblPerson.intPersonID
				FROM tblPerson
                WHERE  tblPerson.intRealmID = ? AND tblPerson.intSystemStatus <> ?
					$wherestr
                ORDER BY tblPerson.intSystemStatus
				LIMIT 1
			];
            @st_fields = (@joinCheck_fields, $realmID, $Defs::PERSONSTATUS_DELETED, @where_fields,);
        }
        my $q = $db->prepare($st);
        $q->execute(@st_fields);
        my $dupl = $q->fetchrow_array;
        $q->finish();
        $dupl ||= 0;
        $params->{'isDuplicate'} = $dupl;

    }
    return ( 1, '' );
}

sub DuplicateExplanation {
    my ($Data) = @_;

    my $msg = '<div class="warningmsg">Person is Possible Duplicate</div>';
    my $currentLevel = $Data->{'clientValues'}{'currentLevel'} || $Defs::LEVEL_NONE;

    my $client = setClient( $Data->{'clientValues'} ) || '';
    my $link = "$Data->{'target'}?client=$client&amp;a=DUPL_L";

    if ( $currentLevel == $Defs::LEVEL_ASSOC ) {
        $msg .= qq[
			<p>The $Data->{'LevelNames'}{$Defs::LEVEL_PERSON} you have added possibly duplicates another record that already exists in this system.</p>
			<p>This $Data->{'LevelNames'}{$Defs::LEVEL_PERSON} <b>has</b> been temporarily added but their details will not be available.</p>
			<p>You should resolve this and any other duplicates as soon as possible by proceeding to the <b>Duplicate Resolution</b> section.</p>
			<p><a href="$link">Resolve Duplicates</a></p>
		];
    }
    elsif ( $currentLevel < $Defs::LEVEL_ASSOC ) {
        $msg .= qq[
			<p>The $Data->{'LevelNames'}{$Defs::LEVEL_PERSON} you have added possibly duplicates another record that already exists in this system.  </p>
			<p>This $Data->{'LevelNames'}{$Defs::LEVEL_PERSON} <b>has</b> been temporarily added but their details will not be available. They will remain this way until your $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} has resolved this issue.</p>
		];
    }
    elsif ( $currentLevel > $Defs::LEVEL_ASSOC ) {
        $msg .= qq[
			<p>The $Data->{'LevelNames'}{$Defs::LEVEL_PERSON} you have added possibly duplicates another record that already exists in this system.  </p>
			<p>This $Data->{'LevelNames'}{$Defs::LEVEL_PERSON} <b>has</b> been temporarily added but their details will not be available. </p>
			<p>You need to proceed to the $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} and choose the <b>Duplicate Resolution</b> option to resolve this issue.</p>
		];
    }
    return $msg;
}

sub getAutoPersonNum {
    my ( $Data, $genCode, $personID, $assocID ) = @_;

    if ( $Data->{'SystemConfig'}{'GenPersonNo'} ) {
        my $num_field = $Data->{'SystemConfig'}{'GenNumField'} || 'strNationalNum';
        my $CreateCodes = 0;
        if ( exists $Data->{'SystemConfig'}{'GenNumAssocIn'} ) {
            my @assocs = split /\|/, $Data->{'SystemConfig'}{'GenNumAssocIn'};
            for my $i (@assocs) { $CreateCodes = 1 if $i == $assocID; }
        }
        else { $CreateCodes = 1; }
        if ($CreateCodes) {
            $genCode ||= new GenCode( $Data->{'db'}, 'PERSON', $Data->{'Realm'}, $Data->{'RealmSubType'} );
            my $num = $genCode->getNumber({


            });
            if ($num) {
                my $st = qq[
						UPDATE tblPerson SET $num_field = ?
						WHERE intPersonID = ?
				];
                $Data->{'db'}->do( $st, undef, $num, $personID );
                return $num;
            }
        }
    }
    return undef;
}

sub delete_person {
    my ( $Data, $personID ) = @_;

    my $aID = $Data->{'clientValues'}{'assocID'} || 0;    #Current Association
    return '' if ( !( allowedAction( $Data, 'm_d' ) and $Data->{'SystemConfig'}{'AllowPersonDelete'} ) );
######## NEEDS THINK ABOUT WR WARREN warren wsc

    my $st = qq[UPDATE tblPerson_Associations SET strStatus=$Defs::RECSTATUS_DELETED WHERE intPersonID=$personID AND intAssocID=$aID];
    $Data->{'db'}->do($st);
    $Data->{'clientValues'}{'personID'} = $Defs::INVALID_ID;
    {
        if ( $Data->{'clientValues'}{'teamID'} and $Data->{'clientValues'}{'teamID'} != $Defs::INVALID_ID ) {
            $Data->{'clientValues'}{'currentLevel'} = $Defs::LEVEL_TEAM;
        }
        elsif ( $Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'clubID'} != $Defs::INVALID_ID ) {
            $Data->{'clientValues'}{'currentLevel'} = $Defs::LEVEL_CLUB;
        }
        else {
            $Data->{'clientValues'}{'currentLevel'} = $Defs::LEVEL_ASSOC;
        }
        $Data->{'clientValues'}{'currentLevel'} = $Defs::INVALID_ID if $Data->{'clientValues'}{'authLevel'} < $Data->{'clientValues'}{'currentLevel'};
    }

    return ( qq[<div class="OKmsg">$Data->{'LevelNames'}{$Defs::LEVEL_PERSON} deleted successfully</div>], "Delete $Data->{'LevelNames'}{$Defs::LEVEL_PERSON}" );

}

sub PersonDupl {
    my ( $action, $Data, $personID ) = @_;

    $personID ||= 0;
    return '' if !$personID;
    my ( $resultHTML, $pageHeading ) = handleDuplicateFlow($action, $Data, $personID);
    return $resultHTML;

}

sub check_valid_date {
    my ($date) = @_;
    my ( $d, $m, $y ) = split /\//, $date;
    use Date::Calc qw(check_date);
    return check_date( $y, $m, $d );
}

sub _fix_date {
    my ($date) = @_;
    return '' if !$date;
    my ( $dd, $mm, $yyyy ) = $date =~ m:(\d+)/(\d+)/(\d+):;
    if ( !$dd or !$mm or !$yyyy ) { return ''; }
    if ( $yyyy < 100 ) { $yyyy += 2000; }
    return "$yyyy-$mm-$dd";
}

sub calculateAgeLevel {
    my($Data, $currentAge) = @_;

    my @RealmAdultAge = split(/\-/, $Data->{'SystemConfig'}{'AdultAge'});

    my $adultAgeFrom = $RealmAdultAge[0];
    my $adultAgeTo = (!defined($RealmAdultAge[1])) ? $adultAgeFrom : $RealmAdultAge[1];

    my $personAgeLevel = undef;

    if(($currentAge >= $adultAgeFrom) and ($currentAge <= $adultAgeTo)) {
        $personAgeLevel = $Defs::AGE_LEVEL_ADULT;
    }
    elsif($currentAge < $adultAgeFrom) {
        $personAgeLevel = $Defs::AGE_LEVEL_MINOR;
    }

    return $personAgeLevel;
}

1;
