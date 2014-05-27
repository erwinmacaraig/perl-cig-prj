#
# $Header: svn://svn/SWM/trunk/web/Venues.pm 10395 2014-01-08 23:51:03Z apurcell $
#

package Venues;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleVenues getVenues loadVenueDetails getVenueHeader);
@EXPORT_OK=qw(handleVenues getVenues loadVenueDetails getVenueHeader);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use CGI qw(unescape param);
use FormHelpers;
use AssocObj;
use VenueObj;
use GridDisplay;
use Log;
require RecordTypeFilter;

sub handleVenues    {
    my ($action, $Data)=@_;

    my $venueID = param('venueID') || param("id") || 0;
    my $resultHTML='';
    my $title='';
    if ($action =~/^VENUE_DT/) {
        ($resultHTML,$title)=venue_details($action, $Data, $venueID);
    }
    elsif ($action =~/^VENUE_L/) {
        #List Venues
        my $tempResultHTML = '';
        ($tempResultHTML,$title)=listVenues($Data);
        $resultHTML .= $tempResultHTML;
    }
    elsif ($action =~/^VENUE_DEL/) {
        ($resultHTML,$title)=deleteVenue($Data,$venueID);
    }
        
    return ($resultHTML,$title);
}

sub venue_details   {
    my ($action, $Data, $venueID)=@_;

    my $option='display';
    $option='edit' if $action eq 'VENUE_DTE' and allowedAction($Data, 'venue_e');
    $option='add' if $action eq 'VENUE_DTA' and allowedAction($Data, 'venue_a');
    $venueID=0 if $option eq 'add';
    my $field=loadVenueDetails($Data->{'db'}, $venueID, $Data->{'clientValues'}{'assocID'}) || ();
    
    my $intAssocID = $Data->{'clientValues'}{'assocID'} >= 0 ? $Data->{'clientValues'}{'assocID'} : 0;
    my $client=setClient($Data->{'clientValues'}) || '';
    
    my %FieldDefinitions = (
        fields => {
            intVenueID => {
                label       => "Venue ID",
                value       => $field->{intDefVenueID},
                type        => 'text',
                readonly    => 1,
                size        => '40',
                maxsize     => '100',
                compulsory  => 0,
                sectionname => 'details',
            },
            strName => {
                label       => "Venue Name",
                value       => $field->{strName},
                type        => 'text',
                size        => '40',
                maxsize     => '100',
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
            intTypeID => {
                label       => 'Venue Type',
                value       => $field->{intTypeID},
                type        => 'lookup',
                options     => \%Defs::VenueTypes,
                firstoption => [ '', " " ],
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
        order => [ qw(intVenueID strName intRecStatus strAbbrev intTypeID strAddress1 strAddress2 strSuburb strState strPostalCode strCountry strPhone strPhone2 strFax strLGA intMapNumber strMapRef mapdesc dblLat dblLong mapblock)],
        sections => [ 
            [ 'details', "Venue Details" ], 
            [ 'mapping', "Online Mapping" ], 
        ],
        options => {
            labelsuffix => ':',
            hideblank   => 1,
            target      => $Data->{'target'},
            formname    => 'n_form',
            submitlabel => "Update Venue",
            introtext   => 'auto',
            NoHTML      => 1,
            updateSQL   => qq[
                UPDATE tblDefVenue
                SET --VAL--
                WHERE 
                    intDefVenueID = $venueID
                    AND intAssocID = $intAssocID
            ],
            addSQL => qq[
                INSERT INTO tblDefVenue (
                    intAssocID, 
                    --FIELDS-- 
                )
                VALUES (
                    $intAssocID, 
                    --VAL-- 
                )
            ],
            auditFunction   => \&auditLog,
            auditAddParams  => [ $Data, 'Add', 'Venue' ],
            auditEditParams => [ $venueID, $Data, 'Update', 'Venue' ],
            LocaleMakeText  => $Data->{'lang'},
        },
        carryfields => {
            client  => $client,
            a       => $action,
            venueID => $venueID,
        },
    );
    
    if($Data->{'SystemConfig'}{'LGADropDown'})  {
        my @lgas =split /\|/,$Data->{'SystemConfig'}{'LGADropDown'};
        if(@lgas) {
            my %LGAList=();
            for my $i(@lgas)  {$LGAList{$i}=$i; }
            $FieldDefinitions{'fields'}{'strLGA'}{'type'}='lookup';
            $FieldDefinitions{'fields'}{'strLGA'}{'size'}=1;
            $FieldDefinitions{'fields'}{'strLGA'}{'options'}=\%LGAList;
            $FieldDefinitions{'fields'}{'strLGA'}{'firstoption'} = [''," "];
        }
    }
    
    my $resultHTML='';
    ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, '',$Data->{'db'});
    my $title=qq[Venue- $field->{strName}];

    my $chgoptions='';
    my $assocObj =  new AssocObj(db=>$Data->{'db'}, ID=>$Data->{'clientValues'}{'assocID'},assocID=>$Data->{'clientValues'}{'assocID'});
    $assocObj->load();
    my $allowSWOL = $assocObj->getValue('intSWOL');
    
    if($option eq 'display')  {
        # Edit Venue.
        $chgoptions.=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=VENUE_DTE&amp;venueID=$venueID">Edit Venue</a></span> ] if allowedAction($Data, 'venue_e');
    }
    elsif ($option eq 'edit' && $allowSWOL) {
        # Delete Venue.
        my $venueObj = new VenueObj('db'=>$Data->{db},ID=>$venueID,assocID=>$intAssocID);
        $venueObj->load();
        
        $chgoptions.=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=VENUE_DEL&amp;venueID=$venueID" onclick="return confirm('Are you sure you want to delete this venue');">Delete Venue</a> ] if $venueObj->canDelete();
    }
    
    $chgoptions= '' if (!$field->{intAssocID});
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
    my($db, $id, $assocID) = @_;

    $assocID ||= 0;
    my $field = {};

    if($id) {
        my $statement=qq[
            SELECT *
            FROM 
                tblDefVenue
            WHERE 
                intDefVenueID = ?
                AND intAssocID = ?
        ];
        my $query = $db->prepare($statement);
        $query->execute(
            $id,
            $assocID,
        );
        $field=$query->fetchrow_hashref();
        $query->finish;
    }

    foreach my $key (keys %{$field})  { 
        if(!defined $field->{$key}) {$field->{$key}='';} 
    }
    {
        #no data - let's try and add some
        my $st = qq[
            SELECT
                strCountry,
                strState,
                strSuburb
            FROM tblAssoc
            WHERE intAssocID = ?
        ];
        my $query = $db->prepare($st);
        $query->execute(
            $assocID,
        );
        my $assocfield=$query->fetchrow_hashref();
        $query->finish;
        $field->{'strCountry'} ||= $assocfield->{'strCountry'};
        $field->{'strState'} ||= $assocfield->{'strState'};
        $field->{'strSuburb'} ||= $assocfield->{'strSuburb'};
    }
    return $field;
}

sub deleteVenue {
    my ($Data,$venueID) = @_; 

    my $dbh = $Data->{db};
    my $assocID = $Data->{clientValues}{assocID};
    my $client=setClient($Data->{'clientValues'}) || '';
    
    my $venueObj = new VenueObj(ID=>$venueID, assocID=>$assocID, db=>$dbh);
    my $result = $venueObj->delete();
    
    my $resultHTML = '';
    if ($result && $result !~/^ERROR/) {
        $resultHTML .= '<p class="OKmsg">Venue successfully deleted.</p>';
        auditLog($venueID, $Data, 'Delete', 'Venue');
    }
    else {
        $resultHTML .= '<p class="warningmsg">Unable to delete Venue.<br>Venue may be assigned to matches or listed as a team venue.</p>';
    }

    $resultHTML .= qq[<p><a href="$Data->{'target'}?client=$client&amp;a=VENUE_L">Click here</a> to return to list of Venues</p>];
    
    return $resultHTML;
}

sub getVenueHeader  {

    my ($Data, $venueID) = @_;


    my $venue_ref=loadVenueDetails($Data->{'db'}, $venueID, $Data->{'clientValues'}{'assocID'}) || ();

    my $venueBody = qq[
        <div><span class="label">Venue Name:</span> $venue_ref->{'strName'}<br>
    ];
    $venueBody .= qq[<span class="label">Abbreviation:</span> $venue_ref->{'strAbbrev'}<br>] if ($venue_ref->{'strAbbrev'} ne '');
    $venueBody .= qq[<span class="label">Address:</span> $venue_ref->{'strAddress1'}<br>$venue_ref->{'strAddress2'}] if ($venue_ref->{'strAddress1'} or $venue_ref->{'strAddress2'});
    $venueBody .= qq[<span class="label">Suburb:</span> $venue_ref->{'strSuburb'}<br>] if ($venue_ref->{'strSuburb'});
    $venueBody .= qq[</div><br>];

    return $venueBody;

}

sub listVenues  {
    my($Data) = @_;

    my $resultHTML = '';
    my $client = unescape($Data->{client});

    my $statement=qq[
        SELECT
          * 
        FROM 
          tblDefVenue
        WHERE 
          intAssocID = ?
          AND intRecStatus <> $Defs::RECSTATUS_DELETED
            ORDER BY 
          strName
    ];

    my $query = $Data->{'db'}->prepare($statement);
    $query->execute(
        $Data->{'clientValues'}{'assocID'}
    );

    my %tempClientValues = getClient($client);
    my $currentname='';

    my @rowdata = ();
    while (my $dref= $query->fetchrow_hashref()) {
        my $venueID = $dref->{intDefVenueID};
        my $tempClient = setClient(\%tempClientValues);
        $dref->{VenueType} = $Defs::VenueTypes{$dref->{intTypeID}} || '';
        
        push @rowdata, {
            id => $venueID || next,
            strName => $dref->{'strName'} || '',
            SelectLink => "$Data->{'target'}?client=$tempClient&amp;a=VENUE_DTE&amp;venueID=$dref->{intDefVenueID}",
            strAbbrev => $dref->{'strAbbrev'} || '',
            VenueType => $dref->{'VenueType'} || '',
            strSuburb => $dref->{'strSuburb'} || '',
            intRecStatus => $dref->{'intRecStatus'} || 0,
        };
    }

    my $addlink='';
    my $title=qq[Venues];
    {
        my $tempClient = setClient(\%tempClientValues);
        $addlink=qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$tempClient&amp;a=VENUE_DTA">Add</a></span>];

    }

    my $modoptions=qq[<div class="changeoptions">$addlink</div>];
    $title=$modoptions.$title;
    my $rectype_options=RecordTypeFilter::show_recordtypes($Data, $Defs::LEVEL_ASSOC,undef, undef, 'Name') || '';

    my @headers = (
        {
            type  => 'Selector',
            field => 'SelectLink',
        },
        {
            name  => $Data->{'lang'}->txt('Venue Name'),
            field => 'strName',
        },
        {
            name  => $Data->{'lang'}->txt('Abbreviation'),
            width => 50,
            field => 'strAbbrev',
        },
        {
            name  => $Data->{'lang'}->txt('Venue Type'),
            field => 'VenueType',
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

    my $grid  = showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '99%',
        filters => $filterfields,
    );

    $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:99%;">$rectype_options</div>
            $grid
        </div>
    ];

    return ($resultHTML,$title);
}

1;

