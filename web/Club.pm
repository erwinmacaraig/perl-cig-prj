package Club;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleClub loadClubDetails);
@EXPORT_OK=qw(handleClub loadClubDetails);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use CustomFields;
use ConfigOptions qw(ProcessPermissions);
use ClubCharacteristics;
use RecordTypeFilter;
use GridDisplay;

use ServicesContacts;
use Contacts;
use Logo;
use HomeClub;
use FieldCaseRule;
use DefCodes;
use TransLog;
use Transactions;
use EntityStructure;
use WorkFlow;
use RuleMatrix;
use InstanceOf;
use EntityDocuments;
use EntityIdentifier;
use Data::Dumper;
use RegistrationItem;
use TTTemplate;
use DBI;
use Countries;
sub handleClub  {
  my ($action, $Data, $parentID, $clubID, $typeID)=@_;

  my $resultHTML='';
  my $clubName=
  my $title='';
  $typeID=$Defs::LEVEL_CLUB if $typeID==$Defs::LEVEL_NONE;
    print STDERR "AAAA" . $Data->{'clientValues'}{'clubID'};
print STDERR "CCCCCC:$clubID $parentID";
  if ($action =~/^C_DT/) {
    #Club Details
      ($resultHTML,$title)=club_details($action, $Data, $clubID);
  }
  elsif ($action =~/C_CFG_/) {
    #Club Configuration
  }
  elsif ($action =~/^C_L/) {
        ($resultHTML,$title)=listClubs($Data, $parentID);
  }
  elsif ($action=~/^C_HOME/) {
      ($resultHTML,$title)=showClubHome($Data,$clubID);
  }
  elsif($action =~ /^C_DOCS/){
  	($resultHTML, $title) = handle_entity_documents($action, $Data, $clubID, $typeID, $Defs::DOC_FOR_CLUBS);  	
  }
  elsif ( $action =~ /^C_TXN_/ ) {
        ( $resultHTML, $title ) = Transactions::handleTransactions( $action, $Data, $clubID, 0);
  }
  elsif ( $action =~ /^C_TXNLog/ ) {
        ( $resultHTML, $title ) = TransLog::handleTransLogs( $action, $Data, $clubID, 0);
  }
  elsif ( $action =~ /^C_ID_/ ) {
        ( $resultHTML, $title ) = handleEntityIdentifiers($action, $Data, $clubID);
  }
    
  return ($resultHTML,$title);
}


