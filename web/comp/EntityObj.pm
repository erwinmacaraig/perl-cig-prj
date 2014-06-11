package EntityObj;

use strict;
use BaseObject;
our @ISA =qw(BaseObject);

sub load {
  my $self = shift;

	my $st=qq[
		SELECT * 
		FROM tblEntity
		WHERE intEntityID = ?
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

sub name {
  my $self = shift;
    my($db) = @_;
    return $self->{'DBData'}{'strLocalName'} 
        ||$self->{'DBData'}{'strLatinName'} 
        || '';
}

1;
