#
# $Header: svn://svn/SWM/trunk/web/comp/RealmObj.pm 10144 2013-12-03 21:36:47Z tcourt $
#

package RealmObj;

use strict;
use BaseObject;
our @ISA =qw(BaseObject);

use lib '.', '..', '../..';
use Defs;

sub load {
  my $self = shift;

	my $st=qq[
		SELECT * 
		FROM tblRealms
		WHERE intRealmID = ?
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

# Static method, returns a list of realms as hash.
sub getAssocs {
    my $class = shift;
    my ($dbh,$realmID, $params) = @_;
    
    return undef if !$dbh;
    return undef if !$realmID;
    
    my $clubJOIN = '';
    if ($params->{clubs}) {
        $clubJOIN = qq[INNER JOIN tblAssoc_Clubs ON (tblAssoc_Clubs.intAssocID = tblAssoc.intAssocID)];
    }
    
    my $query = qq[SELECT tblAssoc.intAssocID, tblAssoc.strName
                   FROM tblAssoc 
                   $clubJOIN
                   WHERE intRealmID = $realmID
                   AND tblAssoc.intRecStatus != $Defs::RECSTATUS_DELETED
               ];
    
    my $sth = $dbh->prepare($query);
    $sth->execute();
    
    my %Assocs = ();
    while (my $dref = $sth->fetchrow_hashref()) {
        $Assocs{$dref->{intAssocID}} = $dref->{strName};
    }
    
    return \%Assocs;
    
}

1;
