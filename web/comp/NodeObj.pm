#
# $Header: svn://svn/SWM/trunk/web/comp/NodeObj.pm 8251 2013-04-08 09:00:53Z rlee $
#

package NodeObj;

use strict;
use BaseObject;
our @ISA =qw(BaseObject);

sub load {
  my $self = shift;

	my $st=qq[
		SELECT * 
		FROM tblNode
		WHERE intNodeID = ?
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

1;
