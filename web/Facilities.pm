#
# $Header: svn://svn/SWM/trunk/web/Venues.pm 10333 2013-12-18 23:54:25Z apurcell $
#

package Facilities;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(handleFacilities getFacilities loadFacilityDetails getFacilityHeader);
@EXPORT_OK = qw(handleFacilities getFacilities loadFacilityDetails getFacilityHeader);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use CGI qw(unescape param);
use FormHelpers;
use GridDisplay;
use FacilitiesUtils;
use Data::Dumper;
use Log;

require RecordTypeFilter;
require FacilityObj;


sub handleFacilities {
    my ( $action, $Data ) = @_;

    my $facilityID = param('facilityID') || param("id") || 0;
    my $resultHTML = '';
    my $title      = '';
    if ( $action =~ /^FACILITY_DT/ ) {
        ( $resultHTML, $title ) = facility_details( $action, $Data, $facilityID );
    }
    elsif ( $action =~ /^FACILITY_L/ ) {

        #List Facilities
        my $tempResultHTML = '';
        ( $tempResultHTML, $title ) = listFacilities($Data);
        $resultHTML .= $tempResultHTML;
    }
    elsif ( $action =~ /^FACILITY_DEL/ ) {
        ( $resultHTML, $title ) = deleteFacility( $Data, $facilityID );
    }

    return ( $resultHTML, $title );
}