sub club_details  {
  my ($action, $Data, $clubID)=@_;

  
print STDERR "SSSS$action $clubID\n";  
  
  
 
  my $field=loadClubDetails($Data->{'db'}, $clubID,$Data->{'clientValues'}{'assocID'}) || ();
  my $client=setClient($Data->{'clientValues'}) || '';
  
  #my $allowedit =( ($field->{strStatus} eq 'ACTIVE' ? 1 : 0) || ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 ) );
  my $allowedit =($field->{strStatus} eq 'ACTIVE' ? 1 : 0);
  my $allowadd = $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ZONE ? 1 : 0;

    $Data->{'ReadOnlyLogin'} ? $allowedit = 0 : undef;
    
    my $option='display';       
   
   $option='edit' if $action eq 'C_DTE' and allowedAction($Data, 'c_e') && $allowedit;
   $option='add' if $action eq 'C_DTA' and allowedAction($Data, 'c_a')  && $allowadd;
   $clubID=0 if $option eq 'add';
  
  my $club_chars = getClubCharacteristicsBlock($Data, $clubID) || '';

  my $field_case_rules = get_field_case_rules({dbh=>$Data->{'db'}, client=>$client, type=>'Club'});

  my $authID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'});

  my $paymentRequired = 0;
  if ($option eq 'add')   {
      my %Reg=();
      $Reg{'registrationNature'}='NEW';
      my $matrix_ref = getRuleMatrix($Data, $Data->{'clientValues'}{'authLevel'}, getLastEntityLevel($Data->{'clientValues'}), $Defs::LEVEL_CLUB, $field->{'strEntityType'}, 'ENTITY', \%Reg);
      $paymentRequired = $matrix_ref->{'intPaymentRequired'} || 0;
  }
  my %keyparams = (); 
  foreach my $i (keys $Data->{clientValues}){
   $keyparams{$i} = $Data->{clientValues}{$i};
  }
  
  
  my %legalTypeOptions = ();
  
  my $query = "SELECT strLegalType, intLegalTypeID FROM tblLegalType WHERE intRealmID IN (0,?)"; 
   my $sth = $Data->{'db'}->prepare($query);
  $sth->execute($Data->{'Realm'}); 
  while(my $href = $sth->fetchrow_hashref()){
  	$legalTypeOptions{$href->{'intLegalTypeID'}} = $href->{'strLegalType'};
  }
  $sth->finish();
  
  #my $kk = $field->{intLegalTypeID};
  #my $vv = $legalTypeOptions{$field->{intLegalTypeID}} || 'Select Type';  
  #  if(!%legalTypeOptions ||  !$field->{intLegalTypeID}){
  #   	   $kk = '';
  #		   $vv = 'Select Type';	
  #  }
  #[ $field->{intLegalTypeID}, $legalTypeOptions{$field->{intLegalTypeID}} ]
   my $isocountries = getISOCountriesHash();
  ######Limited List of Country Per MA ############################
    my %countriesonly = ();
    my %Mcountriesonly = ();
  
    my @limitCountriesArr = ();
    if($Data->{'RegoForm'} && $Data->{'SystemConfig'}{'AllowedRegoCountries'}){
    	@limitCountriesArr = split(/\|/, $Data->{'SystemConfig'}{'AllowedRegoCountries'} );    	
    }
  
    while(my($k,$c) = each(%{$isocountries})){
    	$countriesonly{$c} = $c;
    	if(@limitCountriesArr){
    		next if(grep(/^$c/, @limitCountriesArr));
    	}
    	$Mcountriesonly{$c} = $c;
    }
    
    #################################################################
  
  my %FieldDefinitions=(
    fields=>  {
      strFIFAID => {
        label => 'FIFA ID',
        value => $field->{strFIFAID},
        type  => 'text',
        size  => '40',
        maxsize => '150',
        readonly =>($Data->{'clientValues'}{authLevel} < $Defs::LEVEL_NATIONAL),
      },
      strLocalName => {
        label => 'Name',
        value => $field->{strLocalName},
        type  => 'text',
        size  => '40',
        maxsize => '150',
      },
      strLocalShortName => {
        label => 'Short Name',
        value => $field->{strLocalShortName},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },      
      strLatinName => {
        label => 'International Name',
        value => $field->{strLatinName},
        type  => 'text',
        size  => '40',
        maxsize => '150',
      },
      strLatinShortName => {
        label => 'International Short Name',
        value => $field->{strLatinShortName},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },
      intLegalTypeID => {
        label => "Legal Entity Type",
        value => $field->{intLegalTypeID},
        type => 'lookup',
        options => \%legalTypeOptions,
        firstoption => [ '', 'Select Type' ],       
        readonly =>($Data->{'clientValues'}{authLevel} < $Defs::LEVEL_NATIONAL),
     },
     strLegalID => {
        label => "Legal Type Number",
        value => $field->{strLegalID},
        type  => 'text',
        size  => '30',
        maxsize => '50',       
      },
      strEntityType => {
        label => "Entity Type",
        value => $field->{strEntityType},
        type => 'lookup',
        options => \%Defs::clubLevelSubtype,
        firstoption => [ '', 'Select Type' ],
     },
      strStatus => {
          label => 'Status',
          value => $field->{strStatus},
          type => 'lookup',  
          options => \%Defs::entityStatus,
          readonly => $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 0 : 1,
          noadd         => 1,
     },
      strContact => {
        label => '',
        value => $field->{strContact},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },
      strContactTitle => {
        label => '',
        value => $field->{strContactTitle},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },
      strContactEmail => {
        label => '',
        value => $field->{strContactEmail},
        type  => 'text',
        size  => '30',
        maxsize => '250',
        validate => 'EMAIL',
      },
      strContactPhone => {
        label => '',
        value => $field->{strContactPhone},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },

      strAddress => {
        label => 'Address',
        value => $field->{strAddress},
        type  => 'text',
        size  => '40',
        maxsize => '50',
      },
      strTown => {
        label => 'Town',
        value => $field->{strTown},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },
      strRegion => {
        label => 'Region',
        value => $field->{strRegion},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },
      strISOCountry => {
          label       => 'ISO Country',
          value       =>  $field->{strISOCountry} || $Data->{'SystemConfig'}{'DefaultCountry'} || '',
          type        => 'lookup',
          options     => \%Mcountriesonly,
          firstoption => [ '', 'Select Country' ],
      },
      strISOLocalLanguage => {
      	label => 'Local Name Language',
        value => $field->{strISOLocalLanguage},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },
      strPostalCode => {
        label => 'Postal Code',
        value => $field->{strPostalCode},
        type  => 'text',
        size  => '15',
        maxsize => '15',
      },
      strPhone => {
        label => '',
        value => $field->{strPhone},
        type  => 'text',
        size  => '20',
        maxsize => '20',
      },
      strFax => {
        label => '',
        value => $field->{strFax},
        type  => 'text',
        size  => '20',
        maxsize => '20',
      },
      strEmail => {
        label => '',
        value => $field->{strEmail},
        type  => 'text',
        size  => '35',
        maxsize => '250',
        validate => 'EMAIL',
      },
      strMANotes => {
      	label => 'MA Comment',
      	value => $field->{strMANotes},
        type => 'textarea',
        rows => '10',
        cols => '40',
        readonly =>($Data->{'clientValues'}{authLevel} < $Defs::LEVEL_NATIONAL),
      },
      strAssocNature => { 
      	label => 'Association Nature',
      	value => $field->{strAssocNature},
        type => 'text',
        size => 40,
      },
      strWebURL => {
        label => 'Web',
        value => $field->{strWebURL},
        type  => 'text',
        size  => '35',
        maxsize => '250',
      },
      strNotes => {
        label => 'Notes',
        value => $field->{strNotes},
        type => 'textarea',
        rows => '10',
        cols => '40',
      },
      SP1  => {
        type =>'_SPACE_',
      },
      clubcharacteristics => {
        label => 'Which of the following are appropriate to your club?',
        value => $club_chars,
        type  => 'htmlblock',
        sectionname => 'clubdetails',
        SkipProcessing => 1,
        nodisplay => 1,
      },
    },
    order => [qw(
        strFIFAID
        strLocalName
        strLocalShortName
        strLatinName
        strLatinShortName
        strEntityType
        strStatus
        strAssocNature
        intLegalTypeID
        strLegalID
        dtFrom
        dtTo
        strISOCountry
        strISOLocalLanguage
        strRegion
        strPostalCode
        strTown
        strAddress
        strWebURL
        strEmail
        strPhone
        strFax
        strContactEmail        
        strMANotes         
        clubcharacteristics
    )],
    fieldtransform => {
      textcase => {
      strName => $field_case_rules->{'strName'} || '',
      }
    },
    options => {
      labelsuffix => ':',
      hideblank => 1,
      target => $Data->{'target'},
      formname => 'n_form',
      submitlabel => $Data->{'lang'}->txt('Update'),
      introtext => $Data->{'lang'}->txt('HTMLFORM_INTROTEXT'),
      NoHTML => 1, 
      updateSQL => qq[
        UPDATE tblEntity
          SET --VAL--
        WHERE intEntityID=$clubID
      ],
      addSQL => qq[
        INSERT INTO tblEntity (
            intRealmID,
            intEntityLevel,
            intCreatedByEntityID,
            intDataAccess,
            strStatus,
            --FIELDS--
         )
          VALUES (
            $Data->{'Realm'},
            $Defs::LEVEL_CLUB,
            $authID,
            $Defs::DATA_ACCESS_FULL,
            "PENDING",
             --VAL-- )
        ],
      auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Club'
      ],
      auditEditParams => [
        $clubID,
        $Data,
        'Update',
        'Club'
      ],
      afteraddFunction => \&postClubAdd,
      afteraddParams => [$option,$Data,$Data->{'db'}],
      afterupdateFunction => \&postClubUpdate,
      afterupdateParams => [$option,$Data,$Data->{'db'}, $clubID],
      LocaleMakeText => $Data->{'lang'},
    },
    carryfields =>  {
      client => $client,
      a=> $action,
    },
  );
  my $fieldperms=$Data->{'Permissions'};

  my $clubperms=ProcessPermissions(
    $fieldperms,
    \%FieldDefinitions,
    'Club',
  );
  $clubperms->{'clubcharacteristics'} = 1;
