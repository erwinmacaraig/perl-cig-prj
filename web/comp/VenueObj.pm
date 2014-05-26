#
# $Header: svn://svn/SWM/trunk/web/comp/VenueObj.pm 11449 2014-05-01 04:29:44Z dhanslow $
#

package VenueObj;
use BaseAssocObject;
our @ISA =qw(BaseAssocObject);

use strict;

sub load	{
    my ($self,$data) = @_;
    
    if (defined($data)) {
        $self->{'DBData'} = $data;
    }
    else {
        my $st=qq[
		SELECT * 
		FROM tblDefVenue
		WHERE intDefVenueID = ?
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
}

# Venue can only be deleted, intRecStatus set to -1,  if it isn't attached to any matches, or no teams have this as a venue.
sub canDelete {
    my $self = shift;
    
    
    my $venueID = $self->ID();
    return 0 if !$venueID;
    
    my $dbh = $self->{db};
    
    my $assocID = $self->{assocID};
    my $assocObj = new AssocObj(ID=>$assocID, assocID=>$assocID, db=>$dbh);
    $assocObj->load();
    if (!$assocObj->getValue('intSWOL')) {
        return 0;
    }

    my $query1 = qq[SELECT COUNT(*) 
                    FROM tblCompMatches
                    WHERE intVenueID = $venueID
                    AND tblCompMatches.intRecStatus != $Defs::RECSTATUS_DELETED
                    AND intAssocID = $assocID];
    
    my ($count1) = $dbh->selectrow_array($query1);
    
    my $query2 = qq[SELECT COUNT(*) 
                    FROM tblTeam
                    WHERE (intVenue1ID = $venueID OR intVenue2ID = $venueID OR intVenue3ID = $venueID)
                    AND tblTeam.intRecStatus != $Defs::RECSTATUS_DELETED
                    AND intAssocID=$assocID];
    
    my ($count2) = $dbh->selectrow_array($query2);
    
    if($count1 == 0 && $count2 == 0){
        return 1;
    }
    else {
        return 0;
    }
}

sub delete {
    my $self = shift;
    
    if ($self->canDelete()) {
        my $venueID = $self->ID();
        my $dbh = $self->{db};

        my @errors = ();
        my $statement1 = qq[UPDATE tblDefVenue SET intRecStatus = $Defs::RECSTATUS_DELETED
                           WHERE intDefVenueID = $venueID LIMIT 1];
        $dbh->do($statement1);
     
        if ($dbh->err()) {
            push @errors, $dbh->errstr();
        }
        


 
        if (scalar @errors) {
            return "ERROR:";
        }
        else {
            return 1;
        }
    }
    else {
        return 0;
    }
}

sub create  {
	my $self = shift;
  my($venueData)=@_;
  for my $k (keys %{$venueData})  {
    $self->{'DBData'}{$k}=$venueData->{$k};
  }
    $self->{'ID'}=$self->{'DBData'}{'intDefVenueID'};
    #$self->writeVenue() if !$self->{'DBData'}{'intDefVenueID'};
}

1;
