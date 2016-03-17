package Venues;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleVenues getVenues loadVenueDetails );
@EXPORT_OK=qw(handleVenues getVenues loadVenueDetails );

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use CGI qw(unescape param);
use FormHelpers;
use GridDisplay;
use Log;
use EntityStructure;
use WorkFlow;

use RecordTypeFilter;
use RuleMatrix;
use Countries;

use RegistrationItem;
use TTTemplate;
use EntityDocuments;
use Data::Dumper;

use EntityFields;
use FacilityFlow;
use PersonLanguages;

use FlashMessage;

sub handleVenues    {
    my ($action, $Data, $parentID, $typeID)=@_;

    my $venueID= param('venueID') || 0;
    warn "HANDLER venue id " . $venueID;
    my $resultHTML='';
    my $title='';
    if ($action =~/^VENUE_DTA/) {
        #($resultHTML,$title)=venue_details($action, $Data, $venueID);
        ($resultHTML,$title) = handleFacilityFlow($action, $Data);
    }
    elsif($action =~/^VENUE_DTE/){
        #still to be implemented
        #($resultHTML,$title)=venue_details($action, $Data, $venueID);
    }
    elsif ($action =~/^VENUE_L/) {
        #List Venues
        my $tempResultHTML = '';
        ($tempResultHTML,$title)=listVenues($Data);
        $resultHTML .= $tempResultHTML;
    }
    ##### FOR UPLOADING DOCUMENT FOR ADDING VENUES #######
    elsif($action =~ /^VENUE_DOCS/){
    	($resultHTML, $title) = handle_entity_documents($action, $Data, $venueID, $typeID, $Defs::DOC_FOR_VENUES);  
    }    
    #####################################################    
    elsif($action =~ /^VENUE_Flist/) {
        ($resultHTML, $title) = list_venue_fields($action, $Data, $venueID);
    }
    elsif($action =~ /^VENUE_Fupdate/){
        ($resultHTML, $title) = update_venue_fields($action, $Data, $venueID);
    }
    elsif($action =~ /^VENUE_FPA/){
        ($resultHTML, $title) = pre_add_venue_fields($action, $Data, $venueID, undef);
    }
    elsif($action =~ /^VENUE_Fadd/ or $action =~ /^VENUE_Fprocadd/){
        ($resultHTML, $title) = add_venue_fields($action, $Data, $venueID);
    }
    elsif($action =~ /^VENUE_FPD/){
        ($resultHTML, $title) = delete_venue_fields($action, $Data, $venueID);
    }
    elsif($action =~ /^VENUE_Fprocdel/){
        ($resultHTML, $title) = proc_delete_venue_fields($action, $Data, $venueID);
    }
    return ($resultHTML,$title);
}