my $resultHTML='' ;
($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, $clubperms, $option, '',$Data->{'db'});
  my $title=$field->{'strLocalName'} || '';
  my $scMenu = (allowedAction($Data, 'c_e'))
    ? getServicesContactsMenu($Data, $Defs::LEVEL_CLUB, $clubID, $Defs::SC_MENU_SHORT, $Defs::SC_MENU_CURRENT_OPTION_DETAILS)
    : '';
  my $logodisplay = '';
  my $editlink = (allowedAction($Data, 'c_e')) ? 1 : 0;
  if($option eq 'display')  {
    $resultHTML .= showContacts($Data,0, $editlink);
    my $chgoptions='';
    $chgoptions.=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_DTE">Edit $Data->{'LevelNames'}{$Defs::LEVEL_CLUB}</a></span>] if allowedAction($Data, 'c_e');

    $chgoptions=qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
    $title=$chgoptions.$title;
    $logodisplay = showLogo(
      $Data,
      $Defs::LEVEL_CLUB,
      $clubID,
      $client,
      $editlink,
    );
  }
  $resultHTML = $scMenu.$logodisplay.$resultHTML;
  $title="Add New $Data->{'LevelNames'}{$Defs::LEVEL_CLUB}" if $option eq 'add';
  
  
  return ($resultHTML,$title);
}



