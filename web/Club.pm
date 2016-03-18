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
use PersonLanguages;

use ClubFlow;
use ListAuditLog;
use Flow_DisplayFields;
use EntityFieldsSetup;
use FieldLabels;

sub handleClub  {
  my ($action, $Data, $parentID, $clubID, $typeID)=@_;

  my $resultHTML='';
  my $clubName=
  my $title='';
  $typeID=$Defs::LEVEL_CLUB if $typeID==$Defs::LEVEL_NONE;
  if ($action =~/^C_DTA/) {
        ($resultHTML,$title) = ClubFlow::handleClubFlow($action, $Data);
  }
  elsif ($action =~/^C_DT/) {
    #Club Details
    ($resultHTML,$title)=club_details($action, $Data, $clubID);
  }
   elsif ($action =~/^C_VW/) {
     #Club Details
     ($resultHTML,$title)=view_pending_club_details($action, $Data, $clubID);
   }
  elsif ($action =~/C_CFG_/) {
    #Club Configuration
  }
  elsif ($action =~/^C_HISTLOG/) {
        ($resultHTML,$title) = listEntityAuditLog($Data, $clubID);
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

 sub view_pending_club_details {
     my ($action, $Data, $clubID)=@_;
     my $client = $Data->{'client'};
     my $entityObj = new EntityObj(db => $Data->{'db'}, ID => $clubID, cache => $Data->{'cache'});
     $entityObj->load();
     my $values = {};
     my $fields = EntityEdit::getFieldNames();
     if($entityObj->ID())    {
         for my $f (@{$fields}) {
             $values->{$f} = $entityObj->getValue($f);
         }
     }
     my $body;
     my $permissionType = 'Entity';
     my $fieldset = undef;
     $permissionType = 'Club';
     my @sections = ('core', 'contactdetails','roledetails');
        
     $fieldset = clubFieldsSetup($Data, $values);
        for my $section (@sections) {
            my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$section}, $permissionType,);
            my $obj = new Flow_DisplayFields(
              Data => $Data,
              Lang => $Data->{'lang'},
              SystemConfig => $Data->{'SystemConfig'},
              Fields => $fieldset->{$section},
            );
            my ($output, undef, $headJS, undef) = $obj->build($permissions,'display',1);
              $body .= qq[
                    $output
            ];
        }
        $body = qq[ <div class="col-md-12">$body</div>];

        my $pageHeading = $entityObj->name();
        return ($body, $pageHeading);
 }