sub facility_details {
    my ( $action, $Data, $facilityID ) = @_;

    my $option = 'display';
    
    if ($action eq 'FACILITY_DTE' and allowedAction( $Data, 'facilities_e' )){
        $option = 'edit';
    }
    elsif ($action eq 'FACILITY_DTA' and allowedAction( $Data, 'facilities_a' )){
        $option = 'add';
        $facilityID = 0;
    }

    my $intRealmID = $Data->{'Realm'} >= 0 ? $Data->{'Realm'} : 0;
    my $field = loadFacilityDetails( $Data->{'db'}, $facilityID, $intRealmID ) || ();
    my $client = setClient( $Data->{'clientValues'} ) || '';

    my ($facility_singular, $facility_plural) = get_facility_titles($Data);

    my %FieldDefinitions = (
        fields => {
            intFacilityID => {
                label       => "$facility_singular ID",
                value       => $field->{intFacilityID},
                type        => 'text',
                readonly    => 1,
                size        => '40',
                maxsize     => '100',
                compulsory  => 0,
                sectionname => 'details',
            },
            strName => {
                label   => "$facility_singular Name",
                value   => $field->{strName},
                type    => 'text',
                size    => '40',
                maxsize => '100',
                compulsory  => 1,
                sectionname => 'details',
            },
            intRecStatus => {
                label         => 'Active?',
                value         => $field->{intRecStatus},
                type          => 'checkbox',
                default       => 1,
                displaylookup => { 1 => 'Yes', 0 => 'No' },
                sectionname   => 'details',
            },
            strAbbrev => {
                label       => "Abbreviation Name",
                value       => $field->{strAbbrev},
                type        => 'text',
                size        => '20',
                sectionname => 'details',
            },
            strAddress1 => {
                label       => "Address 1",
                value       => $field->{strAddress1},
                type        => 'text',
                size        => '40',
                sectionname => 'details',
            },
            strAddress2 => {
                label       => "Address 2",
                value       => $field->{strAddress2},
                type        => 'text',
                size        => '40',
                sectionname => 'details',
            },
            strSuburb => {
                label       => "Suburb",
                value       => $field->{strSuburb},
                type        => 'text',
                size        => '40',
                sectionname => 'details',
            },
            strState => {
                label       => "State",
                value       => $field->{strState},
                type        => 'text',
                size        => '40',
                sectionname => 'details',
            },
            strPostalCode => {
                label       => "Postal Code",
                value       => $field->{strPostalCode},
                type        => 'text',
                size        => '10',
                sectionname => 'details',
            },
            strCountry => {
                label       => "Country",
                value       => $field->{strCountry},
                type        => 'text',
                size        => '40',
                sectionname => 'details',
            },
            strPhone => {
                label       => "Phone",
                value       => $field->{strPhone},
                type        => 'text',
                size        => '20',
                sectionname => 'details',
            },
            strPhone2 => {
                label       => "Phone 2",
                value       => $field->{strPhone2},
                type        => 'text',
                size        => '20',
                sectionname => 'details',
            },
            strFax => {
                label       => "Fax",
                value       => $field->{strFax},
                type        => 'text',
                size        => '20',
                sectionname => 'details',
            },
            strMapRef => {
                label       => "Map Reference (Printed Map)",
                value       => $field->{strMapRef},
                type        => 'text',
                size        => '10',
                sectionname => 'details',
            },
            strLGA => {
                label       => 'Local Government Area',
                value       => $field->{strLGA},
                type        => 'text',
                size        => '40',
                maxsize     => '150',
                validate    => 'NOHTML',
                sectionname => 'details',
                class       => 'chzn-select',
            },
            intMapNumber => {
                label       => "Map Number (Printed Map)",
                value       => $field->{intMapNumber},
                type        => 'text',
                size        => '10',
                sectionname => 'details',
            },
            mapdesc => {
                label       => 'map desc',
                type        => 'textvalue',
                value       => '<p>Enter Latitude and Longtitude in the boxes below or drag the map marker to the correct location.</p>',
                sectionname => 'mapping',
                SkipProcessing => 1,
            },
            mapblock => {
                label       => "Map",
                value       => '',
                posttext    => ' <div id="map_canvas" style="width:450px;height:450px;border:1px solid #888;"></div>',
                type        => 'hidden',
                size        => '40',
                sectionname => 'mapping',
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
        order => [ qw(intFacilitiesID strName intRecStatus strAbbrev strAddress1 strAddress2 strSuburb strState strPostalCode strCountry strPhone strPhone2 strFax strLGA intMapNumber strMapRef mapdesc dblLat dblLong mapblock)],
        sections => [
            [ 'details', "$facility_singular Details" ],
            [ 'mapping', "Online Mapping" ],
        ],
        options => {
            labelsuffix => ':',
            hideblank   => 1,
            target      => $Data->{'target'},
            formname    => 'n_form',
            submitlabel => ($option eq 'add') ? "Create $facility_singular" : "Update $facility_singular",
            introtext   => 'auto',
            NoHTML      => 1,
            updateSQL   => qq[
                UPDATE tblFacilities
                SET --VAL--
                WHERE 
                    intFacilityID = $facilityID
                    AND intRealmID = $intRealmID
            ],
            addSQL => qq[
                INSERT INTO tblFacilities (
                    intRealmID, 
                    --FIELDS-- 
                )
                VALUES (
                    $intRealmID, 
                    --VAL-- 
                )
            ],
            auditFunction   => \&auditLog,
            auditAddParams  => [ $Data, 'Add', 'Facilities' ],
            auditEditParams => [ $facilityID, $Data, 'Update', 'Facilities' ],
            LocaleMakeText  => $Data->{'lang'},
        },
        carryfields => {
            client  => $client,
            a       => $action,
            facilityID => $facilityID,
        },
    );

    if ( $Data->{'SystemConfig'}{'LGADropDown'} ) {
        my @lgas = split /\|/, $Data->{'SystemConfig'}{'LGADropDown'};
        if (@lgas) {
            my %LGAList = ();
            for my $i (@lgas) { $LGAList{$i} = $i; }
            $FieldDefinitions{'fields'}{'strLGA'}{'type'}        = 'lookup';
            $FieldDefinitions{'fields'}{'strLGA'}{'size'}        = 1;
            $FieldDefinitions{'fields'}{'strLGA'}{'options'}     = \%LGAList;
            $FieldDefinitions{'fields'}{'strLGA'}{'firstoption'} = [ '', " " ];
        }
    }

    my $resultHTML = '';
    ( $resultHTML, undef ) = handleHTMLForm( \%FieldDefinitions, undef, $option, '', $Data->{'db'} );
    my $title = qq[$facility_singular - $field->{strName}];

    my $chgoptions = '';

    if ( $option eq 'display' ) {

        # Edit facility
        if (allowedAction( $Data, 'facility_e' )){
            $chgoptions .= qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=FACILITY_DTE&amp;facilityID=$facilityID">Edit $facility_singular</a></span>];
        }
    }
    elsif ( $option eq 'edit' ) {
        my $facilityObj = FacilityObj->new('db'=>$Data->{db},ID=>$facilityID);
        $facilityObj->load();
        $chgoptions .= qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=FACILITY_DEL&amp;facilityID=$facilityID" onclick="return confirm('Are you sure you want to delete this $facility_singular');">Delete $facility_singular</a> ] if $facilityObj->canDelete();
    }


    $chgoptions = qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;
    $title = $chgoptions . $title;

    $title = "Add New $facility_singular" if $option eq 'add';

    if ( $option ne 'display' ) {
        my $original_lat  = $field->{'dblLat'}  || '-25.901820984476252';
        my $original_long = $field->{'dblLong'} || '134.00135040279997';

        my $zoomstr = $field->{'dblLat'} ? "zoom : 15," : '';

        #TODO: Pull this out to somewhere else
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
    my $text = qq[<p style = "clear:both;"><a href="$Data->{'target'}?client=$client&amp;a=FACILITY_L">Click here</a> to return to list of $facility_plural</p>];
    $resultHTML = $text . $resultHTML . $text;

    return ( $resultHTML, $title );
}

sub loadFacilityDetails {
    my ( $db, $id, $realmID ) = @_;

    $realmID ||= 0;
    my $field = {};

    if ($id) {
        my $statement = qq[
            SELECT *
            FROM 
                tblFacilities
            WHERE 
                intFacilityID = ?
                AND intRealmID = ?
        ];
        my $query = $db->prepare($statement);
        $query->execute( $id, $realmID, );
        $field = $query->fetchrow_hashref();
        $query->finish;
    }

    foreach my $key ( keys %{$field} ) {
        if ( !defined $field->{$key} ) { $field->{$key} = ''; }
    }

    return $field;
}


sub deleteFacility {
    my ($Data, $facilityID) = @_;

    my $dbh = $Data->{db};
    my $assocID = $Data->{clientValues}{assocID};
    my $client = setClient($Data->{'clientValues'}) || '';

    my $facililyObj = FacilityObj->new(ID=>$facilityID, db=>$dbh);
    my $result = $facililyObj->delete();
    
    my ($facility_singular, $facility_plural) = get_facility_titles($Data);

    my $resultHTML = '';
    if ($result && $result !~/^ERROR/) {
        $resultHTML .= '<p class="OKmsg">' . $facility_singular . ' successfully deleted.</p>';
        auditLog($facilityID, $Data, 'Delete', 'Facility');
    }
    else {
        $resultHTML .= '<p class="warningmsg">Unable to delete ' . $facility_singular .'<br>' . $facility_singular . ' may be assigned to active programs.</p>';
    }

    $resultHTML .= qq[<p><a href="$Data->{'target'}?client=$client&amp;a=FACILITY_L">Click here</a> to return to list of $facility_plural</p>];

    return $resultHTML;
}

sub getFacilityHeader {

    my ( $Data, $facilityID ) = @_;

    my $facility_ref = loadFacilityDetails( $Data->{'db'}, $facilityID, $Data->{'Realm'} ) || ();
    my ($facility_singular, $facility_plural) = get_facility_titles($Data);

    my $facilityBody = qq[<div><span class="label">$facility_singular Name:</span> $facility_ref->{'strName'}<br>];
    $facilityBody .= qq[<span class="label">Abbreviation:</span> $facility_ref->{'strAbbrev'}<br>] if ( $facility_ref->{'strAbbrev'} ne '' );
    $facilityBody .= qq[<span class="label">Address:</span> $facility_ref->{'strAddress1'}<br>$facility_ref->{'strAddress2'}] if ( $facility_ref->{'strAddress1'} or $facility_ref->{'strAddress2'} );
    $facilityBody .= qq[<span class="label">Suburb:</span> $facility_ref->{'strSuburb'}<br>] if ( $facility_ref->{'strSuburb'} );
    $facilityBody .= qq[</div><br>];

    return $facilityBody;

}

sub listFacilities {
    my ($Data) = @_;

    my $resultHTML = '';
    my $client     = unescape( $Data->{client} );

    my $statement = qq[
        SELECT
          * 
        FROM 
          tblFacilities
        WHERE 
          intRealmID = ?
          AND intRecStatus <> $Defs::RECSTATUS_DELETED
            ORDER BY 
          strName
    ];

    my $query = $Data->{'db'}->prepare($statement);
    $query->execute( $Data->{'Realm'} );

    my %tempClientValues = getClient($client);

    my @rowdata    = ();
    my $tempClient = setClient( \%tempClientValues );

    while ( my $dref = $query->fetchrow_hashref() ) {
        my $facilityID = $dref->{intFacilityID};


        push @rowdata, {
            id         => $facilityID          || next,
            strName    => $dref->{'strName'}   || '',
            SelectLink =>"$Data->{'target'}?client=$tempClient&amp;a=FACILITY_DTE&amp;facilityID=$dref->{intFacilityID}",
            strAbbrev  => $dref->{'strAbbrev'} || '',
            strSuburb    => $dref->{'strSuburb'}    || '',
            intRecStatus => $dref->{'intRecStatus'} || 0,

        };
    }
    
    my ($facility_singular, $facility_plural) = get_facility_titles($Data);

    my $addlink = ''; 
    my $title=qq[$facility_singular];  
    {
        $addlink = qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$tempClient&amp;a=FACILITY_DTA">Add</a></span>];
    }

    my $modoptions = qq[<div class="changeoptions">$addlink</div>];
    $title = $modoptions . $title;
    my $rectype_options = RecordTypeFilter::show_recordtypes( $Data, 0, undef, undef, 'Name' ) || '';

    my @headers = (
        {
            type  => 'Selector',
            field => 'SelectLink',
        },
        {
            name  => $Data->{'lang'}->txt($facility_singular . ' Name'),
            field => 'strName',
        },
        {
            name  => $Data->{'lang'}->txt('Abbreviation'),
            width => 50,
            field => 'strAbbrev',
        },
        {
            name  => $Data->{'lang'}->txt('Suburb'),
            field => 'strSuburb',
        },
        {
            name   => $Data->{'lang'}->txt('Status'),
            field  => 'intRecStatus',
            editor => 'checkbox',
            type   => 'tick',
            width  => 30,
        },

    );

    my $filterfields = [
        {
            field     => 'strName',
            elementID => 'id_textfilterfield',
            type      => 'regex',
        },
        {
            field     => 'intRecStatus',
            elementID => 'dd_actstatus',
            allvalue  => '2',
        },
    ];

    my $grid = showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '99%',
        filters => $filterfields,
        client  => $client,
        saveurl => 'ajax/aj_grid_update.cgi',
        ajax_keyfield => 'intFacilityID',
        saveaction => 'edit_facility',
    );

    $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:99%;">$rectype_options</div>
            $grid
        </div>
    ];

    return ( $resultHTML, $title );
}

1;