sub venue_details   {
    my ($action, $Data, $venueID)=@_;

    return '' if ($venueID and !venueAllowed($Data, $venueID));
    my $option='display';
    my $field=loadVenueDetails($Data->{'db'}, $venueID) || ();
    
    #my $allowedit =( ($field->{strStatus} eq 'ACTIVE' ? 1 : 0) || ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 ) );
    my $allowedit =( ($field->{strStatus} eq 'ACTIVE' ? 1 : 0) || ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_CLUB ? 1 : 0 ) );
    $Data->{'ReadOnlyLogin'} ? $allowedit = 0 : undef;
   
    $option='edit' if $action eq 'VENUE_DTE' && $allowedit;
    $option='add' if $action eq 'VENUE_DTA' && $allowedit;
    
    #$option='edit' if $action eq 'VENUE_DTE' && !$Data->{'ReadOnlyLogin'};# and allowedAction($Data, 'venue_e');
    #$option='add' if $action eq 'VENUE_DTA' && !$Data->{'ReadOnlyLogin'}; # and allowedAction($Data, 'venue_a');
    $venueID=0 if $option eq 'add';
    
    
    my $intRealmID = $Data->{'Realm'} ? $Data->{'Realm'} : 0;
    my $client=setClient($Data->{'clientValues'}) || '';
    
    my $authID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'});
    my $paymentRequired = 0;
    if ($option eq 'add')   {
        my %Reg=();
        $Reg{'registrationNature'}='NEW';
        my $matrix_ref = getRuleMatrix($Data, $Data->{'clientValues'}{'authLevel'}, getLastEntityLevel($Data->{'clientValues'}), $Defs::LEVEL_VENUE, '', 'ENTITY', \%Reg);
        $paymentRequired = $matrix_ref->{'intPaymentRequired'} || 0;
    }
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
        
    #################################################################
    my %FieldDefinitions = (
    fields=>  {
      strFIFAID => {
        label => 'FIFA ID',
        value => $field->{strFIFAID},
        type  => 'text',
        size  => '40',
        maxsize => '150',
        readonly =>1,
        sectionname => 'details',
      },
      strLocalName => {
        label => 'Venue Name',
        value => $field->{strLocalName},
        type  => 'text',
        size  => '40',
        maxsize => '150',
        sectionname => 'details',
        compulsory => 1,
      },
      strLocalShortName => {
        label => 'Venue Short Name',
        value => $field->{strLocalShortName},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
        compulsory => 1,
      },
       intLocalLanguage => {
          label       => 'Language the name is written in',
          type        => 'lookup',
          value       => $field->{intLocalLanguage} || $Data->{'SystemConfig'}{'Default_NameLanguage'},
          options     => \%languageOptions,
          firstoption => [ '', 'Select Language' ],
          compulsory => 1,
          posttext => $nonlatinscript,
      },      
      strLatinName => {
        label => $Data->{'SystemConfig'}{'entity_strLatinNames'} ? 'International Venue Name' : '',
        value => $field->{strLatinName},
        type  => 'text',
        size  => '40',
        maxsize => '150',
        sectionname => 'details',
      },
      strLatinShortName => {
        label => $Data->{'SystemConfig'}{'entity_strLatinNames'} ? 'International Venue Short Name' : '',
        value => $field->{strLatinShortName},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
      },
      
      strStatus => {
          label => 'Status',
    	  value => $field->{strStatus} || 'ACTIVE',
    	  type => 'lookup',  
    	  options => \%Defs::entityStatus,
    	  sectionname => 'details',
    	  readonly => $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 0 : 1,
          noadd=>1,
      },
      
      strAddress => {
        label => 'Address 1',
        value => $field->{strAddress},
        type  => 'text',
        size  => '40',
        maxsize => '50',
        sectionname => 'details',
      },
      strAddress2 => {
        label => 'Address 2',
        value => $field->{strAddress2},
        type  => 'text',
        size  => '40',
        maxsize => '50',
        sectionname => 'details',
      },
 
      strContactCity=> {
        label => 'City of Address',
        value => $field->{strContactCity},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
      },
      strCity=> {
        label => 'City',
        value => $field->{strCity},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
      },
      strState => {
        label => 'State',
        value => $field->{strState},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
      },
      strTown => {
        label => 'Town',
        value => $field->{strTown},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
      },
      strRegion => {
        label => 'Region',
        value => $field->{strRegion},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
      },      
      strISOCountry => {
        label => 'Country',
        value =>  $field->{strISOCountry} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
        type  => 'lookup',
        options     => \%Mcountriesonly,
        firstoption => [ '', 'Select Country' ],
        sectionname => 'details',
      },
      strContactISOCountry => {
        label => 'Country of Address',
        value =>  $field->{strContactISOCountry} ||  $Data->{'SystemConfig'}{'DefaultCountry'} || '',
        type  => 'lookup',
        options     => \%Mcountriesonly,
        firstoption => [ '', 'Select Country' ],
        sectionname => 'details',
      },
      strPostalCode => {
        label => 'Postcode',
        value => $field->{strPostalCode},
        type  => 'text',
        size  => '15',
        maxsize => '15',
        sectionname => 'details',
      },
      strPhone => {
        label => 'Contact Phone',
        value => $field->{strPhone},
        type  => 'text',
        size  => '20',
        maxsize => '20',
        sectionname => 'details',
      },
      strFax => {
        label => 'Fax',
        value => $field->{strFax},
        type  => 'text',
        size  => '20',
        maxsize => '20',
        sectionname => 'details',
      },
      strEmail => {
        label => 'Contact Email',
        value => $field->{strEmail},
        type  => 'text',
        size  => '35',
        maxsize => '250',
        validate => 'EMAIL',
        sectionname => 'details',
      },
      strWebURL => {
        label => 'Web Address',
        value => $field->{strWebURL},
        type  => 'text',
        size  => '35',
        maxsize => '250',
        sectionname => 'details',
      },
      strContact=> {
        label => 'Contact Person',
        value => $field->{strContact},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
      },      
      strDescription => {
        label => 'Description',
        value => $field->{strDescription},
        type => 'textarea',
        rows => '10',
        cols => '40',
        sectionname => 'details',
      },
        dtFrom => {
        label       => 'Foundation Date',
        value       => $field->{dtFrom},
        type        => 'date',
        datetype    => 'dropdown',
        format      => 'dd/mm/yyyy',
        validate    => 'DATE',
      },
      dtTo => {
        label       => 'Dissolution Date',
        value       => $field->{dtTo},
        type        => 'date',
        datetype    => 'dropdown',
        format      => 'dd/mm/yyyy',
        validate    => 'DATE',
      },
      SP1  => {
        type =>'_SPACE_',
        sectionname => 'details',
      },
      intCapacity => {
        label => 'Capacity',
        value => $field->{intCapacity},
        type  => 'text',
        size  => '10',
        maxsize => '10',
        validate => 'NUMBER',
        sectionname => 'details',
      },
      intCoveredSeats=> {
        label => 'Covered Seats',
        value => $field->{intCoveredSeats},
        type  => 'text',
        size  => '10',
        maxsize => '10',
        validate => 'NUMBER',
        sectionname => 'details',
      },
      intUncoveredSeats=> {
        label => 'Uncovered Seats',
        value => $field->{intUncoveredSeats},
        type  => 'text',
        size  => '10',
        maxsize => '10',
        sectionname => 'details',
        validate => 'NUMBER',
      },
      intCoveredStandingPlaces => {
        label => 'Covered Standing Places',
        value => $field->{intCoveredStandingPlaces},
        type  => 'text',
        size  => '10',
        maxsize => '10',
        validate => 'NUMBER',
        sectionname => 'details',
      },
      intUncoveredStandingPlaces => {
        label => 'Uncovered Standing Places',
        value => $field->{intUncoveredStandingPlaces},
        type  => 'text',
        size  => '10',
        maxsize => '10',
        validate => 'NUMBER',
        sectionname => 'details',
      },
      intLightCapacity=> {
        label => 'Light Capacity',
        value => $field->{intLightCapacity},
        type  => 'text',
        size  => '10',
        maxsize => '10',
        validate => 'NUMBER',
        sectionname => 'details',
      },
      strGroundNature => {
        label => 'Type of Field',
        value => $field->{strGroundNature},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
      },
      strDiscipline => {
        label => 'Discipline',
        value => $field->{strDiscipline},
        type  => 'text',
        size  => '30',
        maxsize => '50',
        sectionname => 'details',
      },
      strMapRef => {
        label       => "Map Reference (Printed Map)",
        value       => $field->{strMapRef},
        type        => 'text',
        size        => '10',
        sectionname => 'details',
      },
      intMapNumber => {
        label       => "Map Number (Printed Map)",
        value       => $field->{intMapNumber},
        type        => 'text',
        size        => '10',
        sectionname => 'details',
      },
      mapdesc => {
        label => 'map desc',
        type  => 'textvalue',
        value => '<p>Enter Latitude and Longtitude in the boxes below or drag the map marker to the correct location.</p>',
        sectionname    => 'mapping',
        SkipProcessing => 1,
      },
      mapblock => {
        label    => "Map",
        value    => '',
        posttext => ' <div id="map_canvas" style="width:450px;height:450px;border:1px solid #888;"></div>',
        type           => 'hidden',
        size           => '40',
        sectionname    => 'mapping',
        SkipProcessing => 1,
      },
      dblLat => {
        label       => "Latitude",
        value       => $field->{dblLat},
        type        => 'text',
        size        => '20',
        sectionname => 'mapping',
      },
      dblLong => {
        label       => "Longtitude",
        value       => $field->{dblLong},
        type        => 'text',
        size        => '20',
        sectionname => 'mapping',
      },
    },
    order => [qw(
        strFIFAID
        strLocalName
        strLocalShortName
        intLocalLanguage
        strLatinName
        strLatinShortName
        strCity
        strRegion
        strISOCountry
        strStatus
        dtFrom
        dtTo
        strAddress
        strAddress2
        strContactCity
        strState
        strContactISOCountry
        strPostalCode
        strWebURL
        strEmail
        strPhone
        strContact
        strFax
        strMapRef
        intMapNumber
        mapdesc
        dblLat
        dblLong
        mapblock
        strDescription
    )],
    sections => [ 
        [ 'details', "Venue Details" ], 
        [ 'mapping', "Online Mapping" ], 
    ],
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
          WHERE intEntityID=$venueID
              AND intRealmID= $intRealmID
      ],
      addSQL => qq[
          INSERT INTO tblEntity (
              intRealmID, 
              intEntityLevel, 
              intCreatedByEntityID,
              intPaymentRequired,
              strStatus,
              intDataAccess,
              --FIELDS-- 
          )
          VALUES (
              $intRealmID, 
              $Defs::LEVEL_VENUE, 
              $authID,
              $paymentRequired,
              'PENDING',
              $Defs::DATA_ACCESS_FULL,
              --VAL-- 
          )
      ],
      auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Venue'
      ],
      auditEditParams => [
        $venueID,
        $Data,
        'Update',
        'Venue'
      ],

      afteraddFunction => \&postVenueAdd,
      afteraddParams => [$option,$Data,$Data->{'db'}],
      afterupdateFunction => \&postVenueUpdate,
      afterupdateParams => [$option,$Data,$Data->{'db'}, $venueID],

      LocaleMakeText => $Data->{'lang'},
    },
    carryfields =>  {
      client => $client,
      a=> $action,
      venueID=> $venueID,
    },
  );
    my $resultHTML='';
    ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, '',$Data->{'db'});
    my $title=qq[Venue- $field->{strLocalName}];

    my $chgoptions='';
    
    if($option eq 'display')  {
        # Edit Venue.
        $chgoptions.=qq[<span class = "btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=VENUE_DTE&amp;venueID=$venueID">].$Data->{'lang'}->txt('Edit Venue').qq[</a></span> ] if allowedAction($Data, 'venue_e');
    }
    elsif ($option eq 'edit') {
        # Delete Venue.
        my $venueObj = new EntityObj('db'=>$Data->{db},ID=>$venueID,realmID=>$intRealmID);
        
        $chgoptions.=qq[<span class = "btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=VENUE_FPA&amp;venueID=$venueID">Add Fields</a> ] if (!$Data->{'ReadOnlyLogin'});
        $chgoptions.=qq[<span class = "btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=VENUE_Flist&amp;venueID=$venueID">Edit Fields</a> ] if (!$Data->{'ReadOnlyLogin'});
        $chgoptions.=qq[<span class = "btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=VENUE_DEL&amp;venueID=$venueID" onclick="return confirm('Are you sure you want to delete this venue');">Delete Venue</a> ] if ($venueObj->canDelete() && !$Data->{'ReadOnlyLogin'});
    }
    
    $chgoptions=qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
    $title=$chgoptions.$title;
    
    $title="Add New Venue" if $option eq 'add';

    if($option ne 'display') {
        my $original_lat = $field->{'dblLat'} || '-25.901820984476252';
        my $original_long = $field->{'dblLong'} || '134.00135040279997';

        my $zoomstr = $field->{'dblLat'} ? "zoom : 15," : '';
        $resultHTML .= qq[
<script src="https://maps.google.com/maps/api/js?sensor=true" type="text/javascript"></script>
<script src="js/jquery.ui.map.full.min.js" type="text/javascript"></script>

<script type="text/javascript">
        jQuery(function() {
                var StartLatLng = new google.maps.LatLng($original_lat, $original_long);
                jQuery('#map_canvas').gmap({
                                    'center': StartLatLng, 
                                    'streetViewControl': false, 
                                    'panControl': false, 
                                    $zoomstr
                                    zoomControlOptions :  {style: google.maps.ZoomControlStyle.SMALL}
                                });
                                jQuery('#map_canvas').gmap('addMarker', {'position': StartLatLng, 'draggable': true, 'bounds': false}).dragend( function(event) {
                                    jQuery('#l_dblLat').val(event.latLng.lat());
                                    jQuery('#l_dblLong').val(event.latLng.lng());
                })
         
                    jQuery('#n_formID input').change(updateMapFromAddress);

                    function updateMapFromAddress   () {
                        if( jQuery('#orig_dblLat').val().length > 1 || jQuery('#orig_dblLong').val().length > 1)    {
                            // coords already set
                            return false;
                        } 

                        var address = jQuery("#l_strAddress1").val() + ' ' + jQuery("#l_strAddress2").val() + ' ' + jQuery("#l_strSuburb").val() + ' ' + jQuery("#l_strState").val() + ' ' + jQuery("#l_strCountry").val();
                      jQuery('#map_canvas').gmap('search', {'address': address}, function(results, status) {
                if ( status === 'OK' ) {
                                    var newpos = results[0].geometry.location;
                                    //jQuery('#map_canvas').gmap('get','map').setCenter(newpos);
                                    jQuery('#map_canvas').gmap('get','map').fitBounds(results[0].geometry.viewport);
                                    var marker = jQuery('#map_canvas').gmap('get', 'markers')[0];
                                    marker.setPosition(newpos);
                                    jQuery('#l_dblLat').val(newpos.lat());
                                    jQuery('#l_dblLong').val(newpos.lng());
                }
                                else {
                                    //alert("Geocode was not successful for the following reason: " + status);
                            }
            });
                    }
                    updateMapFromAddress(); // Run first time on load
        });
</script>
<input type = "hidden" value = "$field->{'dblLat'}" name = "orig_dblLat" id = "orig_dblLat">
<input type = "hidden" value = "$field->{'dblLong'}" name = "orig_dblLong" id = "orig_dblLong">
        ];
    }
    my $text = qq[<p style = "clear:both;"><a href="$Data->{'target'}?client=$client&amp;a=VENUE_L">Click here</a> to return to list of Venues</p>];
    $resultHTML = $text.$resultHTML.$text;

    return ($resultHTML,$title);
}

