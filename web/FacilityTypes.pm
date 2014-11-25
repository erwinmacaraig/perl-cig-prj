package FacilityTypes;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getAll);

use strict;

use lib '.', '..';

use Defs;

sub getAll {
	my(
        $Data,
    )=@_;

    my $db = $Data->{'db'};
    my $realmID = $Data->{'Realm'} || 0;

    my @facilityTypes = ();
    if($db) {
        my $statement=qq[
            SELECT 
                intFacilityTypeID,
                intSubRealmID,
                strName
            FROM 
                tblFacilityType
            WHERE 
                intRealmID IN (0, ?)
            ORDER BY
                strName ASC
        ];
        my $query = $db->prepare($statement);
        $query->execute($realmID);

        while (my $dref = $query->fetchrow_hashref) {
            next if !$dref->{'strName'};
            push @facilityTypes, $dref;
        }
    }
    return \@facilityTypes;
}