sub club_details  {
  my ($action, $Data, $clubID)=@_;


  my $field=loadClubDetails($Data->{'db'}, $clubID,$Data->{'clientValues'}{'assocID'}) || ();
  my $client=setClient($Data->{'clientValues'}) || '';

  my $allowedit =( ($field->{strStatus} eq 'ACTIVE' ? 1 : 0) || ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 ) );
  #my $allowedit =($field->{strStatus} eq 'ACTIVE' ? 1 : 0);
  my $allowadd = $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ZONE ? 1 : 0;

    $Data->{'ReadOnlyLogin'} ? $allowedit = 0 : undef;

    my $option='display';
      
   $option='edit' if $action eq 'C_DTE' and allowedAction($Data, 'c_e') && $allowedit;
   $option='add' if $action eq 'C_DTA' and allowedAction($Data, 'c_a')  && $allowadd;
   $clubID=0 if $option eq 'add';

  my $club_chars = ''; #getClubCharacteristicsBlock($Data, $clubID) || '';

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

  #################Limited List of Country Per MA ############################
    my $isocountries = getISOCountriesHash();
    my %countriesonly = ();
    my %Mcountriesonly = ();

    my @limitCountriesArr = ();
    if($Data->{'RegoForm'} && $Data->{'SystemConfig'}{'AllowedRegoCountries'}){
    	@limitCountriesArr = split(/\|/, $Data->{'SystemConfig'}{'AllowedRegoCountries'} );
    }

    while(my($k,$c) = each(%{$isocountries})){
    	$countriesonly{$k} = $c;
    	if(@limitCountriesArr){
    		next if(grep(/^$k/, @limitCountriesArr));
    	}
    	$Mcountriesonly{$c} = $c;
    }
    #################################################################

    my $dissDateReadOnly = 0;

    if ($Data->{'SystemConfig'}{'Entity_EditDissolutionDateMinLevel'} && $Data->{'SystemConfig'}{'Entity_EditDissolutionDateMinLevel'} < $Data->{'clientValues'}{'authLevel'}){
      $dissDateReadOnly = 1; ### Allow us to set custom Level that can edit. ###
    }
    elsif ($Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL){
      $dissDateReadOnly = 1;
    }

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
                    jQuery('#l_row_strLatinName').hide();
                    jQuery('#l_row_strLatinShortName').hide();
                    jQuery('#l_intLocalLanguage').change(function()   {
                        var lang = parseInt(jQuery('#l_intLocalLanguage').val());
                        nonlatinvals = [$vals];
                        if(nonlatinvals.indexOf(lang) !== -1 )  {
                            jQuery('#l_row_strLatinName').show();
                            jQuery('#l_row_strLatinShortName').show();
                        }
                        else    {
                            jQuery('#l_row_strLatinName').hide();
                            jQuery('#l_row_strLatinShortName').hide();
                        }
                    });
                });
            </script> 

        ];
    }
    my $countries = Countries::getISOCountriesHash();
  my %FieldDefinitions=(
    fields=>  {
      strFIFAID => {
        label => $Data->{'lang'}->txt('FIFA ID'),
        value => $field->{strFIFAID} || ' ',
        type  => 'text',
        size  => '40',
        maxsize => '150',

      },
      strLocalName => {
        label => $Data->{'lang'}->txt('Organisation Name'),
        value => $field->{strLocalName},
        type  => 'text',
        size  => '40',
        maxsize => '150',
        compulsory => 1,
      },
      strLocalShortName => {
        label => $Data->{'lang'}->txt('Organisation Short Name'),
        value => $field->{strLocalShortName},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },
      strLatinName => {
        label => $Data->{'SystemConfig'}{'entity_strLatinNames'} ? $Data->{'lang'}->txt('International Organisation Name') : '',
        value => $field->{strLatinName},
        type  => 'text',
        size  => '40',
        maxsize => '150',
      },
      strLatinShortName => {
        label => $Data->{'SystemConfig'}{'entity_strLatinNames'} ? $Data->{'lang'}->txt('International Organisation Short Name') : '',
        value => $field->{strLatinShortName},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },
      strMAID => {
      	label => $Data->{'lang'}->txt('MA Organisation ID'),
      	value => $field->{strMAID},
      	type => 'text',
      	size => '30',
      	maxsize => '100',
        compulsory => 1,
      },
      dtFrom => {
        label       => $Data->{'lang'}->txt('Organisation Foundation Date'),
        value       => $field->{dtFrom},
        type        => 'date',
        datetype    => 'dropdown',
        format      => 'dd/mm/yyyy',
        validate    => 'DATE',
        compulsory => 1,
      },
      dtTo => {
        label       => $Data->{'lang'}->txt('Organisation Dissolution Date'),
        value       => $field->{dtTo},
        type        => 'date',
        datetype    => 'dropdown',
        format      => 'dd/mm/yyyy',
        validate    => 'DATE',
        readonly    => $dissDateReadOnly,
      },
      strGender => {
          label => $Data->{'lang'}->txt("Gender"),
          value => $field->{strGender},
          type  => 'lookup',
          options => \%Defs::genderEntityInfo,
          firstoption => [ '', $Data->{'lang'}->txt('Select Type') ],
      },
      strDiscipline => {
      	 label => $Data->{'lang'}->txt("Sport"),
      	 value => $field->{strDiscipline},
         type  => 'lookup',
         options => \%Defs::entitySportType,
         firstoption => [ '', $Data->{'lang'}->txt('Select Type') ],
      },
      intLegalTypeID => {
        label => $Data->{'lang'}->txt("Type of Legal Entity"),
        value => $field->{intLegalTypeID},
        type => 'lookup',
        options => \%legalTypeOptions,
        firstoption => [ '', $Data->{'lang'}->txt('Select Type') ],
        readonly =>($Data->{'clientValues'}{authLevel} < $Defs::LEVEL_NATIONAL),       
     },
     strLegalID => {
        label =>$Data->{'lang'}->txt( "Legal Type Identification Number"),
        value => $field->{strLegalID},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        compulsory => 1,
      },
      strEntityType => {
        label => $Data->{'lang'}->txt("Entity Type"),
        value => $field->{strEntityType},
        type => 'lookup',
        options => \%Defs::entityType,
        firstoption => [ '', $Data->{'lang'}->txt('Select Type') ],
        compulsory => 1,
     },
      strStatus => {
          label => $Data->{'lang'}->txt('Status'),
          value => $field->{strStatus},
          type => 'lookup',
          options => \%Defs::entityStatus,
          readonly => $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 0 : 1,
          noadd         => 1,
     },
      strContact => {
        label => $Data->{'lang'}->txt('Contact Person'),
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
        
      strAddress => {
        label => $Data->{'lang'}->txt('Address 1'),
        value => $field->{strAddress},
        type  => 'text',
        size  => '40',
        maxsize => '50',
        compulsory => 1,
      },
    strAddress2=> {
        label => $Data->{'lang'}->txt('Address 2'),
        value => $field->{strAddress2},
        type  => 'text',
        size  => '40',
        maxsize => '50',
        compulsory => 1,
      },
      strContactISOCountry => {
          label       => $Data->{'lang'}->txt('Country of Address'),
          value       => $field->{strContactISOCountry} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
          type        => 'lookup',
          options     => $countries,
          firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
        compulsory => 1,
      },
      strContactCity=> {
        label => $Data->{'lang'}->txt('City'),
        value => $field->{strContactCity},
        type  => 'text',
        size  => '40',
        maxsize => '50',
        compulsory => 1,
      },

      strCity=> {
        label => $Data->{'lang'}->txt('City'),
        value => $field->{strCity},
        type  => 'text',
        size  => '40',
        maxsize => '50',
        compulsory => 1,
      },
      strState => {
        label => $Data->{'lang'}->txt('State of Organisation'),
        value => $field->{strState},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        compulsory => 1,
      },
      strTown => {
        label => $Data->{'lang'}->txt('Town of Organisation'),
        value => $field->{strTown},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        compulsory => 1,
      },
      strRegion => {
        label => $Data->{'lang'}->txt('Region of Organisation'),
        value => $field->{strRegion},
        type  => 'text',
        size  => '30',
        maxsize => '50',
      },
      strISOCountry => {
          label       => $Data->{'lang'}->txt('Country of Organisation'),
          value       => $field->{strISOCountry} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
          type        => 'lookup',
          options     => $countries,
          firstoption => [ '', $Data->{'lang'}->txt('Select Country') ],
        compulsory => 1,
      },
      intLocalLanguage => {
          label       => $Data->{'lang'}->txt('Language the name is written in'),
          type        => 'lookup',
          value       => $field->{intLocalLanguage},
          options     => \%languageOptions,
          firstoption => [ '', $Data->{'lang'}->txt('Select Language') ],
          compulsory => 1,
          posttext => $nonlatinscript,
      },
      strPostalCode => {
        label => $Data->{'lang'}->txt('Postcode'),
        value => $field->{strPostalCode},
        type  => 'text',
        size  => '15',
        maxsize => '15',
      },
      strPhone => {
        label => $Data->{'lang'}->txt('Contact Number'),
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
        label => $Data->{'lang'}->txt('Contact Email'),
        value => $field->{strEmail},
        type  => 'text',
        size  => '35',
        maxsize => '250',
        validate => 'EMAIL',
      },
      strMANotes => {
      	label => $Data->{'lang'}->txt('MA Comment'),
      	value => $field->{strMANotes},
        type => 'textarea',
        rows => '10',
        cols => '40',
        readonly =>($Data->{'clientValues'}{authLevel} < $Defs::LEVEL_NATIONAL),
      },
      strAssocNature => {
      	label => $Data->{'lang'}->txt('Association Nature'),
      	value => $field->{strAssocNature},
        type => 'text',
        size => 40,
        compulsory => 1,
      },
      strWebURL => {
        label => $Data->{'lang'}->txt('Web'),
        value => $field->{strWebURL},
        type  => 'text',
        size  => '35',
        maxsize => '250',
      },
      strShortNotes => {
        label => $Data->{'lang'}->txt('Notes'),
        value => $field->{strShortNotes},
        type => 'textarea',
        rows => '10',
        cols => '40',
      },
      intNotifications => {
        label => $Data->{'lang'}->txt("Notifications"),
        value => $field->{intNotifications},
        type => 'lookup',
        options => \%Defs::notificationToggle,
      },
      SP1  => {
        type =>'_SPACE_',
      },
      clubcharacteristics => {
        label => $Data->{'lang'}->txt('Which of the following are appropriate to your club?'),
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
        strCity
        strRegion
        strState
        strISOCountry
        strMAID
        dtFrom
        dtTo
        strGender
        strDiscipline
        strOrganisationLevel
        strEntityType
        strStatus
        strAssocNature
        intLegalTypeID
        strLegalID
        intLocalLanguage
        strAddress
        strAddress2
        strContactCity
        strContactISOCountry
        strPostalCode
        strWebURL
        strEmail
        strPhone
        strContact
        strFax
        strMANotes
        clubcharacteristics
        intNotifications
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
      clubID => $clubID
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
($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, $clubperms, $option, 0,$Data->{'db'});
  my $title=$field->{'strLocalName'} || '';
  my $scMenu = '';#(allowedAction($Data, 'c_e')) ? getServicesContactsMenu($Data, $Defs::LEVEL_CLUB, $clubID, $Defs::SC_MENU_SHORT, $Defs::SC_MENU_CURRENT_OPTION_DETAILS) : '';
  my $logodisplay = '';
  my $editlink = (allowedAction($Data, 'c_e')) ? 1 : 0;
  #( ($field->{strStatus} eq 'ACTIVE' ? 1 : 0) || ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 ) );#
  if($option eq 'display')  {
#    $resultHTML .= showContacts($Data,0, $editlink);
    my $chgoptions='';
    $chgoptions.=qq[<span class = "btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=C_DTE&clubID=$clubID">Edit $Data->{'LevelNames'}{$Defs::LEVEL_CLUB}</a></span>] if ( ($field->{strStatus} eq 'ACTIVE' ? 1 : 0) || ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 ) ); #allowedAction($Data, 'c_e');
    #
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
     strMAID,
     dtFrom,
     dtTo,
     strLocalName,
     intLegalTypeID,
     strLocalShortName,
     strGender,
     strDiscipline,
     strOrganisationLevel
     strLocalFacilityName,
     strLatinName,
     strLatinShortName,
     strLatinFacilityName,
     strISOCountry,
     strContactISOCountry,
     strContact,
     strContactCity,
     intLocalLanguage,
     strRegion,
     strPostalCode,
     strTown,
     strState,
     strCity,
     strAddress,
     strAddress2,
     strWebURL,
     strEmail,
     strPhone,
     strFax,
     strAssocNature,
     strMANotes,
     dtAdded,
     strShortNotes,
     tTimeStamp,
     strLegalID,
     intNotifications
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
        INSERT IGNORE INTO tblEntityLinks (intParentEntityID, intChildEntityID)
        VALUES (?,?)
      ];
      my $query = $db->prepare($st);
      $query->execute($entityID, $id);
      $query->finish();

    ### A call TO createTempEntityStructure FROM EntityStructure   ###
    createTempEntityStructure($Data, $Data->{'Realm'}, 0);
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

    my @req_docs=();
     foreach my $doc_ref (@{$required_club_docs}){
        next if(!$doc_ref);
        my $parentCheck= authstring($doc_ref->{'intFileID'});
        $doc_ref->{'chk'} = $parentCheck;
        push @req_docs,$doc_ref;
    }

     #what is origin level,is the level for this entity or the level of the person logged in???

    my %PageData = (
        target => $Data->{'target'},
        documents => \@req_docs,
        Lang => $Data->{'lang'},
        client => $clm,
  );
  my $clubdocs;
  $clubdocs = runTemplate($Data, \%PageData, 'club/required_docs.templ') || '';

	### Change strStatus to DE-REGISTERED When Dissolution date is less than current date ###
	resetStatus($cv{'clubID'},$db);

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
  if($id)    {
    $Data->{'cache'}->delete('swm','EntityObj-'.$id) if $Data->{'cache'};
  }


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
  ### Change strStatus to DE-REGISTERED When Dissolution date is less than current date ###
  resetStatus($clubID,$db);
}

sub resetStatus {
  my($id,$db)=@_;
  my $st=qq[
    UPDATE tblEntity SET strStatus = \"DE-REGISTERED\" WHERE intEntityID = ? and date(dtTo) <= date(NOW())
  ];
  my $query = $db->prepare($st);
  $query->execute($id);
  $query->finish;
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
      AND CN.strStatus <> 'INPROGRESS'
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
      SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=EE_D",
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
      name =>   $Data->{'lang'}->txt('Name'),
      field =>  'strName',
      defaultShow => 1,
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
    {
      type => 'Selector',
      field => 'SelectLink',
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
    OFFfilters => $filterfields,
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
  $rectype_options=''; #OFF FOR NOW

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
    || $Data->{'lang'}->txt("Clubs in [_1]",$currentname); ###needs translation ->  WHAT in WHAT?

  my $addlink='';
  #{
  #    $addlink=qq[<span class = "btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=C_DTA">].$Data->{'lang'}->txt('Add').qq[</a></span>] if(!$Data->{'ReadOnlyLogin'});
  # }

  my $modoptions=qq[<div class="changeoptions">$addlink</div>];
  $title=$modoptions.$title;

  return ($resultHTML,$title);
}

sub getLegalTypeName {
	my ($Data, $legalTypeID) = @_;

	my $query = qq[SELECT strLegalType FROm tblLegalType WHERE intLegalTypeID = ?];
	
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($legalTypeID);
	my $dref = $sth->fetchrow_hashref();
	return $dref->{'strLegalType'};
}
1;