sub loadVenueDetails {
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
      strLocalShortName,
      strLocalFacilityName,
      strLatinName,
      strLatinShortName,
      strLatinFacilityName,
        intLocalLanguage,
      dtFrom,
      dtTo,
      strISOCountry,
      strContactISOCountry,
      strContact,
     strCity,
     strContactCity,
      strRegion,
      strPostalCode,
      strTown,
      strState,
      strAddress,
      strAddress2,
      strWebURL,
      strEmail,
      strPhone,
      strFax,
      dtAdded,
      tTimeStamp,
      intCapacity,
      intCoveredSeats,
      intUncoveredSeats,
      intCoveredStandingPlaces,
      intUncoveredStandingPlaces,
      intLightCapacity,
      strGroundNature,
      strDiscipline,
      strMapRef,
      intMapNumber,
      dblLat,
      dblLong,
      strDescription
    FROM tblEntity
    WHERE intEntityID = ?
        AND intEntityLevel = $Defs::LEVEL_VENUE
  ];
  my $query = $db->prepare($statement);
  $query->execute($id);
  my $field=$query->fetchrow_hashref();
  $query->finish;
                                                                                                        
  foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
  return $field;
}

sub listVenues  {
    my($Data) = @_;

    my $resultHTML = '';
    my $client = unescape($Data->{client});

    my %tempClientValues = getClient($client);

    my $entityID = getID($Data->{'clientValues'});

    my $statement =qq[
      SELECT 
        DISTINCT
        PN.intEntityID AS PNintEntityID, 
        CN.strLocalName, 
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
        AND CN.intEntityLevel = ?
        AND CN.intDataAccess>$Defs::DATA_ACCESS_NONE
      ORDER BY CN.strLocalName
    ];
    my $query = $Data->{'db'}->prepare($statement);
    $query->execute($entityID, $Defs::LEVEL_VENUE);
    my $results=0;
    my @rowdata = ();
    while (my $dref = $query->fetchrow_hashref) {
      $results=1;
      #$tempClientValues{currentLevel} = $dref->{CNintEntityLevel};
      #setClientValue(\%tempClientValues, $dref->{CNintEntityLevel}, $dref->{CNintEntityID});
      #my $tempClient = setClient(\%tempClientValues);
      push @rowdata, {
        id => $dref->{'CNintEntityID'} || 0,
        strLocalName => $dref->{'strLocalName'} || '',
        strStatus => $dref->{'strStatus'} || '',
        strStatusText => $Data->{'lang'}->txt($Defs::entityStatus{$dref->{'strStatus'}} || ''),
        SelectLink => "$Data->{'target'}?client=$client&amp;a=FE_D&amp;venueID=$dref->{'CNintEntityID'}",
      };
    }
    $query->finish;

    my $addlink='';
    my $title = $Data->{'lang'}->txt('Venues');
    #{
    #    my $tempClient = setClient(\%tempClientValues);
    #    $addlink=qq[<span class = "btn-inside-panels"><a href="$Data->{'target'}?client=$client&amp;a=VENUE_DTA">].$Data->{'lang'}->txt('Add').qq[</a></span>] if !$Data->{'ReadOnlyLogin'};
    #}

    my $modoptions=qq[<div class="changeoptions">$addlink</div>];
    $title=$modoptions.$title;
    my $rectype_options=show_recordtypes(
        $Data, 
        $Data->{'lang'}->txt('Name'),
        '',
        \%Defs::entityStatus,
        { 'ALL' => $Data->{'lang'}->txt('All'), },
        'ACTIVE',
    ) || '';

    my @headers = (
        {
            name  => $Data->{'lang'}->txt('Venue Name'),
            field => 'strLocalName',
            defaultShow => 1,
        },
        {
            name   => $Data->{'lang'}->txt('Status'),
            field  => 'strStatusText',
            width  => 30,
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
        #filters => $filterfields,
    );

    $resultHTML = qq[
            $grid
    ];

    return ($resultHTML,$title);
}

sub postVenueUpdate {
  my($id,$params,$action,$Data,$db, $entityID)=@_;
  return undef if !$db;
  $entityID ||= $id || 0;

  $Data->{'cache'}->delete('swm',"VenueObj-$entityID") if $Data->{'cache'};

}

sub postVenueAdd {
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
      $Data->{'db'}=$db;
      createTempEntityStructure($Data, $Data->{'Realm'}, $id); 
        #my $rc = addTasks($Data,$entityID, 0,0);
      addWorkFlowTasks($Data, 'ENTITY', 'NEW', $Data->{'clientValues'}{'authLevel'}, $id,0,0, 0);
    }
      ### A call TO createTempEntityStructure FROM EntityStructure   ###
      ### End call to createTempEntityStructure FROM EntityStructure###
    {
      my $cl=setClient($Data->{'clientValues'}) || '';
      my %cv=getClient($cl);      
      $cv{'venueID'}=$id;
      $cv{'currentLevel'} = $Defs::LEVEL_VENUE;
      my $clm=setClient(\%cv);
      ######################## For Adding Venue Documents ################################
      my $originLevel = $Data->{'clientValues'}{'authLevel'} || 0;
      my $clientValues = $Data->{'clientValues'};
      my $entityRegisteringForLevel = getLastEntityLevel($clientValues) || 0;
      my $entityID = getID($Data->{'clientValues'});    
      my $entityIDD = getLastEntityID($clientValues);     
      
     
      my $required_venue_docs = getRegistrationItems(
        $Data,
        'ENTITY',
        'DOCUMENT',
        $originLevel,
        'NEW',
        $id,
        $entityRegisteringForLevel,
        0,
        undef,
     );
      #what is origin level,is the level for this entity or the level of the person logged in???
         my @req_docs=();
     foreach my $doc_ref (@{$required_venue_docs}){
        next if(!$doc_ref);
        my $parentCheck= authstring($doc_ref->{'intFileID'});
        $doc_ref->{'chk'} = $parentCheck;
        push @req_docs,$doc_ref;
    }
     
    my %PageData = (
        target => $Data->{'target'},
        documents => $required_venue_docs,
        Lang => $Data->{'lang'},
        nextaction => 'VENUE_DOCS_u',
        client => $clm,
        venue => $id,
   );  
 
   my $venuedocs;
   $venuedocs = runTemplate($Data, \%PageData, 'entity/required_docs.templ') || '';  
      
      ####################################################################################
      ; # Venue ID = $id AND entityID = $entityID AND entityIDD = $entityIDD</div><br>
      return (0,qq[
        <div class="OKmsg"> $Data->{'LevelNames'}{$Defs::LEVEL_VENUE} Added Successfully</div><br>
        <div>
        $venuedocs
        </div>
        <a href="$Data->{'target'}?client=$clm&amp;venueID=$id&amp;a=VENUE_DT">Display Details for $params->{'d_strLocalName'}</a><br><br>
        <b>or</b><br><br>
        <a href="$Data->{'target'}?client=$cl&amp;a=VENUE_DTA&amp;l=$Defs::LEVEL_VENUE">Add another $Data->{'LevelNames'}{$Defs::LEVEL_VENUE}</a>

      ]);
    }
    
  } ## end if add
  
} ## end sub


