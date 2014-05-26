#
# $Header: svn://svn/SWM/trunk/web/Venues.pm 10333 2013-12-18 23:54:25Z apurcell $
#

package FacilitiesUtils;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get_available_facilities get_facilities_by_lat_long get_facility_titles);
@EXPORT_OK = qw(get_available_facilities get_facilities_by_lat_long get_facility_titles);

use lib ".", "..", "../..", "comp";

use strict;
use Log;
use Data::Dumper;

require FacilityObj;

sub get_available_facilities {
    my $params = shift;
    
    my ($dbh, $realm_id, $subrealm_id, $assoc_id) = @{$params}{qw/ dbh realm_id subrealm_id assoc_id /};
    
    # If we dont have a database handle or a realm, then there is not much point in living...
    return unless ($dbh && $realm_id);
    
    my @where_conditions;
    my @values;
    
    # Realm
    push @where_conditions, 'intRealmID = ?';
    push @values, $realm_id;
    
    #TODO: Sub-realm
    
    #TODO: Assoc
    
    my $where_statement = join (', ', @where_conditions);

    my $search_sql = qq[
        SELECT 
            *
        FROM
            tblFacilities
        WHERE
            $where_statement
        ORDER BY 
            strName
    ];
    
    my $search_stmt = $dbh->prepare($search_sql);
    $search_stmt->execute( @values );
    my $facilities = $search_stmt->fetchall_hashref('intFacilityID') || {};
    my @facilities_list;
    
    foreach my $facilityID (keys %{$facilities}){
        my $facility_obj = FacilityObj->new(
            'ID' => $facilityID,
            'db' => $dbh,
            'DBData' => $facilities->{$facilityID},
        );
        
        push @facilities_list, $facility_obj;
    }  
    
    return \@facilities_list;
    
}

sub get_facilities_by_lat_long {
    my $params = shift;
    
    my ($dbh, $realm_id, $subrealm_id, $latitude, $longitude, $distance, $state) = @{$params}{qw/ dbh realm_id subrealm_id latitude longitude distance state/};
    
    # If we dont have a database handle or a realm, then there is not much point in living...
    return unless ($dbh && $realm_id);
    
    # If we dont have a latitude or longitude, then there is not much point in living...
    return unless ($latitude && $longitude);
    
    my @where_conditions;
    my @having_conditions;
    my @values;
    
    # Push on long/lat
    push @values, $latitude, $longitude, $latitude;
    
    # Realm
    push @where_conditions, 'intRealmID = ?';
    push @values, $realm_id;
    
    #TODO: Sub-realm
    
    if ( $state ){
        push @having_conditions, 'strState = ?'; 
        push @values, $state;
    }
    else{
        push @having_conditions, 'strDistance < ?'; 
        push @values, $distance;
    }
    
    my $where_statement  = join (', ', @where_conditions);
    my $having_statement = join (', ', @having_conditions);

    my $search_sql = qq[
        SELECT 
            *,
            ( 6371 * acos(
                cos( radians(?) )
                * cos( radians( dblLat ) )
                * cos( radians( dblLong )
                - radians(?) )
                + sin( radians(?) )
                * sin( radians( dblLat ) )
              )
            ) AS strDistance
        FROM
            tblFacilities
        WHERE
            $where_statement
        HAVING
            $having_statement
        ORDER BY 
            strDistance, strName
    ];
    
    my $search_stmt = $dbh->prepare($search_sql);
    $search_stmt->execute( @values );

    my @facilities_list;

    while (my $facility_ref = $search_stmt->fetchrow_hashref ) {
        my $facility_id = $facility_ref->{'intFacilityID'};

        # We dont need distance any longer
        delete $facility_ref->{'strDistance'};
        
        my $facility_obj = FacilityObj->new(
            'ID' => $facility_id,
            'db' => $dbh,
            'DBData' => $facility_ref,
        );
        
        push @facilities_list, $facility_obj;
    }  
    
    return \@facilities_list;
    
}

sub get_facility_titles {
    my $Data = shift;
    
    my $facility_singular = $Data->{'SystemConfig'}{'Custom_Facility_Title_Singular'} || 'Facility';
    my $facility_plural = $Data->{'SystemConfig'}{'Custom_Facility_Title_Plural'} || 'Facilities';
    
    return ($facility_singular, $facility_plural);
}
1;