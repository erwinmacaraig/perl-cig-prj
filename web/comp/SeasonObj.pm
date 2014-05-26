#
# $Header: svn://svn/SWM/trunk/web/comp/SeasonObj.pm 10144 2013-12-03 21:36:47Z tcourt $
#

package SeasonObj;
use BaseObject;
our @ISA =qw(BaseObject);

use strict;

use lib '.', '..', '../..';
use Defs;

sub load	{
    my ($self,$data) = @_;
    
    if (defined($data)) {
        $self->{'DBData'} = $data;
    }
    else {
        my $st=qq[
		SELECT * 
		FROM tblSeasons
		WHERE intSeasonID = ?
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

sub getIDsNamesHash {
    my $class = shift;
    my ($Data) = shift; 
    
    
    my $dbh = $Data->{db};
    my $assocID=$Data->{'clientValues'}{'assocID'} || $Defs::INVALID_ID;
    my $subType = $Data->{'RealmSubType'} || 0;

    my $query = qq[ 
                   SELECT intSeasonID, strSeasonName, intSeasonOrder
                   FROM tblSeasons 
                   WHERE intRealmID = $Data->{'Realm'}
                   AND (intAssocID = $assocID OR intAssocID = 0)
                   AND (intRealmSubTypeID = $subType OR intRealmSubTypeID= 0)
                   AND intArchiveSeason <> 1
               ]; 
        
    my $sth = $dbh->prepare($query);
    
    my %Seasons = ();
    my @Order = ();
    
    $sth->execute();
    while (my $dref = $sth->fetchrow_hashref()) {
        $Seasons{$dref->{intSeasonID}} = $dref->{'strSeasonName'};
        push @Order, $dref->{intSeasonOrder};
    }
    
    return \%Seasons, \@Order;
}

1;