sub venueAllowed    {
    #Check if this user is allowed access to this venue
    my ($Data, $venueID) = @_;

    #Get parent entity and check that the user has access to that

    my $st = qq[
        SELECT
            intParentEntityID
        FROM
            tblEntityLinks AS EL
                INNER JOIN tblEntity AS E
                    ON EL.intChildEntityID = E.intEntityID
        WHERE
            intChildEntityID = ?
            AND intEntityLevel = $Defs::LEVEL_VENUE
        LIMIT 1
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute($venueID);
    my $parentID = $query->fetchrow_array() || 0;
    $query->finish();
    return 0 if !$parentID;
    my $authID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'});
    return 1 if($authID== $parentID);
    $st = qq[
        SELECT
            intRealmID
        FROM
            tblTempEntityStructure
        WHERE
            intParentID = ?
            AND intChildID = ?
            AND intDataAccess = $Defs::DATA_ACCESS_FULL
        LIMIT 1
    ];
    $query = $Data->{'db'}->prepare($st);
    $query->execute($authID, $parentID);
    my ($found) = $query->fetchrow_array();
    $query->finish();
    return $found ? 1 : 0;
}

sub list_venue_fields {
    my ($action, $Data, $venueID) = @_;
    my $back_screen = param('bscrn') || '';

    warn "METHOD CALL $venueID";
    my $entityID = getID($Data->{'clientValues'});
    warn "METHOD CALL $entityID";
    my $venueDetails = loadVenueDetails($Data->{'db'}, $venueID);

    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Invalid Venue/Facility ID.")) if($venueDetails->{'intEntityLevel'} != $Defs::LEVEL_VENUE);
    
    my $entityFields = new EntityFields();
    my $title = $venueDetails->{strLocalName} . ": " . $Data->{'lang'}->txt("Edit Fields");

    $entityFields->setEntityID($venueID);
    $entityFields->setData($Data);

    my $fields = $entityFields->getAll("HTML");
    my $count = scalar(@{$fields});

    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Facility Field(s) not found.")) if(!$count);

    my %PageData = (
        target  => $Data->{'target'},
        Lang    => $Data->{'lang'},
        action  => 'VENUE_Fupdate',
        client  => $Data->{'client'},
        venueID => $venueID,
        bscrn => $back_screen,
        #fields  => $fields,
        FieldElements => $fields,
    );  
 
    my $fieldsPage = runTemplate(
        $Data,
        \%PageData,
        'entity/venue_fields.templ'
    );  

    return($fieldsPage, $title);
}

sub update_venue_fields {
    my ($action, $Data, $venueID) = @_;
    my $back_screen = param('bscrn') || '';
    my $activeTab = safe_param('at','number') || 1;

    my $p = new CGI;
	  my %params = $p->Vars();

    my $entityID = getID($Data->{'clientValues'});
    my $venueDetails = loadVenueDetails($Data->{'db'}, $venueID);

    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Invalid Venue/Facility ID.")) if($venueDetails->{'intEntityLevel'} != $Defs::LEVEL_VENUE);

    my $entityFields = new EntityFields();
    my $title = $venueDetails->{strLocalName} . ": " . $Data->{'lang'}->txt("Edit Fields");;

    $entityFields->setEntityID($venueID);
    $entityFields->setData($Data);

    my $fields = $entityFields->getAll("HTML");
    my $count = scalar(@{$fields});

    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Invalid Venue/Facility ID.")) if(!$count);

    $entityFields->setCount($count);

    my $facilityFieldDataCluster;
    my $errors;
    my $fieldElements;
    ($facilityFieldDataCluster, $errors, $fieldElements) = $entityFields->retrieveFormFieldData(\%params);
 
    my %PageData = (
        target  => $Data->{'target'},
        Lang    => $Data->{'lang'},
        action  => 'VENUE_Fupdate',
        client  => $Data->{'client'},
        venueID => $venueID,
        Errors  => $errors,
        FieldElements  => $fieldElements,
        ActiveTab => $activeTab,
    );
 
    my $fieldsPage = runTemplate(
        $Data,
        \%PageData,
        'entity/venue_fields.templ'
    );  

    if(scalar(@{$errors})){
        return($fieldsPage, $title);
    }

    my $updatedFields = 0;

    foreach my $fieldObjData (@{$facilityFieldDataCluster}){
        my $entityFieldObj = new EntityFieldObj(db => $Data->{'db'}, ID => $fieldObjData->{'intEntityFieldID'});
        $entityFieldObj->setValues($fieldObjData);
        $entityFieldObj->write();
        $updatedFields++;
    }

    #$PageData{'FieldElements'} = $entityFields->getAll();
    $PageData{'Success'} = $updatedFields;
    delete $PageData{'Errors'};

    my %flashMessage;
    $flashMessage{'flash'}{'type'} = 'success';
    $flashMessage{'flash'}{'message'} = $Data->{'lang'}->txt("Facility fields have been updated.");

    #FlashMessage::setFlashMessage($Data, 'FAC_FM', \%flashMessage);

    if($back_screen){
      my %tempClientValues = getClient($Data->{'client'});
      $tempClientValues{currentLevel} = $tempClientValues{authLevel};
      my $tempClient= setClient(\%tempClientValues);
        $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$tempClient&venueID=$venueID&$back_screen";
      }
      else {
		FlashMessage::setFlashMessage($Data, 'FAC_FM', \%flashMessage);
        $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&amp;a=FE_D&amp;venueID=$venueID";
      }
     
    $fieldsPage = runTemplate(
        $Data,
        \%PageData,
        'entity/venue_fields.templ'
    );

    return($fieldsPage, $title);
}

sub add_venue_fields {
    my ($action, $Data, $venueID) = @_;

	my $p = new CGI;
	my %params = $p->Vars();

    my @err;
    if (!$params{'field_count'}) {
        push @err, $Data->{'lang'}->txt("Number of Fields") . " : " . $Data->{'lang'}->txt("required");
    }

    if ($params{'field_count'} !~ /^\d+$/) {
        push @err, $Data->{'lang'}->txt("Number of Fields"). " : " .$Data->{'lang'}->txt("invalid input");
    }

    return pre_add_venue_fields($action, $Data, $venueID, \@err) if scalar(@err);

    my $venueDetails = loadVenueDetails($Data->{'db'}, $venueID);
    my $title = $venueDetails->{strLocalName} . ": " . $Data->{'lang'}->txt("Add Fields");

    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Invalid Venue/Facility ID.")) if($venueDetails->{'intEntityLevel'} != $Defs::LEVEL_VENUE);

    #TODO: create form to accept number of fields
    my $facilityFieldCount = $params{'field_count'};

    my $facilityFields = new EntityFields();
    $facilityFields->setEntityID($venueID);
    $facilityFields->setData($Data);
    my $existingFacilityFields = $facilityFields->getAll();
    $facilityFields->setCount($facilityFieldCount + scalar(@{$facilityFields->getAll()}));
    
    my @facilityFieldsData = ();

    my %FieldsGridData = (
        target  => $Data->{'target'},
        Lang    => $Data->{'lang'},
        action  => 'VENUE_Fprocadd',
        client  => $Data->{'client'},
        venueID => $venueID,
        field_count => $params{'field_count'},
        FieldElements => \@facilityFieldsData,
    );
	$FieldsGridData{'TID'} = $params{'TID'} if($params{'TID'});	
	$FieldsGridData{'at'} = $params{'at'} if($params{'at'});

    if($action =~ /^VENUE_Fadd/) {
        my $startNewIndex = 1;

        foreach my $fieldObjData (@{$existingFacilityFields}){
            $facilityFields->setDBData($fieldObjData);
            push @facilityFieldsData, $facilityFields->generateSingleRowField($startNewIndex, $fieldObjData->{'intEntityFieldID'});
            $startNewIndex++;
        }

        for my $i ($startNewIndex .. ($facilityFieldCount + $startNewIndex) - 1){
            $facilityFields->setDBData({});
            push @facilityFieldsData, $facilityFields->generateSingleRowField($i, undef);
        }

        my $facilityFieldsContent = runTemplate(
            $Data,
            \%FieldsGridData,
            'entity/venue_fields.templ',
        );


        return ($facilityFieldsContent, $title);
    }
    elsif($action =~ /^VENUE_Fprocadd/){

        my $facilityFieldDataCluster;
        my $errors;
        my $fieldElements;
        ($facilityFieldDataCluster, $errors, $fieldElements) = $facilityFields->retrieveFormFieldData(\%params);
        
        $FieldsGridData{'Errors'} = $errors;
        $FieldsGridData{'FieldElements'} = $fieldElements;

       my $facilityFieldsContent = runTemplate(
            $Data,
            \%FieldsGridData,
            'entity/venue_fields.templ'
        );  

        if(scalar(@{$errors})){
            return($facilityFieldsContent, $title);
        }

        my $updatedFields = 0;

        foreach my $fieldObjData (@{$facilityFieldDataCluster}){
            my $existingEntityFieldID = $fieldObjData->{'intEntityFieldID'} || 0;
            my $entityFieldObj = new EntityFieldObj(db => $Data->{'db'}, ID => $existingEntityFieldID);
            $entityFieldObj->load();
            $entityFieldObj->setValues($fieldObjData);
            $entityFieldObj->write();
            $updatedFields++;
        }

        my %flashMessage;
        $flashMessage{'flash'}{'type'} = 'success';
        $flashMessage{'flash'}{'message'} = $Data->{'lang'}->txt("Facility fields have been updated.");

        FlashMessage::setFlashMessage($Data, 'FAC_FM', \%flashMessage);
        #$Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&amp;a=FE_D&amp;venueID=$venueID";
		
		$Data->{'RedirectTo'} = $params{'TID'} ? "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&amp;a=WF_View&TID=$params{'TID'}&amp;at=$params{'at'}" : "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&amp;a=FE_D&amp;venueID=$venueID";
        return redirectTemplate($Data);

        #$FieldsGridData{'Success'} = $updatedFields;
        #$FieldsGridData{'action'} = "VENUE_Fadd";
        #delete $FieldsGridData{'Errors'};

        #$facilityFieldsContent = runTemplate(
        #    $Data,
        #    \%FieldsGridData,
        #    'entity/venue_fields.templ'
        #);

        #return($facilityFieldsContent, $title);

    }
}

sub delete_venue_fields {
    my ($action, $Data, $venueID) = @_;
    my $back_screen = param('bscrn') || '';
    my $activeTab = safe_param('at','number') || 1;

    my $p = new CGI;
	  my %params = $p->Vars();

    my $entityID = getID($Data->{'clientValues'});
    my $venueDetails = loadVenueDetails($Data->{'db'}, $venueID);

    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Invalid Venue/Facility ID.")) if($venueDetails->{'intEntityLevel'} != $Defs::LEVEL_VENUE);

    my $entityFields = new EntityFields();
    my $title = $venueDetails->{strLocalName} . ": " . $Data->{'lang'}->txt("Delete Fields");

    $entityFields->setEntityID($venueID);
    $entityFields->setData($Data);

    my $fields = $entityFields->getAll("RAW");
    my $count = scalar(@{$fields});

    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Invalid Venue/Facility ID.")) if(!$count);

    $entityFields->setCount($count);

    my %templateData = (
        Disciplines => \%Defs::sportType,
        GroundNature => \%Defs::fieldGroundNatureType,
        FieldElements => $fields,
        action => 'VENUE_Fprocdel',
        client  => $Data->{'client'},
        venueID => $venueID,
        type => 'delete',
    );

    my $fields_summary = runTemplate(
        $Data,
        \%templateData,
        'entity/venue_fields.templ'
    );

    return ($fields_summary, $title);
}

sub proc_delete_venue_fields {
    my ($action, $Data, $venueID) = @_;

    my $p = new CGI;
    my %params = $p->Vars();

    my @target_fields = $p->param('deletefield[]');

    my $count = scalar(@target_fields);
    return displayGenericError($Data, $Data->{'lang'}->txt("Error"), $Data->{'lang'}->txt("Invalid number of fields to be deleted.")) if !$count;

    my $bind_str = join ', ', (split(/ /, "? " x ($count)));
    push @target_fields, $venueID;

    my $st = qq[
        UPDATE tblEntityFields
        SET
            strStatus = 'DELETED'
        WHERE
            intEntityFieldID IN ($bind_str)
            AND intEntityID = ?
    ];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(@target_fields) or query_error($st);
    $query->finish;

    my %flashMessage;
    $flashMessage{'flash'}{'type'} = 'success';
    $flashMessage{'flash'}{'message'} = $Data->{'lang'}->txt("Facility fields have been updated.");

    FlashMessage::setFlashMessage($Data, 'FAC_FM', \%flashMessage);
    $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&amp;a=FE_D&amp;venueID=$venueID";

    return redirectTemplate($Data);
}

sub pre_add_venue_fields {
    my ($action, $Data, $venueID, $err) = @_;

	my $p = new CGI;
	my %params = $p->Vars();
	

    my $title = $Data->{'lang'}->txt("Number of Fields");
    my %TemplateData;
    $TemplateData{'action'} = 'VENUE_Fadd';
    $TemplateData{'client'} = $Data->{'client'};
    $TemplateData{'venueID'} = $venueID;
    $TemplateData{'Errors'} = $err if scalar($err);
    $TemplateData{'field_count'} = $params{'field_count'} if $params{'field_count'};

	$TemplateData{'TID'} = $params{'TID'} if($params{'TID'});
	$TemplateData{'at'} = $params{'at'} if($params{'at'});

    my $body = runTemplate(
        $Data,
        \%TemplateData,
        'entity/add_fields_count.templ',
    );

    return ($body, $title);
}

sub displayGenericError {
    my ($Data, $titleHeader, $message) = @_;

    $titleHeader ||= $Data->{'lang'}->txt("Error");
    my $body = runTemplate(
        $Data,
        {
            message => $message,
        },
        'personrequest/generic/error.templ',
    );

    return ($body, $titleHeader);
}

sub redirectTemplate {
    my ($Data) = @_;

    my $body = runTemplate(
        $Data,
        {},
        '',
    );

    return ($body, ' ');
}



1;