sub loadClubDetails {
  my($db, $id) = @_;
                                                                                                        
  my $statement=qq[
    SELECT 
     intEntityID,
     intEntityLevel,
     intRealmID,
     strEntityType,
     strStatus,
     intCreatedByEntityID,
     strFIFAID,
     strLocalName,
     intLegalTypeID,
     strLocalShortName,
     strLocalFacilityName,
     strLatinName,
     strLatinShortName,
     strLatinFacilityName,
     dtFrom,
     dtTo,
     strISOCountry,
     strISOLocalLanguage,
     strRegion,
     strPostalCode,
     strTown,
     strAddress,
     strWebURL,
     strEmail,
     strPhone,
     strFax,
     strAssocNature,
     strMANotes,
     strContactTitle,
     strContactEmail,
     strContactPhone,
     dtAdded,
     tTimeStamp,
     strLegalID
    FROM tblEntity
    WHERE intEntityID = ?
  ];
  my $query = $db->prepare($statement);
  $query->execute($id);
  my $field=$query->fetchrow_hashref();
  $query->finish;
                                                                                                        
  foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
  return $field;
}


sub postClubAdd {
  my($id,$params,$action,$Data,$db)=@_;
  return undef if !$db;
  if($action eq 'add')  {
    if($id) {
      my $entityID = getID($Data->{'clientValues'});
      my $st=qq[
        INSERT INTO tblEntityLinks (intParentEntityID, intChildEntityID)
        VALUES (?,?)
      ];
      my $query = $db->prepare($st);
      $query->execute($entityID, $id);
      $query->finish();
        
    ### A call TO createTempEntityStructure FROM EntityStructure   ###
    createTempEntityStructure($Data); 
    ### End call to createTempEntityStructure FROM EntityStructure###
      addWorkFlowTasks($Data, 'ENTITY', 'NEW', $Data->{'clientValues'}{'authLevel'}, $id,0,0, 0);
    }

    my %clubchars = ();
    for my $k (keys %{$params})  {
      if($k =~ /^cc_cb/)  {
        my $id = $k;
        $id =~s/^cc_cb//;
        $clubchars{$id} = 1;
      }
    }
    if(scalar(keys %clubchars))  {
      updateCharacteristics(
        $Data,
        $id,
        \%clubchars,
      );
    }
    {
      my $cl=setClient($Data->{'clientValues'}) || '';
      my %cv=getClient($cl);
      $cv{'clubID'}=$id;
      $cv{'currentLevel'} = $Defs::LEVEL_CLUB;
      my $clm=setClient(\%cv);
       ############################################################
      my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;
      my $clientValues = $Data->{'clientValues'};
      my $entityRegisteringForLevel = getLastEntityLevel($clientValues) || 0;
      my $entityID = getLastEntityID($clientValues);     
     
      my $required_club_docs = getRegistrationItems(
        $Data,
        'ENTITY',
        'DOCUMENT',
        $originLevel,
        'NEW',
        $entityID,
        $entityRegisteringForLevel,
        0,
        undef,
     );
     
     #what is origin level,is the level for this entity or the level of the person logged in???
     
    my %PageData = (
        target => $Data->{'target'},
        documents => $required_club_docs,
        Lang => $Data->{'lang'},
        client => $clm,
  );  
  my $clubdocs;
  $clubdocs = runTemplate($Data, \%PageData, 'club/required_docs.templ') || '';  
      
      
      
      
      return (0,qq[
     <div class="sectionheader"> $Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Added Successfully</div><br>
      <div>
       $clubdocs
	  </div>
	  <a href="$Data->{'target'}?client=$clm&amp;a=C_DT">Display Details for $params->{'d_strLocalName'}</a><br><br>
        <b>or</b><br><br>
	   <a href="$Data->{'target'}?client=$cl&amp;a=C_DTA&amp;l=$Defs::LEVEL_CLUB">Add another $Data->{'LevelNames'}{$Defs::LEVEL_CLUB}</a>
      ]);
    }
  ###############################################################################  
    
  } ### end if  add
  
} ## end sub

