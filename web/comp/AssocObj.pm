#
# $Header: svn://svn/SWM/trunk/web/comp/AssocObj.pm 9897 2013-11-21 01:05:03Z tcourt $
#

package AssocObj;

use strict;
use BaseAssocObject;
our @ISA =qw(BaseAssocObject);

use lib '.', '..', '../..';
use Defs;

sub load {
  my $self = shift;

	my $st=qq[
		SELECT * 
		FROM tblAssoc
		WHERE intAssocID = ?
	];

	my $q = $self->{'db'}->prepare($st);
	$q->execute($self->{'ID'});
	if($DBI::err)	{
		$self->LogError($DBI::err);
	}
	else	{
		$self->{'DBData'}=$q->fetchrow_hashref();	
	}
}

# Static method - returns an array of hashes.
# Each hash represents one venue.
sub getVenues {
    my $class = shift;
    my $Data = shift;
    my $active_only = shift;
    
    my $assoc_id = $Data->{'clientValues'}{'assocID'};
    return undef if !$assoc_id;
    my $venue_status_where = '';
    if ($active_only) {
        $venue_status_where = qq[ AND intRecStatus = $Defs::RECSTATUS_ACTIVE];
    }
    else {
        $venue_status_where = qq[ AND intRecStatus != $Defs::RECSTATUS_DELETED];
    }
    my $st = qq[
		         SELECT 
			       intDefVenueID, 
			       strName
                 FROM 
                   tblDefVenue
                 WHERE 
                    intAssocID = ?
                 $venue_status_where        
                 ORDER BY strName
                 ];
    
    my $qry =  $Data->{db}->prepare($st);
    $qry->bind_param(1, $assoc_id);
    $qry->execute();
    
    return $qry->fetchall_arrayref(); 
}


# Static method - returns hash of comps, compID as key, strTitle as value.
sub getClubs {
    my $class = shift;
    my ($dbh,$assocID) = @_;
    
       
    # Find the clubs for this Assoc
    my $query = qq[
                   SELECT tblClub.intClubID, tblClub.strName
                   FROM tblClub
                   INNER JOIN tblAssoc_Clubs USING (intClubID)
                   WHERE intAssocID = $assocID
                   AND tblClub.intRecStatus = $Defs::RECSTATUS_ACTIVE
                   AND tblAssoc_Clubs.intRecStatus = $Defs::RECSTATUS_ACTIVE
        ];

    my $sth = $dbh->prepare($query);
    $sth->execute();

    my %Clubs = ();

    while (my $dref = $sth->fetchrow_hashref()) {
        $Clubs{$dref->{'intClubID'}} = $dref->{'strName'};
    }
    return \%Clubs;
}


1;