sub postClubUpdate {
  my($id,$params,$action,$Data,$db, $clubID)=@_;
  return undef if !$db;
  $clubID ||= $id || 0;

  my %clubchars = ();
  for my $k (keys %{$params}) {
    if($k =~ /^cc_cb_/)  {
      my $id = $k;
      $id =~s/^cc_cb_//;
      $clubchars{$id} = 1;
    }
  }
  if(scalar(keys %clubchars)) {
    updateCharacteristics(
      $Data,
      $clubID,
      \%clubchars,
    );
  }

  $Data->{'cache'}->delete('swm',"ClubObj-$clubID") if $Data->{'cache'};

}

sub listClubs   {
  my($Data, $entityID) = @_;

  my $db=$Data->{'db'};
  my $resultHTML = '';

  my $lang = $Data->{'lang'};
  my %textLabels = (
      'contact' => $lang->txt('Contact'),
      'email' => $lang->txt('Email'),
      'name' => $lang->txt('Name'),
      'phone' => $lang->txt('Phone'),
  );

  my $client=setClient($Data->{'clientValues'});
  my %tempClientValues = getClient($client);
  my $currentname='';
  my @rowdata = ();
  my $statement =qq[
    SELECT 
      PN.intEntityID AS PNintEntityID, 
      CN.strLocalName, 
      CN.strContact, 
      CN.strPhone, 
      CN.strEmail, 
      CN.intEntityID AS CNintEntityID, 
      CN.intEntityLevel AS CNintEntityLevel, 
      PN.strLocalName AS PNName, 
      CN.strStatus
    FROM tblEntity AS PN 
      LEFT JOIN tblEntityLinks ON PN.intEntityID=tblEntityLinks.intParentEntityID 
      JOIN tblEntity as CN ON CN.intEntityID=tblEntityLinks.intChildEntityID
    WHERE PN.intEntityID = ?
      AND CN.strStatus <> 'DELETED'
      AND CN.intEntityLevel = $Defs::LEVEL_CLUB
      AND CN.intDataAccess>$Defs::DATA_ACCESS_NONE
    ORDER BY CN.strLocalName
  ];
  my $query = $db->prepare($statement);
  $query->execute($entityID);
  my $results=0;
  while (my $dref = $query->fetchrow_hashref) {
    $results=1;
    $tempClientValues{currentLevel} = $dref->{CNintEntityLevel};
    setClientValue(\%tempClientValues, $dref->{CNintEntityLevel}, $dref->{CNintEntityID});
    my $tempClient = setClient(\%tempClientValues);
    push @rowdata, {
      id => $dref->{'CNintEntityID'} || 0,
      strName => $dref->{'strLocalName'} || '',
      SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=C_HOME",
      strContact => $dref->{'strContact'} || '',
      strPhone => $dref->{'strPhone'} || '',
      strEmail => $dref->{'strEmail'} || '',
      strStatus => $dref->{'strStatus'} || '',
      strStatusText => $Data->{'lang'}->txt($Defs::entityStatus{$dref->{'strStatus'}} || ''),
    };
  }
  $query->finish;

  my $list_instruction= $Data->{'SystemConfig'}{"ListInstruction_Club"} 
        ? qq[<div class="listinstruction">$Data->{'SystemConfig'}{"ListInstruction_Club"}</div>] 
        : '';
  $list_instruction=eval($list_instruction) if $list_instruction;

  my @headers = (
    {
      type => 'Selector',
      field => 'SelectLink',
    },
    {
      name =>   $Data->{'lang'}->txt('Name'),
      field =>  'strName',
    },
    {
      name =>   $Data->{'lang'}->txt('Contact'),
      field =>  'strContact',
    },
    {
      name =>   $Data->{'lang'}->txt('Phone'),
      field =>  'strPhone',
      width => 50,   
    },
    {
      name =>   $Data->{'lang'}->txt('Email'),
      field =>  'strEmail',
    },
    {
        name   => $Data->{'lang'}->txt('Status'),
        field  => 'strStatusText',
        width  => 30,
    },

  );
  my $filterfields = [
    {
      field => 'strName',
      elementID => 'id_textfilterfield',
      type => 'regex',
    },
    {
      field => 'strStatus',
      elementID => 'dd_actstatus',
      allvalue => 'ALL',
    }
  ];
  my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@rowdata,
    filters => $filterfields,
    gridid => 'grid',
    width => '99%',
  );
  my $rectype_options=show_recordtypes(
        $Data,
        $Data->{'lang'}->txt('Name'),
        '',
        \%Defs::entityStatus,
        { 'ALL' => $Data->{'lang'}->txt('All'), },
  ) || '';

  $resultHTML = qq[ 
      <div style="width:99%;">$rectype_options</div>
    $list_instruction
    $grid
  ];

  my $obj = getInstanceOf($Data, 'entity', $entityID);
  if($obj)   {
      $currentname = $obj->getValue('strLocalName') || '';
  }
  my $title=$Data->{'SystemConfig'}{"PageTitle_List_".$Defs::LEVEL_CLUB} 
    || "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB.'_P'} in $currentname"; ###needs translation ->  WHAT in WHAT? 

  my $addlink='';
  {
      $addlink=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=C_DTA">].$Data->{'lang'}->txt('Add').qq[</a></span>] if(!$Data->{'ReadOnlyLogin'});

  }

  my $modoptions=qq[<div class="changeoptions">$addlink</div>];
  $title=$modoptions.$title;
  
  return ($resultHTML,$title);
}
1;
